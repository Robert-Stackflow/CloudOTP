#import "FlutterWebAuth2Plugin.h"
#import <flutter_web_auth_2/flutter_web_auth_2-Swift.h>

@implementation FlutterWebAuth2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterWebAuth2Plugin registerWithRegistrar:registrar];
}
@end
