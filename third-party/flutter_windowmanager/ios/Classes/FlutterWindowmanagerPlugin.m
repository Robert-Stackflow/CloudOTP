#import "FlutterWindowmanagerPlugin.h"
#if __has_include(<flutter_windowmanager/flutter_windowmanager-Swift.h>)
#import <flutter_windowmanager/flutter_windowmanager-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_windowmanager-Swift.h"
#endif

@implementation FlutterWindowmanagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterWindowmanagerPlugin registerWithRegistrar:registrar];
}
@end
