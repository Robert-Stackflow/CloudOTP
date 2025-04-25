## 5.1.0-rc.5

* upgrade dependency to web 1.0

## 5.1.0-rc.4

* enable building on jdk 17 and up https://github.com/authpass/biometric_storage/issues/117 thanks @connyduck

## 5.1.0-rc.3

* Split Split authenticationValidityDurationSeconds between android and iOS
  * `darwinTouchIDAuthenticationForceReuseContextDuration`: Basically the equivalent to `androidAuthenticationValidityDuration`
  * `darwinTouchIDAuthenticationAllowableReuseDuration`
* android: return correct code if no biometric is enrolled #115 @ThomasLamprecht
* web: migrate from dart:html to package:web (for wasm support).

## 5.0.1

* Add option for iOS/MacOS to allow non-biometric authentication (`darwinBiometricOnly`) #101
  * Improve [canAuthenticate] to differentiate between no available biometry and no available 
    user code.
* Bump dart sdk requirement to `3.2`.

## 5.0.0+4

* Add topics to pubspec.yaml

## 5.0.0+3

* Android: Upgrade AGP, fix building with AGP 8
* Android: Depend on slf4j-api.

## 5.0.0+1

* MacOS: fix building on MacOS

## 5.0.0

* Allow overriding of `promptInfo` during `read`/`write` thanks @luckyrat
* Android: (POTENTIALLY BREAKING): Completely removed deprecated old file backend 
  based on `androidx.security`. This was deprecated since version 3.0.0 and users 
  should have been migrated on every read or write. (this is only internally, does not change
  anything of the API).
* Update dependencies.

## 4.1.3

* iOS/MacOS: Reuse LAContext to make `touchIDAuthenticationAllowableReuseDuration` work.
    thanks @radvansky-tomas

## 4.1.2

* Android: Move File I/O and encryption to background thread. (Previously used UI Thread)
     https://github.com/authpass/biometric_storage/pull/64   

## 4.1.1

* Fix building on all platforms, add github actions to test building.

## 4.1.0

* Android: Remove Moshi dependency altogether. #53

## 4.0.1

* Update to Moshi 1.13 for Kotlin 1.6.0 compatibility. #53 

## 4.0.0

* Fixed compile errors with Flutter >= 2.8.0 (Compatible with Flutter 2.5). #47 fix #42

## 3.0.1

* Android: Validate options on `int`
  When `authenticationValidityDurationSeconds == -1`, then `androidBiometricOnly` must be `true`
* Android: if `authenticationValidityDurationSeconds` is `> 0` only show authentication prompt when
  necessary. (It will simply try to use the key, and show the auth prompt only when a
  `UserNotAuthenticatedException` is thrown).
* Android: When biometric key is invalidated (e.g. because biometric security is changed on the 
  device), we simply delete the old key and data! (KeyPermanentlyInvalidatedException)

## 3.0.0

* Stable Release 🥳
* **Please check below for breaking changes in the `-rc` releases.

## 3.0.0-rc.12

* Android: Fix a few bugs with `authenticationValidityDurationSeconds` == -1
* iOS/MacOS: Don't set timeout for `authenticationValidityDurationSeconds` == -1
* iOS/MacOS: Don't raise an error on `delete` if item was not found.
* Android: Fix user cancel code. 
  (Previously an `unknown` exception was thrown instead of `userCanceled`)
* Android: Ignore `androidBiometricOnly` prior to Android R (30).
* Introduce `AuthExceptionCode.canceled`

## 3.0.0-rc.7

* **Breaking Change**: `authenticationValidityDurationSeconds` is now `-1` by default, which was
  not supported before hand. If you need backward compatibility, make sure to override this value
  to the previous value of `10`.
* **Breaking Change**: No more support for Android v1 Plugin registration.
* **Breaking Change**: No longer using androidx.security, but instead handle encryption
  directly. Temporarily there is a fallback to read old content. This requires either reencrypting
  everything, or old data will no longer be readable.
  
  1. This should fix a lot of errors.
  2. This now finally also allows using `authenticationValidityDurationSeconds` = -1.
  3. `BIOMETRIC_WEAK` is no longer used, only `BIOMETRIC_STRONG`.
* Don't ask for authentication for delete.

## 3.0.0-rc.5

* **Breaking Change**: due to the introduction of iOS prompt info there is now a wrapper object
  `PromptInfo` which contains `AndroidPromptInfo` and `IosPromptInfo`.
* Android: Add support for local (non-biometric) storage (#28, thanks @killalad)
* Android: Update all gradle dependencies, removed gradle-wrapper from plugin folder.
* iOS: Add support for customizing prompt strings.
* MacOS: Add support for customizing prompt strings.

## 2.0.3

* Android
  * compatibility with kotlin 1.5.20
  * Remove jcenter() references.
  * androidx.core:core:1.3.2 to 1.6.0
  * moshi from 1.11.0 to 1.12.0 (this is the kotlin 1.5.20 compatibility problem)

## 2.0.2

* Android upgrade dependencies:
  * androidx.security:security-crypto from 1.1.0-alpha02 to 1.1.0-alpha03
  * androidx.biometric:biometric from 1.1.0-beta01 to 1.2.0-alpha03
  * Update README to clarify minSdkVersion and kotlin version

## 2.0.1

* Handle android `BIOMETRIC_STATUS_UNKNOWN` response on older devices
  (Android 9/API 28(?))

## 2.0.0

* Null safety stable release.

## 2.0.0-nullsafety.1

* Null safety migration.

## 1.1.0+1

* upgrade android moshi dependency.

## 1.1.0

* Upgrade to latest Android dependencies (gradle plugin, androidx.*, gradle plugin)
  * [androidx.security:security-crypto](https://developer.android.com/jetpack/androidx/releases/security) 1.0.0-rc02 to 1.1.0-alpha02
  * [androidx.biometric:biometric](https://developer.android.com/jetpack/androidx/releases/biometric) 1.0.1 to 1.1.0-beta01

## 1.0.1+5

* Workaround to not load win32 when compiling for web.

## 1.0.1+4

* Fix windows plugin config.

## 1.0.1+1

* Support for web support: **Warning**: Unencrypted - stores into local storage on web!
* Updated README to add details about windows.

## 1.0.0

* Windows: Initial support for windows. only unauthenticated storage in Credential Manager.

## 0.4.1

* Linux: Improve snap compatibility by detecting AppArmor error to prompt users to connect
         to password-manager-service.

## 0.4.0

* Linux: Initial support for Linux - only unauthenticated storage in Keyring.

## 0.3.4+6

* Android: androidx.security 1.0.0-rc02 needs another proguard rule.
  https://github.com/google/tink/issues/361

## 0.3.4+5

* Android: Upgrade to androidx.security 1.0.0-rc02 which should fix protobuf incompatibilities
  #6 https://developer.android.com/jetpack/androidx/releases/security#security-crypto-1.0.0-rc02

## 0.3.4+4

* Android: fix PromptInfo deserialization with minification.
* Android: add proguard setting to fix protobuf exceptions.

## 0.3.4+2

* Android: updated dependencies to androidx.security, biometric, gradle tools.

## 0.3.4+1

* Android: on error send stack trace to flutter. also fixed a couple of warnings.

## 0.3.4

* Android: allow customization of the PromptInfo (labels, buttons, etc).
  @patrickhammond

## 0.3.3

* ios: added swift 5 dependency to podspec to fix compile errors
       https://github.com/authpass/biometric_storage/issues/3

## 0.3.2

* android: fingerprint failures don't cancel the dialog, so don't trigger error callback. #2
  (fixes crash)

## 0.3.1

* Use android v2 plugin API.

## 0.3.0-beta.2

* Use new plugin format for Mac OS format. Not compatible with flutter 1.9.x

## 0.2.2+2

* Use legacy plugin platforms structure to be compatible with flutter stable.

## 0.2.2+1

* fixed home page link, updated example README. 

## 0.2.2

* Android: Use codegen instead of reflection for json serialization.
  (Fixes bug that options aren't assed in correctly due to minification)

## 0.2.1

* Android: Fix for having multiple files with different configurations.
* Correctly handle UserCanceled events.
* Define correct default values on dart side (10 seconds validity timeout).

## 0.2.0

* MacOS Support

## 0.1.0

* iOS Support
* Support for non-authenticated storage (ie. secure/encrypted storage, 
  without extra biometric authenticatiton prompts)
* delete()'ing files.

## 0.0.1 - Initial release

* Android Support.
