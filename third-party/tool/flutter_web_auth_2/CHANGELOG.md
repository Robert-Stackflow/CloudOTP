## 4.0.0-alpha.8

- 🌹 Allow also `web` versions `0.5.x` again (Thanks to [@Rexios80](https://github.com/Rexios80) in [#118](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/180))
- 🌹 Improve documentation

## 4.0.0-alpha.7

- 🎉 Enable `ASWebAuthenticationSession.Callback.https` support to fix Universal Links on iOS (Thanks to [@GabrielDamasceno](https://github.com/GabrielDamasceno) in [#117](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/117), related to [#65](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/65) and [#104](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/104))
- 🌹 Update `web` to `1.x`

## 4.0.0-alpha.6

- 🌹 Allow custom browser priority and rework Android code (Thanks to [@kecson](https://github.com/kecson) in [#111](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/111))
- 🌹 Enable partial `ASWebAuthenticationSession.Callback` support (related to [#104](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/104))

## 4.0.0-alpha.5

- 💥 Remove Android embedding v1 support (in accordance with Flutter `3.22.0`)
- 💥 Increase Android min SDK to `21` (in accordance with Flutter `3.22.0`)
- 💥 Increase Android JVM version to `11` (in accordance with Flutter `3.22.0`)
- 🌹 Update AndroidX browser to `1.8.0`
- 🌹 Migrate Android and Web examples to newest standards

## 4.0.0-alpha.4

- 🐛 Fix recursion errors in Flutter `3.22.0`
- 🌹 Update dependencies (`melos` and `flutter_lints`)

## 4.0.0-alpha.3

- 🐛 Fix `iframe` approach
- 🌹 Update `melos` to `5.1.0` to have cleaner CI commands

## 4.0.0-alpha.2

- 🌹 Migrate to `web` package

## 4.0.0-alpha.1

- 🌹 Fix lint for Flutter 3.19.x

## 4.0.0-alpha.0

- 🎉 Add Webview approach for Windows and Linux (Thanks to [@Mino5531](https://github.com/Mino5531) in [#92](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/92))

## 3.1.1

- 🐛 Fix null-safe options (again)

## 3.1.0

- 🎉 Implement `iframe` authentication approach (Thanks to [@rundfunk47](https://github.com/rundfunk47) in [#88](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/88))
- 🌹 Fix lint for Flutter 3.16.x

## 3.0.4

- 🐛 Fix null-safe options

## 3.0.3

- 🌹 Fix Web implementation not being found properly (See [#82](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/82))

## 3.0.2

- 🌹 Fix deprecations in Gradle 8.x

## 3.0.1

- 🌹 Better null-safe options

## 3.0.0

- 💥 Release next major version, yay!
- 🐛 Fix Apple implementations

## 3.0.0-alpha.6

- 🐛 Trying a few attempts to fix iOS implementations

## 3.0.0-alpha.5

- 🌹 Fix iOS "screenshot"
- 🐛 Trying a few attempts to fix iOS and MacOS implementations

## 3.0.0-alpha.4

- 🐛 Trying a few attempts to fix iOS and MacOS implementations

## 3.0.0-alpha.3

- 🌹 Add more entries to the pubspec
- 🌹 Add reference to `android_intent_plus`

## 3.0.0-alpha.2

- 🎉 Customizable landing page on Windows and Linux
- 🌹 Update some files from official Flutter template

## 3.0.0-alpha.1

- 🐛 Update platform interface version

## 3.0.0-alpha.0

- 💥 Bump Dart SDK constraints to `>=2.15.0`
- 💥 Huge refactor with more configuration possibilities
- 🎉 Add `melos` to project
- 🌹 Cleanup Android implementation

## 2.2.1

- 🌹 Timeouts (5 minutes) on Web throw real errors now

## 2.2.0

- 🎉 Add fallback for `window.opener` being `null` on Web (See [#58](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/58)) **(See enhanced/better setup instructions for Web in the README!)**
- 🌹 Add delay to example
- 🌹 Bring back support for older AGP versions
- 🐛 Fix `compileOptions` on Android (See [#59](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/59))

## 2.1.5

- 🌹 Fix example support for Dart `3.x`
- 🐛 Implement protocol handler to supply `ASPresentationAnchor` (See [#51](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/51))

## 2.1.4

- 🌹 Fix support for Dart `3.x`
- 🌹 Support AGP `8.x` namespace declaration
- 🌹 Fix web example to work "properly"
- 🐛 Update `flutter_web_auth_2_platform_interface` to require `2.1.4` at least

## 2.1.3

- 🌹 Add `contextArgs` for web implementations (See [#40](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/40))

## 2.1.2

- 🐛 Downgrade Kotlin to fix some compatibility issues

## 2.1.1

- 🌹 Fix formatting

## 2.1.0

- 🎉 Add support for Linux ([#31](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/31))
- 🌹 Get rid of dependency on `win32` and `ffi` by using `window_to_front` instead
- 🌹 Update linter rules
- 🌹 Update Android dependencies

## 2.0.4

- 🐛 Partially fix ([#135](https://github.com/LinusU/flutter_web_auth/issues/135))
- 🌹 Support `win32` versions `2.7.0` until `4.x`
- 🌹 Fix typos in README

## 2.0.3

- 🌹 Add Universal link support ([#26](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/26))
- 🌹 Some small documentation changes

## 2.0.2

- 🐛 Fix windows callback verification ([#22](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/22))
- 🐛 Force-update platform interface ([#21](https://github.com/ThexXTURBOXx/flutter_web_auth_2/pull/21))

## 2.0.1

- 🌹 Merge upstream changes (most notably troubleshooting documentation)
- 🌹 Added `redirectOriginOverride` for web implementations (By [Rexios80](https://github.com/Rexios80))
- 🌹 Fix some documentation and changelogs

## 2.0.0

- 💥 Full two-package federated plugin refactor

## 1.1.2

- 🌹 Support `win32` versions `2.7.0` until `3.x`

## 1.1.1

- 🐛 Fix Windows support and support for future platforms
- 🐛 Fix example on Windows
- 🌹 `127.0.0.1` is now also a supported callback URL host on Windows
- 🌹 Cleaned up platform implementations

## 1.1.0

- 🌹 Tested `flutter_web_auth_2` with Flutter `3.3.0`, seems to work!
- 🌹 Update `win32` to `3.0.0` (relevant only for Windows users)
- 🌹 Add `android:exported` tag to documentation *before* users start to complain
- 🌹 Overhauled example layout

## 1.0.1

- 🐛 Remove path dependency
- 🌹 Add migration guide README
- 🌹 Add more documentation

## 1.0.0

- 💥 Old project, new maintainers! Due to the lack of updates in the main project, we forked the project and will update it as time passes!
- 💥 Update to Flutter 3 ([#118](https://github.com/LinusU/flutter_web_auth/pull/118))
- 💥 Federated plugin refactor ([#98](https://github.com/LinusU/flutter_web_auth/pull/98))
- 💥 Windows support (By [Jon-Salmon](https://github.com/Jon-Salmon/flutter_web_auth/tree/windows-implementation))
- 🎉 Add support for ephemeral sessions on MacOS ([#112](https://github.com/LinusU/flutter_web_auth/pull/112))

## 0.4.1

- 🎉 Add support for Flutter "add to app" ([#106](https://github.com/LinusU/flutter_web_auth/pull/106))

## 0.4.0

- 💥 Upgrade to Android V2 embedding ([#87](https://github.com/LinusU/flutter_web_auth/pull/87))

  Migration guide:

  Make sure that you are running a recent version of Flutter before upgrading.

## 0.3.2

- 🎉 Add Web support ([#77](https://github.com/LinusU/flutter_web_auth/pull/77))

## 0.3.1

- 🎉 Add support for Android Plugin API v2 ([#67](https://github.com/LinusU/flutter_web_auth/pull/67))
- 🎉 Add support for ephemeral sessions ([#64](https://github.com/LinusU/flutter_web_auth/pull/64))
- 🌹 Avoid deprecated RaisedButton in example ([#75](https://github.com/LinusU/flutter_web_auth/pull/75))
- 🌹 Cleanup metadata

## 0.3.0

- 💥 Add null safety support ([#60](https://github.com/LinusU/flutter_web_auth/pull/60))

  Migration guide:

  This version drops support for Flutter 1.x, please upgrade to Flutter 2 for continued support.

## 0.2.4

- 🐛 Fix building on iOS ([#36](https://github.com/LinusU/flutter_web_auth/pull/36))

## 0.2.3

- 🐛 Remove NoHistory flag ([#33](https://github.com/LinusU/flutter_web_auth/pull/33))
- 🐛 Fix building on iOS 8, 9, and 10 ([#29](https://github.com/LinusU/flutter_web_auth/pull/29))
- 🐛 Always terminate 'authenticate' callbacks on Android ([#28](https://github.com/LinusU/flutter_web_auth/pull/28))

## 0.2.2

- 🐛 Fix propagation of "CANCELED" error on iOS ([#31](https://github.com/LinusU/flutter_web_auth/pull/31))

## 0.2.1

- 🐛 Fix AndroidX build issues ([#27](https://github.com/LinusU/flutter_web_auth/pull/27))

## 0.2.0

- 💥 Add macOS support ([#20](https://github.com/LinusU/flutter_web_auth/pull/20))

  Migration guide:

  This version drops support for Flutter 1.9 and older, please upgrade to Flutter 1.12 for continued support.

## 0.1.3

- 🎉 Update the kotlin plugin version to 1.3.61

## 0.1.2

- 🎉 Add support for iOS 13

## 0.1.1

- 🐛 Add swift_version to the Podspec
- 🐛 Update Gradle and Kotlin versions
- 🐛 Add missing link in readme

## 0.1.0

- 🎉 Add initial implementation
