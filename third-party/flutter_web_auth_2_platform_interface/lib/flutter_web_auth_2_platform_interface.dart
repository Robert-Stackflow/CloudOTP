import './method_channel/method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of FlutterWebAuth must implement.
///
/// Platform implementations should extend this class rather than implement it
/// because `implements` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation.
abstract class FlutterWebAuth2Platform extends PlatformInterface {
  /// Construct a platform instance.
  FlutterWebAuth2Platform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWebAuth2Platform _instance = FlutterWebAuth2MethodChannel();

  /// Get the currently used platform instance.
  static FlutterWebAuth2Platform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [FlutterWebAuth2Platform] when they register
  /// themselves.
  static set instance(FlutterWebAuth2Platform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Ask the user to authenticate to the specified web service.
  ///
  /// The page pointed to by [url] will be loaded and displayed to the user.
  /// From the page, the user can authenticate herself and grant access to the
  /// app. On completion, the service will send a callback URL with an
  /// authentication token, and this URL will be result of the returned
  /// [Future].
  ///
  /// [callbackUrlScheme] should be a string specifying the scheme of the URL
  /// that the page will redirect to upon successful authentication.
  ///
  /// [options] can be used to specify either both general and
  /// platform-specific settings. It should be JSON-formatted.
  Future<String> authenticate({
    required String url,
    required String callbackUrl,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) =>
      _instance.authenticate(
        url: url,
        callbackUrl: callbackUrl,
        callbackUrlScheme: callbackUrlScheme,
        options: options,
      );

  /// The plugin may need to store the resulting callbacks in order to pass
  /// the result back to the caller of `authenticate`. But if that result never
  /// comes the callback will dangle around forever. This can be called to
  /// terminate all `authenticate` calls with an error.
  Future clearAllDanglingCalls() => _instance.clearAllDanglingCalls();
}
