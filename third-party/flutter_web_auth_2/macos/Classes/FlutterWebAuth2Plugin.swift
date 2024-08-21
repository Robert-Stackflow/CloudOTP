import AuthenticationServices
import SafariServices
import FlutterMacOS

@available(OSX 10.15, *)
public class FlutterWebAuth2Plugin: NSObject, FlutterPlugin, ASWebAuthenticationPresentationContextProviding {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_web_auth_2", binaryMessenger: registrar.messenger)
        let instance = FlutterWebAuth2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "authenticate",
           let arguments = call.arguments as? [String: AnyObject],
           let urlString = arguments["url"] as? String,
           let url = URL(string: urlString),
           let callbackURLScheme = arguments["callbackUrlScheme"] as? String,
           let options = arguments["options"] as? [String: AnyObject]
        {
            var sessionToKeepAlive: Any? // if we do not keep the session alive, it will get closed immediately while showing the dialog
            let completionHandler = { (url: URL?, err: Error?) in
                sessionToKeepAlive = nil

                if let err = err {
                    if case ASWebAuthenticationSessionError.canceledLogin = err {
                        result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                        return
                    }

                    result(FlutterError(code: "EUNKNOWN", message: err.localizedDescription, details: nil))
                    return
                }

                guard let url = url else {
                    result(FlutterError(code: "EUNKNOWN", message: "URL was null, but no error provided.", details: nil))
                    return
                }

                result(url.absoluteString)
            }

            var _session: ASWebAuthenticationSession? = nil
            if #available(macOS 14.4, *) {
                if (callbackURLScheme == "https") {
                    guard let host = options["httpsHost"] as? String else {
                        result(FlutterError.invalidHttpsHostError)
                        return
                    }

                    guard let path = options["httpsPath"] as? String else {
                        result(FlutterError.invalidHttpsPathError)
                        return 
                    }

                    _session = ASWebAuthenticationSession(url: url, callback: ASWebAuthenticationSession.Callback.https(host: host, path: path), completionHandler: completionHandler)
                } else {
                    _session = ASWebAuthenticationSession(url: url, callback: ASWebAuthenticationSession.Callback.customScheme(callbackURLScheme), completionHandler: completionHandler)
                }
            } else {
                _session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
            }
            let session = _session!

            if let preferEphemeral = options["preferEphemeral"] as? Bool {
                session.prefersEphemeralWebBrowserSession = preferEphemeral
            }
            session.presentationContextProvider = self

            session.start()
            sessionToKeepAlive = session
        } else if call.method == "cleanUpDanglingCalls" {
            // we do not keep track of old callbacks on macOS, so nothing to do here
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    @available(macOS 10.15, *)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

fileprivate extension FlutterError {
    static var invalidHttpsHostError: FlutterError {
        return FlutterError(code: "INVALID_HTTPS_HOST_ERROR", message: "Failed to retrieve host for https scheme", details: nil)
    }

    static var invalidHttpsPathError: FlutterError {
        return FlutterError(code: "INVALID_HTTPS_PATH_ERROR", message: "Failed to retrieve path for https scheme", details: nil)
    }
}
