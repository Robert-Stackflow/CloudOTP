import Flutter
import UIKit
import LocalAuthentication
import UserNotifications
import AuthenticationServices

final class CloudOTPIOSPlugin: NSObject, FlutterPlugin {
  private var autoFillAvailable: Bool { Bundle.main.object(forInfoDictionaryKey: "CloudOTPAutoFillAvailable") as? String == "YES" }
  private let privacyCover = BackgroundPrivacyCover()
  private var authContext: LAContext?
  private var authInProgress = false
  private var backupTasks: [Int: UIBackgroundTaskIdentifier] = [:]
  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = CloudOTPIOSPlugin()
    registrar.addMethodCallDelegate(instance, channel: FlutterMethodChannel(name: "cloudotp/ios", binaryMessenger: registrar.messenger()))
  }
  private func authenticate(_ reason: String, result: @escaping FlutterResult) {
    guard !authInProgress else { result(false); return }
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      result(FlutterError(code: "biometric_unavailable", message: error?.localizedDescription, details: nil)); return
    }
    authContext = context
    authInProgress = true
    let privacyLease = privacyCover.beginAuthentication()
    context.localizedFallbackTitle = ""
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
      DispatchQueue.main.async {
        self.authInProgress = false
        self.authContext = nil
        self.privacyCover.endAuthentication(privacyLease)
        if let error = error as? LAError, ![.userCancel, .systemCancel, .appCancel, .authenticationFailed].contains(error.code) {
          result(FlutterError(code: "biometric_failed", message: error.localizedDescription, details: nil))
        } else { result(success) }
      }
    }
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let center = UNUserNotificationCenter.current()
    switch call.method {
    case "beginSystemAuthentication":
      result(privacyCover.beginAuthentication().uuidString)
    case "endSystemAuthentication":
      if let value = args["id"] as? String, let id = UUID(uuidString: value) { privacyCover.endAuthentication(id) }
      result(nil)
    case "setPrivacyCover":
      privacyCover.setEnabled(args["enabled"] as? Bool ?? false)
      result(nil)
    case "beginBackup":
      var task = UIBackgroundTaskIdentifier.invalid
      task = UIApplication.shared.beginBackgroundTask(withName: "CloudOTP encrypted backup") { [weak self] in
        if task != .invalid {
          UIApplication.shared.endBackgroundTask(task)
          self?.backupTasks.removeValue(forKey: task.rawValue)
        }
      }
      if task != .invalid { backupTasks[task.rawValue] = task }
      result(task == .invalid ? nil : task.rawValue)
    case "endBackup":
      if let id = args["id"] as? Int, let task = backupTasks.removeValue(forKey: id) {
        UIApplication.shared.endBackgroundTask(task)
      }
      result(nil)
    case "authenticate":
      authenticate(args["reason"] as? String ?? "Unlock CloudOTP", result: result)
    case "copy":
      let text = args["text"] as? String ?? ""
      var options: [UIPasteboard.OptionsKey: Any] = [:]
      if let seconds = args["expiresIn"] as? Int {
        options[.expirationDate] = Date().addingTimeInterval(TimeInterval(seconds))
        options[.localOnly] = !UserDefaults.standard.bool(forKey: "cloudotp.universalClipboard")
      }
      UIPasteboard.general.setItems([["public.utf8-plain-text": text]], options: options)
      result(nil)
    case "status":
      center.getNotificationSettings { settings in
        ASCredentialIdentityStore.shared.getState { state in
          DispatchQueue.main.async {
            result(["autofillAvailable": self.autoFillAvailable,
                    "notifications": settings.authorizationStatus.rawValue,
                    "notificationsEnabled": UserDefaults.standard.bool(forKey: "cloudotp.notifications"),
                    "autofillEnabled": self.autoFillAvailable && UserDefaults.standard.bool(forKey: "cloudotp.autofill"),
                    "autofillSystemEnabled": state.isEnabled,
                    "universalClipboard": UserDefaults.standard.bool(forKey: "cloudotp.universalClipboard")])
          }
        }
      }
    case "universalClipboard":
      UserDefaults.standard.set(args["enabled"] as? Bool ?? false, forKey: "cloudotp.universalClipboard"); result(nil)
    case "requestNotifications":
      center.requestAuthorization(options: [.alert, .sound]) { allowed, error in
        DispatchQueue.main.async {
          UserDefaults.standard.set(allowed, forKey: "cloudotp.notifications")
          result(allowed)
        }
      }
    case "disableNotifications":
      UserDefaults.standard.set(false, forKey: "cloudotp.notifications")
      center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications(); result(nil)
    case "notifyBackup":
      guard UserDefaults.standard.bool(forKey: "cloudotp.notifications"),
            UIApplication.shared.applicationState != .active else { result(nil); return }
      let content = UNMutableNotificationContent()
      content.title = "CloudOTP"
      // Deliberately exclude account names, secrets and verification codes.
      content.body = args["body"] as? String ?? "Backup finished"
      content.sound = .default
      center.add(UNNotificationRequest(identifier: "cloudotp.backup", content: content, trigger: nil)) { error in
        DispatchQueue.main.async { result(error.map { FlutterError(code: "notification_failed", message: $0.localizedDescription, details: nil) }) }
      }
    case "openNotificationSettings":
      let value: String
      if #available(iOS 16.0, *) { value = UIApplication.openNotificationSettingsURLString }
      else { value = UIApplication.openSettingsURLString }
      guard let url = URL(string: value) else { result(false); return }
      UIApplication.shared.open(url) { result($0) }
    case "openSettings":
      guard let url = URL(string: UIApplication.openSettingsURLString) else { result(false); return }
      UIApplication.shared.open(url) { result($0) }
    case "openAutoFillSettings":
      if #available(iOS 18.0, *) {
        ASSettingsHelper.openCredentialProviderAppSettings { error in
          DispatchQueue.main.async { result(error == nil) }
        }
      } else { result(false) }
    case "syncAutoFill":
      guard UserDefaults.standard.bool(forKey: "cloudotp.autofill") else { result(nil); return }
      do {
        let records = args["tokens"] as? [[String: Any]] ?? []
        let data = try JSONSerialization.data(withJSONObject: records)
        let tokens = try JSONDecoder().decode([AutoFillToken].self, from: data)
        try AutoFillVault.save(data)
        if #available(iOS 18.0, *) {
          let identities: [ASOneTimeCodeCredentialIdentity] = tokens.compactMap { token in
            guard let domain = token.domain, !domain.isEmpty else { return nil }
            return ASOneTimeCodeCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: domain, type: .domain), label: token.label, recordIdentifier: token.uid)
          }
          ASCredentialIdentityStore.shared.getState { state in
            guard state.isEnabled else { DispatchQueue.main.async { result(nil) }; return }
            ASCredentialIdentityStore.shared.replaceCredentialIdentities(identities) { success, error in
              DispatchQueue.main.async {
                result(error.map { FlutterError(code: "autofill_index_failed", message: $0.localizedDescription, details: nil) })
              }
            }
          }
        } else { result(nil) }
      } catch { result(FlutterError(code: "autofill_sync_failed", message: error.localizedDescription, details: nil)) }
    case "enableAutoFill":
      guard autoFillAvailable else {
        result(FlutterError(code: "autofill_unavailable", message: "This build does not include the AutoFill extension. An eligible Apple Developer Program team is required.", details: nil)); return
      }
      authenticate(args["reason"] as? String ?? "Enable verification code AutoFill") { value in
        guard let success = value as? Bool, success else { result(value); return }
        do {
          // Validate shared keychain entitlement before claiming success.
          try AutoFillVault.save(Data("[]".utf8))
          UserDefaults.standard.set(true, forKey: "cloudotp.autofill")
          result(true)
        } catch { result(FlutterError(code: "autofill_unavailable", message: error.localizedDescription, details: nil)) }
      }
    case "disableAutoFill":
      do {
        try AutoFillVault.clear()
        UserDefaults.standard.set(false, forKey: "cloudotp.autofill")
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { _, _ in }
        result(nil)
      } catch { result(FlutterError(code: "autofill_clear_failed", message: error.localizedDescription, details: nil)) }
    default: result(FlutterMethodNotImplemented)
    }
  }
}

/// Protect the app-switcher transition without obscuring our own Face ID UI.
private final class BackgroundPrivacyCover {
  private var policy = PrivacyCoverPolicy()
  private var observers: [NSObjectProtocol] = []
  private var covers: [UIWindow: UIView] = [:]

  init() {
    let center = NotificationCenter.default
    for name in [UIScene.willDeactivateNotification, UIApplication.willResignActiveNotification] {
      observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
        self?.policy.deactivate()
        self?.update(in: notification.object as? UIWindowScene)
      })
    }
    for name in [UIScene.didEnterBackgroundNotification, UIApplication.didEnterBackgroundNotification] {
      observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
        self?.policy.enterBackground()
        self?.update(in: notification.object as? UIWindowScene)
      })
    }
    for name in [UIScene.didActivateNotification, UIApplication.didBecomeActiveNotification] {
      observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.policy.activate()
        self?.update(in: nil)
      })
    }
  }
  deinit { observers.forEach(NotificationCenter.default.removeObserver) }
  func setEnabled(_ value: Bool) {
    policy.enabled = value
    if UIApplication.shared.applicationState == .background { policy.enterBackground() }
    update(in: nil)
  }
  func beginAuthentication() -> UUID { policy.beginAuthentication() }
  func endAuthentication(_ id: UUID) { policy.endAuthentication(id) }
  private func update(in scene: UIWindowScene?) {
    guard policy.shouldCover else {
      covers.values.forEach { $0.removeFromSuperview() }
      covers.removeAll()
      return
    }
    let windows = scene?.windows ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
    UIView.performWithoutAnimation {
      for window in windows where !window.isHidden && window.windowLevel == .normal && covers[window] == nil {
        // An opaque surface protects short numeric codes as well as account names.
        let cover = UIView(frame: window.bounds)
        cover.backgroundColor = .systemBackground
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cover.isUserInteractionEnabled = false
        cover.accessibilityElementsHidden = true
        window.addSubview(cover)
        window.layoutIfNeeded()
        covers[window] = cover
      }
    }
  }
}
