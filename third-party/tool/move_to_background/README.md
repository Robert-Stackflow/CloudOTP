# move_to_background

Flutter plugin for sending mobile applications to background. Supports iOS and Android.

## Getting Started

### Install it (pubspec.yaml)

```yaml
move_to_background: <latest>
```

### Import it

```dart
import 'package:move_to_background/move_to_background.dart';
```

### Use it

```dart
MoveToBackground.moveTaskToBack();
```

## Useful Scenario

Use with WillPopScope to send your application to the background when the user attempts to exit the app.

```dart
WillPopScope(
  child: MaterialApp(...),
  onWillPop: () async {
    MoveToBackground.moveTaskToBack();
    return false;
  },
);
```

## Note about using it for iOS

Quitting your application or sending it to the background programmatically is a violation of the iOS [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/overview/themes/#//apple_ref/doc/uid/TP40006556-CH20-SW27), which usually doesn't bode well for getting through the review process. Keep that in mind.
