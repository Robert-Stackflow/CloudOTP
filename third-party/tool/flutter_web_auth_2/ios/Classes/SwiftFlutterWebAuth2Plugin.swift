import AuthenticationServices
import Flutter
import SafariServices
import UIKit

public class SwiftFlutterWebAuth2Plugin: NSObject, FlutterPlugin {
    private struct PendingAuthentication {
        let id: UUID
        let callback: OAuthCallback
        let session: ASWebAuthenticationSession
        let context: AuthenticationPresentationContext
        let result: FlutterResult
        let timeout: DispatchWorkItem
        let deadline: Date
    }
    private var pending: PendingAuthentication?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterWebAuth2Plugin()
        let channel = FlutterMethodChannel(name: "flutter_web_auth_2", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) { registrar.addSceneDelegate(instance) }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "authenticate": authenticate(call.arguments, result: result)
        case "cleanUpDanglingCalls":
            // A foreground event alone does not cancel a live system session.
            result(nil)
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func authenticate(_ arguments: Any?, result: @escaping FlutterResult) {
        guard pending == nil else {
            result(failure("IN_PROGRESS", "An authentication session is already running.")); return
        }
        guard let args = arguments as? [String: Any],
              let urlString = args["url"] as? String, let url = URL(string: urlString),
              url.scheme?.lowercased() == "https",
              let callbackString = args["callbackUrl"] as? String,
              let callbackURL = URL(string: callbackString),
              let callback = OAuthCallback(url: callbackURL, authorizationURL: url)
        else {
            result(failure("INVALID_ARGUMENTS", "Invalid authentication or callback URL.")); return
        }
        guard #available(iOS 12.0, *) else {
            result(failure("UNSUPPORTED_IOS", "Authentication requires iOS 12 or later.")); return
        }
        guard let anchor = presentationWindow() else {
            result(failure("NO_PRESENTATION_WINDOW", "No active window is available for authentication.")); return
        }
        let options = args["options"] as? [String: Any] ?? [:]
        let id = UUID()
        let completion: (URL?, Error?) -> Void = { [weak self] url, error in
            DispatchQueue.main.async { self?.complete(id: id, url: url, error: error) }
        }
        let session: ASWebAuthenticationSession
        if callback.scheme == "https" {
            guard #available(iOS 17.4, *), let host = callback.url.host else {
                result(failure("HTTPS_CALLBACK_UNSUPPORTED", "HTTPS callbacks require iOS 17.4 or later.")); return
            }
            // The app must also have the corresponding Associated Domains entitlement.
            session = ASWebAuthenticationSession(url: url, callback: .https(host: host, path: callback.url.path), completionHandler: completion)
        } else if #available(iOS 17.4, *) {
            session = ASWebAuthenticationSession(url: url, callback: .customScheme(callback.scheme), completionHandler: completion)
        } else {
            session = ASWebAuthenticationSession(url: url, callbackURLScheme: callback.scheme, completionHandler: completion)
        }
        let context = AuthenticationPresentationContext(window: anchor)
        if #available(iOS 13.0, *) {
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = options["preferEphemeral"] as? Bool ?? false
        }
        let timeout = DispatchWorkItem { [weak self] in
            self?.finish(id: id, value: self?.failure("TIMEOUT", "Authentication timed out."))
        }
        let seconds = min(max(options["timeout"] as? Double ?? 300, 1), 300)
        // Install ownership before start(): both failure and completion clear it once.
        pending = PendingAuthentication(id: id, callback: callback, session: session, context: context, result: result, timeout: timeout, deadline: Date().addingTimeInterval(seconds))
        guard session.start() else {
            finish(id: id, value: failure("START_FAILED", "Unable to start authentication.")); return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: timeout)
        NSLog("CloudOTP OAuth: session started")
    }

    private func complete(id: UUID, url: URL?, error: Error?) {
        guard let current = pending, current.id == id else { return }
        guard Date() < current.deadline else {
            finish(id: id, value: failure("TIMEOUT", "Authentication timed out.")); return
        }
        if let error = error {
            let canceled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
            finish(id: id, value: failure(canceled ? "CANCELED" : "AUTHENTICATION_FAILED", canceled ? "Authentication was canceled." : "Authentication failed."))
            return
        }
        guard let url = url, current.callback.matchesEndpoint(url), current.callback.hasValidState(url) else {
            finish(id: id, value: failure("INVALID_CALLBACK", "The authentication callback did not match the pending request.")); return
        }
        finish(id: id, value: url.absoluteString)
    }

    private func finish(id: UUID, value: Any?) {
        guard let current = pending, current.id == id else { return }
        pending = nil
        current.timeout.cancel()
        current.session.cancel()
        current.result(value)
        // Never log callback URLs, codes, tokens, or server error descriptions.
        NSLog("CloudOTP OAuth: session finished (%@)", (value as? FlutterError)?.code ?? "callback_received")
    }

    private func consume(_ url: URL) -> Bool {
        guard let current = pending, current.callback.matchesEndpoint(url) else { return false }
        // An unsolicited or stale URL cannot authenticate a different transaction.
        guard current.callback.hasValidState(url) else { return true }
        complete(id: current.id, url: url, error: nil)
        return true
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        consume(url)
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return false }
        return consume(url)
    }

    private func presentationWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
            let windows = scenes.flatMap { $0.windows }
            return windows.first { $0.isKeyWindow } ?? windows.first { !$0.isHidden && $0.windowLevel == .normal }
        }
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    private func failure(_ code: String, _ message: String) -> FlutterError {
        FlutterError(code: code, message: message, details: nil)
    }
}

@available(iOS 13.0, *)
extension SwiftFlutterWebAuth2Plugin: FlutterSceneLifeCycleDelegate {
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        URLContexts.reduce(false) { consume($1.url) || $0 }
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return false }
        return consume(url)
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        guard let options = connectionOptions else { return false }
        // Cold starts have no pending session. Never persist or replay credentials.
        var handled = options.urlContexts.reduce(false) { consume($1.url) || $0 }
        for activity in options.userActivities {
            if let url = activity.webpageURL { handled = consume(url) || handled }
        }
        return handled
    }
}

private final class AuthenticationPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let window: UIWindow
    init(window: UIWindow) { self.window = window }
    @available(iOS 13.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }
}
