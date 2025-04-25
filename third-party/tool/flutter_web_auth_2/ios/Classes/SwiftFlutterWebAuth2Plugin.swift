import AuthenticationServices
import Flutter
import SafariServices
import UIKit

public class SwiftFlutterWebAuth2Plugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_web_auth_2", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterWebAuth2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    var completionHandler: ((URL?, Error?) -> Void)?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "authenticate",
           let arguments = call.arguments as? [String: AnyObject],
           let urlString = arguments["url"] as? String,
           let url = URL(string: urlString),
           let callbackURLScheme = arguments["callbackUrlScheme"] as? String,
           let options = arguments["options"] as? [String: AnyObject]
        {
            var sessionToKeepAlive: Any? // if we do not keep the session alive, it will get closed immediately while showing the dialog
            completionHandler = { (url: URL?, err: Error?) in
                self.completionHandler = nil

                if (sessionToKeepAlive != nil) {
                    if #available(iOS 12, *) {
                        (sessionToKeepAlive as! ASWebAuthenticationSession).cancel()
                    } else if #available(iOS 11, *) {
                        (sessionToKeepAlive as! SFAuthenticationSession).cancel()
                    }
                    sessionToKeepAlive = nil
                }

                if let err = err {
                    if #available(iOS 12, *) {
                        if case ASWebAuthenticationSessionError.canceledLogin = err {
                            result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                            return
                        }
                    }

                    if #available(iOS 11, *) {
                        if case SFAuthenticationError.canceledLogin = err {
                            result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                            return
                        }
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

            if #available(iOS 12, *) {
                var _session: ASWebAuthenticationSession? = nil
                if #available(iOS 17.4, *) {
                    if (callbackURLScheme == "https") {
                        guard let host = options["httpsHost"] as? String else {
                            result(FlutterError.invalidHttpsHostError)
                            return 
                        }

                        guard let path = options["httpsPath"] as? String else {
                            result(FlutterError.invalidHttpsPathError)
                            return 
                        }

                        _session = ASWebAuthenticationSession(url: url, callback: ASWebAuthenticationSession.Callback.https(host: host, path: path), completionHandler: completionHandler!)
                    } else {
                        _session = ASWebAuthenticationSession(url: url, callback: ASWebAuthenticationSession.Callback.customScheme(callbackURLScheme), completionHandler: completionHandler!)
                    }
                } else {
                    _session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler!)
                }
                let session = _session!

                if #available(iOS 13, *) {
                    var rootViewController: UIViewController? = nil

                    // FlutterViewController
                    if (rootViewController == nil) {
                        rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
                    }

                    // UIViewController
                    if (rootViewController == nil) {
                        rootViewController = UIApplication.shared.keyWindow?.rootViewController
                    }

                    // ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED
                    if (rootViewController == nil) {
                        result(FlutterError.acquireRootViewControllerFailed)
                        return
                    }

                    while let presentedViewController = rootViewController!.presentedViewController {
                        rootViewController = presentedViewController
                    }
                    if let nav = rootViewController as? UINavigationController {
                        rootViewController = nav.visibleViewController ?? rootViewController
                    }

                    guard let contextProvider = rootViewController as? ASWebAuthenticationPresentationContextProviding else {
                        result(FlutterError.acquireRootViewControllerFailed)
                        return
                    }
                    session.presentationContextProvider = contextProvider
                    if let preferEphemeral = options["preferEphemeral"] as? Bool {
                        session.prefersEphemeralWebBrowserSession = preferEphemeral
                    }
                }

                session.start()
                sessionToKeepAlive = session
            } else if #available(iOS 11, *) {
                let session = SFAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler!)
                session.start()
                sessionToKeepAlive = session
            } else {
                result(FlutterError(code: "FAILED", message: "This plugin does currently not support iOS lower than iOS 11", details: nil))
            }
        } else if call.method == "cleanUpDanglingCalls" {
            // we do not keep track of old callbacks on iOS, so nothing to do here
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void) -> Bool
    {
        switch userActivity.activityType {
            case NSUserActivityTypeBrowsingWeb:
                guard let url = userActivity.webpageURL, let completionHandler = completionHandler else {
                    return false
                }
                completionHandler(url, nil)
                return true
            default: return false
        }
    }
}

@available(iOS 13, *)
extension FlutterViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}

fileprivate extension FlutterError {
    static var acquireRootViewControllerFailed: FlutterError {
        return FlutterError(code: "ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED", message: "Failed to acquire root view controller", details: nil)
    }

    static var invalidHttpsHostError: FlutterError {
        return FlutterError(code: "INVALID_HTTPS_HOST_ERROR", message: "Failed to retrieve host for https scheme", details: nil)
    }

    static var invalidHttpsPathError: FlutterError {
        return FlutterError(code: "INVALID_HTTPS_PATH_ERROR", message: "Failed to retrieve path for https scheme", details: nil)
    }
}
