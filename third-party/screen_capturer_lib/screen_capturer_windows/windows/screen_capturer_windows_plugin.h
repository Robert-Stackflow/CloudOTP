#ifndef FLUTTER_PLUGIN_SCREEN_CAPTURER_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SCREEN_CAPTURER_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace screen_capturer_windows {

class ScreenCapturerWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  ScreenCapturerWindowsPlugin();

  virtual ~ScreenCapturerWindowsPlugin();

  // Disallow copy and assign.
  ScreenCapturerWindowsPlugin(const ScreenCapturerWindowsPlugin&) = delete;
  ScreenCapturerWindowsPlugin& operator=(const ScreenCapturerWindowsPlugin&) =
      delete;

  void ScreenCapturerWindowsPlugin::CaptureScreen(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ScreenCapturerWindowsPlugin::ReadImageFromClipboard(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ScreenCapturerWindowsPlugin::SaveClipboardImageAsPngFile(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  std::vector<BYTE> ScreenCapturerWindowsPlugin::Hbitmap2PNG(HBITMAP hbitmap);
  bool ScreenCapturerWindowsPlugin::SaveHbitmapToPngFile(HBITMAP hbitmap,
                                                  std::string image_path);

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace screen_capturer_windows

#endif  // FLUTTER_PLUGIN_SCREEN_CAPTURER_WINDOWS_PLUGIN_H_
