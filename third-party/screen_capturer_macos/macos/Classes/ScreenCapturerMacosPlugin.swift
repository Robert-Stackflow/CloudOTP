import Cocoa
import FlutterMacOS

public class ScreenCapturerMacosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "dev.leanflutter.plugins/screen_capturer", binaryMessenger: registrar.messenger)
        let instance = ScreenCapturerMacosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAccessAllowed":
            isAccessAllowed(call, result: result)
            break
        case "requestAccess":
            requestAccess(call, result: result)
            break
        case "readImageFromClipboard":
            readImageFromClipboard(call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func isAccessAllowed(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(macOS 10.16, *) {
            result(CGPreflightScreenCaptureAccess())
            return
        };
        result(true)
    }
    
    public func requestAccess(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args:[String: Any] = call.arguments as! [String: Any]
        let onlyOpenPrefPane: Bool = args["onlyOpenPrefPane"] as! Bool
        
        if (!onlyOpenPrefPane) {
            if #available(macOS 10.16, *) {
                CGRequestScreenCaptureAccess()
            } else {
                // Fallback on earlier versions
            }
        } else {
            let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(prefpaneUrl)
        }
        result(true)
    }
    
    public func readImageFromClipboard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            result(nil)
            return
        }
        result(image.png)
    }
}

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }
}
