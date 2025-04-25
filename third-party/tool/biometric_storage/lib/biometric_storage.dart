export 'src/biometric_storage.dart';
export 'src/biometric_storage_win32_fake.dart'
    if (dart.library.io) 'src/biometric_storage_win32.dart';
