# ente_crypto_dart
The core of the ente's crypto library.

## Getting started

- Import the package
```dart
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
```
- Call the following inside the main function
```dart
WidgetsFlutterBinding.ensureInitialized();
initCryptoUtil();
```
- Just start consuming the CryptoUtil class, see usage below

## Usage

```dart
import 'package:ente_crypto_dart/ente_crypto_dart.dart';

final utf8Str = CryptoUtil.strToBin("Hello");
```

## Integration tests
Use the Following command for running them from the example directory of this project.

### Setup Files
Download and place [this file](https://github.com/ente-io/ente_crypto_dart/assets/41370460/a5012a0e-00ef-4c08-a001-c1102ea842d9) in example/test_data folder with file name `png-5mb-1.png`

**OR**

Run the following commands from terminal
```bash
cd example
flutter create .
mkdir test_data
cd test_data
curl -O https://freetestdata.com/wp-content/uploads/2021/09/png-5mb-1.png
cd ../..
```

### Running Tests
For this one remember to select a desktop target like macos as tests may fail on android & iOS due to clash of libsodium and on web as it is not supported
```bash
cd example
flutter test integration_test --dart-define=PWD=$(PWD)
```

## Additional information

This library is made by Ente.io developers and used in auth and photos app.

This is GPL-3.0 Licensed and wouldn't be possible without `libsodium` library and the `sodium` dart package.