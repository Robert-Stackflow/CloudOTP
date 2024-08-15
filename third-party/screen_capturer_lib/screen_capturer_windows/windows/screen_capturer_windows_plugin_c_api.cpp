#include "include/screen_capturer_windows/screen_capturer_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "screen_capturer_windows_plugin.h"

void ScreenCapturerWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  screen_capturer_windows::ScreenCapturerWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
