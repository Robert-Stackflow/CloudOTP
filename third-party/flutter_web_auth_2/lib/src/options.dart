/// Default intent flags for opening the custom tabs intent on Android.
/// This is essentially the same as
/// `FLAG_ACTIVITY_SINGLE_TOP | FLAG_ACTIVITY_NEW_TASK`.
const defaultIntentFlags = 1 << 29 | 1 << 28;

/// "Ephemeral" intent flags for opening the custom tabs intent on Android.
/// This is essentially the same as
/// `FLAG_ACTIVITY_SINGLE_TOP | FLAG_ACTIVITY_NEW_TASK
/// | FLAG_ACTIVITY_NO_HISTORY`.
const ephemeralIntentFlags = defaultIntentFlags | 1 << 30;

/// Default HTML code that generates a nice callback page.
const _defaultLandingPage = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>OAuth Success</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; }

    main {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol;
    }

    #text {
      padding: 2em;
      text-align: center;
      font-size: 2rem;
    }
  </style>
</head>
<body>
  <main>
    <div id="text">Congratulations, your connection was successful!</div>
  </main>
</body>
</html>
''';

/// Provides configuration options for calls to `authenticate`.
class FlutterWebAuth2Options {
  /// Construct an instance and specify the wanted options.
  const FlutterWebAuth2Options({
    bool? preferEphemeral,
    this.debugOrigin,
    int? intentFlags,
    this.windowName,
    int? timeout,
    String? landingPageHtml,
    bool? silentAuth,
    bool? useWebview,
    this.httpsHost,
    this.httpsPath,
    this.customTabsPackageOrder,
  })  : preferEphemeral = preferEphemeral ?? false,
        intentFlags = intentFlags ?? defaultIntentFlags,
        timeout = timeout ?? 5 * 60,
        landingPageHtml = landingPageHtml ?? _defaultLandingPage,
        silentAuth = silentAuth ?? false,
        useWebview = useWebview ?? true;

  /// Construct an instance from JSON format.
  FlutterWebAuth2Options.fromJson(Map<String, dynamic> json)
      : this(
          preferEphemeral: json['preferEphemeral'],
          debugOrigin: json['debugOrigin'],
          intentFlags: json['intentFlags'],
          windowName: json['windowName'],
          timeout: json['timeout'],
          landingPageHtml: json['landingPageHtml'],
          silentAuth: json['silentAuth'],
          useWebview: json['useWebview'],
          httpsHost: json['httpsHost'],
          httpsPath: json['httpsPath'],
          customTabsPackageOrder: json['customTabsPackageOrder'],
        );

  /// **Only has an effect on iOS and MacOS!**
  /// If this is `true`, an ephemeral web browser session
  /// will be used where possible (`prefersEphemeralWebBrowserSession`).
  /// For Android devices, see [intentFlags].
  final bool preferEphemeral;

  /// **Only has an effect on Web!**
  /// Can be used to override the origin of the redirect URL.
  /// This is useful for cases where the redirect URL is not on the same
  /// domain (e.g. local testing).
  final String? debugOrigin;

  /// **Only has an effect on Android!**
  /// Can be used to configure the intent flags for the custom tabs intent.
  /// Possible values can be found
  /// [here](https://developer.android.com/reference/android/content/Intent#setFlags(int))
  /// or by using the flags from the `Flag` class from
  /// [android_intent_plus](https://pub.dev/packages/android_intent_plus).
  /// Use [ephemeralIntentFlags] if you want similar behaviour to
  /// [preferEphemeral] on Android.
  /// For Apple devices, see [preferEphemeral].
  final int intentFlags;

  /// **Only has an effect on Web!**
  /// Can be used to pass a window name for the URL open call.
  /// See [here](https://www.w3schools.com/jsref/met_win_open.asp) for
  /// possible parameter values.
  final String? windowName;

  /// **Only has an effect on Linux, Web and Windows!**
  /// Can be used to specify a timeout in seconds when the authentication shall
  /// be deemed unsuccessful. An error will be thrown in order to abort the
  /// authentication process.
  final int timeout;

  /// **Only has an effect on Linux and Windows!**
  /// Can be used to customise the landing page which tells the user that the
  /// authentication was successful. It is the literal HTML source code which
  /// will be displayed using a `HttpServer`.
  final String landingPageHtml;

  /// **Only has an effect on Web!**
  /// When set to `true`, the authentication URL will be loaded in a hidden
  /// `iframe` instead of opening a new window or tab. This is primarily used
  /// for silent authentication processes where a full-page redirect is not
  /// desirable. It allows for a seamless user experience by performing the
  /// authentication in the background. This approach is useful for token
  /// refreshes or for maintaining user sessions without explicit user
  /// interaction. IT IS YOUR RESPONSIBILITY TO MAKE SURE THAT THE URL IS SANE
  /// AND DOES NOT CAUSE ANY HARM. IFRAMES CAN BE EXPLOITED IN MANY WAYS BY
  /// MALICIOUS ATTACKERS!
  final bool silentAuth;

  /// **Only has an effect on Linux and Windows!**
  /// When set to `true`, use the new Webview implementation.
  /// When set to `false`, the old approach using an internal server is being
  /// used in order to fetch the HTTP result. When using the internal server,
  /// please keep in mind that you cannot choose any callback URL scheme, as
  /// described in https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/25
  final bool useWebview;

  /// **Only has an effect on iOS and MacOS!**
  /// String specifying the **host** of the URL that the page will redirect to
  /// upon successful authentication (callback URL).
  /// When `callbackUrlScheme` is `https`, this **must** be specified on
  /// Apple devices running iOS >= 17.4 or macOS >= 14.4.
  final String? httpsHost;

  /// **Only has an effect on iOS and MacOS!**
  /// String specifying the **path** of the URL that the page will redirect to
  /// upon successful authentication (callback URL).
  /// When `callbackUrlScheme` is `https`, this **must** be specified on
  /// Apple devices running iOS >= 17.4 or macOS >= 14.4.
  final String? httpsPath;

  /// **Only has an effect on Android!**
  /// Sets the Android browser priority for opening custom tabs.
  /// Needs to be a list of packages providing a custom tabs
  /// service. If a browser is not installed, the next on the list
  /// is tested etc.
  final List<String>? customTabsPackageOrder;

  /// Convert this instance to JSON format.
  Map<String, dynamic> toJson() => {
        'preferEphemeral': preferEphemeral,
        'debugOrigin': debugOrigin,
        'intentFlags': intentFlags,
        'windowName': windowName,
        'timeout': timeout,
        'landingPageHtml': landingPageHtml,
        'silentAuth': silentAuth,
        'useWebview': useWebview,
        'customTabsPackageOrder': customTabsPackageOrder,
        'httpsHost': httpsHost,
        'httpsPath': httpsPath,
      };
}
