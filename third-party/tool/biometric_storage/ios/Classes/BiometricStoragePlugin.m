#import "BiometricStoragePlugin.h"
#import <biometric_storage/biometric_storage-Swift.h>

@implementation BiometricStoragePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBiometricStoragePlugin registerWithRegistrar:registrar];
}
@end
