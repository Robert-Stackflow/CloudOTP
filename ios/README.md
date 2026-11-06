# CloudOTP on iOS

The shared app retains its existing behavior on Android, Windows, Linux and macOS. iOS integrations live in `lib/Platform/ios` and `ios`; shared entry points check `ResponsiveUtil.isIOS()`.

## Build configurations

For local device signing, copy `ios/Flutter/LocalSigning.xcconfig.example` to `ios/Flutter/LocalSigning.xcconfig` and set your team ID. This ignored file is shared by Runner and AutoFill build configurations. The repository does not pin a personal signing team.

- `flutter run -d <iPhone UDID>` uses the normal Runner configuration. It can be signed with a Personal Team and excludes the credential-provider extension.
- `flutter run --flavor autofill -d <iPhone UDID>` builds the app with the OTP AutoFill extension. Both targets require a signing team eligible for the AutoFill Credential Provider capability. Set the same Development Team on Runner and CloudOTPAutoFill in Xcode.
- For compilation validation without a provisioning profile: `flutter build ios --flavor autofill --debug --no-codesign`.

The main app supports iOS 15+. The OTP extension requires iOS 18+. Home-screen controls, including the scanner button and category tabs, use their repository-baseline styling. No custom iOS glass button is used. Narrow iOS fixes prevent native overscroll from duplicating the pull-search hint translation and consume the device bottom safe area once, without adding Scaffold-injected bottom-bar padding again. In portrait, the original scanner and category tabs share one hide animation, with an 8pt scanner top inset and aligned control centers.

## AutoFill

Open the home More menu → Laboratory. The page uses the same setting groups, entries, checkboxes, confirmation dialogs and input sheets as the rest of the app. AutoFill is off by default. Enabling requires biometric authentication and explicit consent to create an independent, device-only Keychain snapshot of standard TOTP records. The extension authenticates with Face ID, Touch ID or the device passcode before returning a code. Main-app gesture/database passwords are not enforced by the extension; this difference is disclosed before opt-in. Disabling deletes the snapshot and credential identities.

Only TOTP with SHA-1, SHA-256 or SHA-512 is supported. HOTP, MOTP, Steam and Yandex tokens are excluded. The extension generates a fresh code at selection time, not when the token list is displayed. Token writes and main-app unlock/start sync the snapshot through the existing mutation notification entry point. Manual sync is also available. Website matching is explicitly configured per token, without guessing domains from issuer names. Only labels and configured domains go to the system credential-identity index.

A Personal Team build displays AutoFill as unavailable. It does not silently claim to provide the extension. Apple rejects signing this capability with the current Personal Team; an eligible Developer Program team is needed for end-to-end AutoFill testing.

## Notifications

Backup result notifications are optional local notifications. They are requested only when the user enables the setting, contain no account names or codes, and are posted only when the app is not active. A finite iOS background task covers an already-running backup. This does not provide periodic background backups or remote push notifications.

## Security and interaction changes

- iOS page routes support interactive horizontal back navigation, starting at the leading screen edge. Page-content drags are reserved for gesture passwords, token actions, sliders and horizontal lists. Lock screens still disallow navigation past authentication.
- Returning from a suspended app checks elapsed wall-clock time before cancelling the auto-lock timer.
- Sensitive copied codes expire through UIPasteboard, independently of Dart timers. Universal Clipboard is opt-in. Non-sensitive copy behavior and other platforms remain unchanged.
- Face ID uses a fresh LAContext with a nonempty, localized authentication reason. Keychain prompts are localized on iOS; the existing macOS behavior is preserved.
- The iOS home route does not invoke the legacy suspend selector when handling a back action.

## Verification

```sh
flutter test
tools/ios_tools/test_otp.sh
flutter build ios --debug
flutter build ios --flavor autofill --debug --no-codesign
```

Native OTP tests cover RFC 6238 SHA-1/256/512 vectors, padding and invalid parameters. Dart tests cover website-domain validation and verify that iOS service entry points make no native calls on other platforms.

Device checks: swipe back and cancel a partial swipe; interact with horizontally scrolling content; verify lock screens cannot be swiped away; test Face ID success/cancel/denial and encrypted-database unlock; copy a code, switch apps and verify expiry; return after the lock timeout; enable/deny notifications and finish a backup in the background. On an eligible team, enable CloudOTP in system AutoFill settings and fill a TOTP in Safari and another app, then test token deletion and disabling AutoFill.

The iOS launch logo uses explicit 180pt aspect-fit constraints. Preserve these when regenerating the native launch storyboard.

For a one-time iOS debug fixture, launch with `--dart-define=CLOUDOTP_SEED_DEMO=true`. This adds 20 clearly labelled demonstration TOTP records in three new categories, without changing existing records or automatic backup settings. The fixture is opt-in, debug-only and idempotent.

## Unlock rendering

iOS screen protection changes are serialized and applied only when the setting changes, so ordinary rebuilds do not repeatedly reattach the secure screenshot surface. A native opaque app-switcher cover is installed as the scene deactivates and removed immediately when it becomes active. A tested privacy policy distinguishes our own Face ID/Keychain prompts from ordinary deactivation, including duplicate scene/application events and authentication completion before reactivation. Native Face ID and balanced Keychain leases suppress only the authentication-related inactive transition; real backgrounding is always covered. Leases expire after two minutes. Other system interruptions may also cover the app until it becomes active. Screenshot prevention remains independently enabled. Laboratory renders its complete settings layout immediately and refreshes cached system status silently. Authentication root transitions paint an opaque background immediately instead of fading from transparency. Real-device checks confirmed automatic Face ID on background return, covered app-switcher previews, and no privacy cover during Face ID. The Flutter tests check call deduplication, ordered setting changes, retry after failure, opaque routes and synchronized control positions.

## OAuth callbacks on iOS

The existing `cloudotp://auth/<provider>/callback` redirects use the system `ASWebAuthenticationSession`. The iOS plugin registers both application and scene delegates and anchors the session to a foreground scene window. One pending transaction owns the session, presentation context, callback and five-minute timeout. Start failure, cancellation and completion release them exactly once. Redirect scheme/host/port/path and a unique state must match; the Dart boundary also rejects duplicate state/code, denial, empty code and fragments. Each iOS attempt generates fresh state. Logs contain only session status/error codes.

`IOSOAuthSession` coordinates the temporary auto-lock hold with browser backgrounding. Callback delivery before foreground activation and the reverse order are both supported. The hold covers only the pending transaction/return, expires using wall-clock time and does not carry over to a later ordinary app switch. The legacy iOS prevention flag also uses a wall-clock deadline because Dart timers may be suspended. Normal background return automatically starts Face ID when biometric unlocking is enabled, as selected during device verification. Other platform authorization and locking paths are unchanged.

Bridge availability checks on iOS use bounded HEAD requests without following redirects: a normal 302 from an OAuth entry point means the bridge is available. They do not attempt to probe Google’s login page. iOS code exchange, token refresh and account metadata requests have a 30-second network limit and close their connection on timeout; timeouts remain transient network errors so existing credentials are retained. These network changes are gated to iOS.

Flutter's default URL-to-route mapping is disabled on iOS. Unsolicited, stale or cold-start callbacks cannot create a route or restore a previous OAuth transaction. If iOS terminates CloudOTP during login, unlock the app and start a new connection. Universal Links are not enabled: the HTTPS callback parameters are normalized, but actually using HTTPS requires an eligible Associated Domains entitlement and a matching server association file. Current cloud callbacks remain custom-scheme URLs.

Run `tools/ios_tools/test_oauth.sh` for native redirect checks and `flutter test test/ios/oauth_session_test.dart test/ios/oauth_http_test.dart` for transaction ordering, timeout, redirect and platform-isolation coverage. On a real device, enable immediate background locking, connect a provider, verify callback/token/account success, cancel another login, and confirm a subsequent normal app switch locks again.

Native privacy policy checks: `tools/ios_tools/test_privacy.sh`. Verify both direct app-switcher entry and Home → app-switcher previews, then return and confirm automatic Face ID has no application-added grey cover.

## Deferred Cupertino navigation

The iOS Cupertino dispatcher retains the existing next-frame navigation contract while creating a native CupertinoPageRoute. Import callers can finish dismissing their progress dialog and password sheet before the preview is pushed. A synchronous push here causes the following dismiss to pop the new preview and strand the importing overlay. The dispatcher explicitly requests a frame for asynchronous completions, preserves route-result futures, and skips disposed origin contexts. Other platform dispatch branches are unchanged. `test/ios/import_navigation_test.dart` exercises both real progress/password overlay sequences and a disposed origin.


## Validation recorded for this change

- 99 Flutter tests passed, including iOS navigation/overlay ordering and non-iOS OAuth argument isolation.
- Native checks cover RFC 6238 OTP vectors, exact OAuth redirect/state matching and privacy transitions.
- Google Drive authorization, callback, saved-token reuse and account access passed on a physical iPhone.
- The user confirmed OneDrive backup preview and import work in the signed Release 4.1.0 (411) build.
- AutoFill compilation was checked without signing; actual system AutoFill remains unverified because the current Personal Team cannot provision its entitlement.
