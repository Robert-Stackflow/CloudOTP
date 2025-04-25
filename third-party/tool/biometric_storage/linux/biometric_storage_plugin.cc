#include "include/biometric_storage/biometric_storage_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <libsecret/secret.h>

#define BIOMETRIC_SCHEMA  biometric_get_schema ()

const char kBadArgumentsError[] = "Bad Arguments";
const char kSecurityAccessError[] = "Security Access Error";
const char kMethodRead[] = "read";
const char kMethodWrite[] = "write";
const char kMethodDelete[] = "delete";
const char kNamePrefix[] = "design.codeux.authpass";

#define METHOD_PARAM_NAME(varName, args) \
    g_autofree gchar * varName = g_strdup_printf("%s.%s", kNamePrefix, fl_value_get_string(fl_value_lookup_string(args, "name")))


#define BIOMETRIC_STORAGE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), biometric_storage_plugin_get_type(), \
                              BiometricStoragePlugin))

#define IS_METHOD(name, equals) \
  strcmp(method, equals) == 0

struct _BiometricStoragePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(BiometricStoragePlugin, biometric_storage_plugin, g_object_get_type())



static FlMethodResponse* _handle_error(const gchar* message, GError *error) {
    const gchar* domain = g_quark_to_string(error->domain);
    g_autofree gchar *error_message = g_strdup_printf("%s: %s (%d) (%s)", message, error->message, error->code, domain);
    g_warning("%s", error_message);
    g_autoptr(FlValue) error_details = fl_value_new_map();
    fl_value_set_string_take(error_details, "domain", fl_value_new_string(domain));
    fl_value_set_string_take(error_details, "code", fl_value_new_int(error->code));
    fl_value_set_string_take(error_details, "message", fl_value_new_string(error->message));
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
                   kSecurityAccessError, error_message, error_details));
}

static FlMethodResponse *handleInit(FlValue *args) {
  FlValue* options = fl_value_lookup_string(args, "options");
  if (fl_value_get_type(options) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Argument map missing or malformed", nullptr));
  }
  FlValue* authRequired = fl_value_lookup_string(options, "authenticationRequired");
  if (fl_value_get_bool(authRequired)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Linux plugin only supports non-authenticated secure storage", nullptr));
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

const SecretSchema *
biometric_get_schema (void)
{
    static const SecretSchema the_schema = {
        "design.codeux.BiometricStorage", SECRET_SCHEMA_NONE,
        {
            {  "name", SECRET_SCHEMA_ATTRIBUTE_STRING },
            // {  "NULL", 0 },
        }
    };
    return &the_schema;
}

static void on_password_stored(GObject *source, GAsyncResult *result,
                               gpointer user_data) {
  GError *error = NULL;
  FlMethodCall *method_call = (FlMethodCall *)user_data;
  g_autoptr(FlMethodResponse) response = nullptr;

  secret_password_store_finish(result, &error);
  if (error != NULL) {
    /* ... handle the failure here */
    response = _handle_error("Failed to store secret", error);
    g_error_free(error);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
  }

  fl_method_call_respond(method_call, response, nullptr);
  g_object_unref(method_call);
}

static void on_password_cleared(GObject *source, GAsyncResult *result,
                                gpointer user_data) {
  GError *error = NULL;
  FlMethodCall *method_call = (FlMethodCall *)user_data;
  g_autoptr(FlMethodResponse) response = nullptr;

  gboolean removed = secret_password_clear_finish(result, &error);

  if (error != NULL) {
    /* ... handle the failure here */
    response = _handle_error("Failed to delete secret", error);
    g_error_free(error);

  } else {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(removed)));
  }
  fl_method_call_respond(method_call, response, nullptr);
  g_object_unref(method_call);
}

static void on_password_lookup(GObject *source, GAsyncResult *result,
                               gpointer user_data) {
  GError *error = NULL;
  FlMethodCall *method_call = (FlMethodCall *)user_data;
  g_autoptr(FlMethodResponse) response = nullptr;

  gchar *password = secret_password_lookup_finish(result, &error);

  if (error != NULL) {
    /* ... handle the failure here */
    response = _handle_error("Failed to lookup secret", error);
    g_error_free(error);
  } else if (password == NULL) {
    /* password will be null, if no matching password found */
    g_warning("Failed to lookup password (not found).");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else {
    /* ... do something with the password */
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(password)));
    secret_password_free(password);
  }
  fl_method_call_respond(method_call, response, nullptr);
  g_object_unref(method_call);
}

// Called when a method call is received from Flutter.
static void
biometric_storage_plugin_handle_method_call(BiometricStoragePlugin *self,
                                            FlMethodCall *method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "canAuthenticate") == 0) {
    g_autoptr(FlValue) result = fl_value_new_string("ErrorHwUnavailable");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "init") == 0) {
    response = handleInit(args);
  } else if (IS_METHOD(method, kMethodWrite)) {
    METHOD_PARAM_NAME(name, args);
    // const gchar *name =
    //     fl_value_get_string(fl_value_lookup_string(args, "name"));
    const gchar *content =
        fl_value_get_string(fl_value_lookup_string(args, "content"));
    g_object_ref(method_call);
    secret_password_store(BIOMETRIC_SCHEMA, SECRET_COLLECTION_DEFAULT, name,
                          content, NULL, on_password_stored, method_call,
                          "name", name, NULL);
    return;
  } else if (IS_METHOD(method, kMethodRead)) {
    METHOD_PARAM_NAME(name, args);
    // const gchar *name =
    //     fl_value_get_string(fl_value_lookup_string(args, "name"));
    g_object_ref(method_call);
    secret_password_lookup(BIOMETRIC_SCHEMA, NULL, on_password_lookup,
                           method_call, "name", name, NULL);
    return;
  } else if (IS_METHOD(method, kMethodDelete)) {
    METHOD_PARAM_NAME(name, args);
    // const gchar *name =
    //     fl_value_get_string(fl_value_lookup_string(args, "name"));
    g_object_ref(method_call);
    secret_password_clear(BIOMETRIC_SCHEMA, NULL, on_password_cleared,
                          method_call, "name", name, NULL);
    return;
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void biometric_storage_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(biometric_storage_plugin_parent_class)->dispose(object);
}

static void biometric_storage_plugin_class_init(BiometricStoragePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = biometric_storage_plugin_dispose;
}

static void biometric_storage_plugin_init(BiometricStoragePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  BiometricStoragePlugin* plugin = BIOMETRIC_STORAGE_PLUGIN(user_data);
  biometric_storage_plugin_handle_method_call(plugin, method_call);
}

void biometric_storage_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  BiometricStoragePlugin* plugin = BIOMETRIC_STORAGE_PLUGIN(
      g_object_new(biometric_storage_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "biometric_storage",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
