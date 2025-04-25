//
// Created by yangbin on 2022/1/11.
//

#include "flutter_window.h"

#include "flutter_windows.h"

#include "tchar.h"

#include "resource.h"

#include <iostream>
#include <utility>

#include "include/desktop_multi_window/desktop_multi_window_plugin.h"
#include "multi_window_plugin_internal.h"

/// RustDesk deps using method channel
// #include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <window_size/window_size_plugin.h>
#include <texture_rgba_renderer/texture_rgba_renderer_plugin_c_api.h>
// #include <window_manager/window_manager_plugin.h>
// #include <screen_retriever/screen_retriever_plugin.h>
// #include <tray_manager/tray_manager_plugin.h>

void RustDeskRegisterPlugins(flutter::PluginRegistry* registry) {
    // BitsdojoWindowPluginRegisterWithRegistrar(
    //    registry->GetRegistrarForPlugin("BitsdojoWindowPlugin"));
    UrlLauncherWindowsRegisterWithRegistrar(
        registry->GetRegistrarForPlugin("UrlLauncherWindows"));
    WindowSizePluginRegisterWithRegistrar(registry->GetRegistrarForPlugin("WindowSizePlugin"));
    TextureRgbaRendererPluginCApiRegisterWithRegistrar(registry->GetRegistrarForPlugin("TextureRgbaRendererPlugin"));
    // WindowManagerPluginRegisterWithRegistrar(
    //     registry->GetRegistrarForPlugin("WindowManagerPlugin"));
    // ScreenRetrieverPluginRegisterWithRegistrar(
    //   registry->GetRegistrarForPlugin("ScreenRetrieverPlugin"));
    // TrayManagerPluginRegisterWithRegistrar(
    //  registry->GetRegistrarForPlugin("TrayManagerPlugin"));
}

bool IsWindows11OrGreater() {
  DWORD dwVersion = 0;
  DWORD dwBuild = 0;

#pragma warning(push)
#pragma warning(disable : 4996)
  dwVersion = GetVersion();
  // Get the build number.
  if (dwVersion < 0x80000000)
    dwBuild = (DWORD)(HIWORD(dwVersion));
#pragma warning(pop)

  return dwBuild < 22000;
}

namespace {

WindowCreatedCallback _g_window_created_callback = nullptr;

TCHAR kFlutterWindowClassName[] = _T("RustdeskMultiWindow");

int32_t class_registered_ = 0;

void RegisterWindowClass(WNDPROC wnd_proc) {
  if (class_registered_ == 0) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kFlutterWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = (HBRUSH) (COLOR_WINDOW + 1);
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = wnd_proc;
    RegisterClass(&window_class);
  }
  class_registered_++;
}

void UnregisterWindowClass() {
  class_registered_--;
  if (class_registered_ != 0) {
    return;
  }
  UnregisterClass(kFlutterWindowClassName, nullptr);
}

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
inline int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling *>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
    FreeLibrary(user32_module);
  }
}

}

FlutterWindow::FlutterWindow(
    HWND parent,
    int64_t id,
    std::string args,
    const std::shared_ptr<FlutterWindowCallback> &callback
) : callback_(callback), id_(id), window_handle_(nullptr), scale_factor_(1) {
  RegisterWindowClass(FlutterWindow::WndProc);

  const POINT target_point = {static_cast<LONG>(10),
                              static_cast<LONG>(10)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  scale_factor_ = dpi / 96.0;

  HWND window_handle = CreateWindow(
      kFlutterWindowClassName, L"", WS_OVERLAPPEDWINDOW,
      Scale(target_point.x, scale_factor_), Scale(target_point.y, scale_factor_),
      Scale(1280, scale_factor_), Scale(720, scale_factor_),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  RECT frame;
  GetClientRect(window_handle, &frame);
  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments({"multi_window", std::to_string(id), std::move(args)});
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    std::cerr << "Failed to setup FlutterViewController." << std::endl;
  }
  auto view_handle = flutter_controller_->view()->GetNativeWindow();
  SetParent(view_handle, window_handle);
  MoveWindow(view_handle, 0, 0, frame.right - frame.left, frame.bottom - frame.top, true);

  RustDeskRegisterPlugins(flutter_controller_->engine());
  InternalMultiWindowPluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("DesktopMultiWindowPlugin"));
  window_channel_ = WindowChannel::RegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("DesktopMultiWindowPlugin"), id_);

  if (_g_window_created_callback) {
    _g_window_created_callback(flutter_controller_.get());
  }

  // hide the window when created.
  ShowWindow(window_handle, SW_HIDE);

}

// static
FlutterWindow *FlutterWindow::GetThisFromHandle(HWND window) noexcept {
  return reinterpret_cast<FlutterWindow *>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

// static
LRESULT CALLBACK FlutterWindow::WndProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT *>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<FlutterWindow *>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (FlutterWindow *that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  auto child_content_ = flutter_controller_ ? flutter_controller_->view()->GetNativeWindow() : nullptr;

  switch (message) {
    case WM_NCCALCSIZE: {
        // This must always be first or else the one of other two ifs will execute
        //  when window is in full screen and we don't want that
        if (wparam && IsFullscreen()) {
            // Note:
            // I dont know why we should -3 on the bottom.
            //
            // NCCALCSIZE_PARAMS* sz = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
            // sz->rgrc[0].bottom -= 3;
            return 0;
        }
        // This must always be before handling title_bar_style_ == "hidden" so
        //  the if TitleBarStyle.hidden doesn't get executed.
        if (wparam && IsFrameless()) {
            NCCALCSIZE_PARAMS* sz = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
            // Add borders when maximized so app doesn't get cut off.
            if (IsMaximized()) {
                sz->rgrc[0].left += 8;
                sz->rgrc[0].top += 8;
                sz->rgrc[0].right -= 8;
                sz->rgrc[0].bottom -= 9;
            }
            // This cuts the app at the bottom by one pixel but that's necessary to
            // prevent jitter when resizing the app
            sz->rgrc[0].bottom += 1;
            return 0;
        }
        if (wparam && this->title_bar_style_ == "hidden") {
            NCCALCSIZE_PARAMS* sz = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
            // Add 8 pixel to the top border when maximized so the app isn't cut off
            if (this->IsMaximized()) {
                sz->rgrc[0].top += 8;
            }
            else {
                // on windows 10, if set to 0, there's a white line at the top
                // of the app and I've yet to find a way to remove that.
                sz->rgrc[0].top += IsWindows11OrGreater() ? 0 : 1;
            }
            sz->rgrc[0].right -= 8;
            sz->rgrc[0].bottom -= 8;
            sz->rgrc[0].left -= -8;
            // Previously (WVR_HREDRAW | WVR_VREDRAW), but returning 0 or 1 doesn't
            // actually break anything so I've set it to 0. Unless someone pointed a
            // problem in the future.
            return 0;
        }
        break;
    }
    case WM_SHOWWINDOW: {
      if (wparam == TRUE) {
        EmitEvent("show");
      } else {
        EmitEvent("hide");
      }
      break;
    }
    case WM_FONTCHANGE: {
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    }
    case WM_DESTROY:
      // prevent crash
      if (!destroyed_) {
        destroyed_ = true;
        // Give onDestroy callback to Flutter to close window gracefully
        if (window_channel_) {
            auto args = flutter::EncodableValue(flutter::EncodableMap());
            window_channel_->InvokeMethod(0, "onDestroy", &args);
            window_channel_->SetMethodCallHandler(nullptr);
            window_channel_.reset();
        }
        if (auto callback = callback_.lock()) {
          callback->OnWindowDestroy(id_);
        }
      }
      return 0;
    case WM_CLOSE: {
      EmitEvent("close");
      if (this->IsPreventClose()) {
        return -1;
      }
      if (auto callback = callback_.lock()) {
        callback->OnWindowClose(id_);
      }
      break;
    }
    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT *>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect;
      GetClientRect(window_handle_, &rect);
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      LONG_PTR gwlStyle =
          GetWindowLongPtr(window_handle_, GWL_STYLE);
      if ((gwlStyle & (WS_CAPTION | WS_THICKFRAME)) == 0 &&
          wparam == SIZE_MAXIMIZED) {
          EmitEvent("enter-full-screen");
          this->last_state = STATE_FULLSCREEN_ENTERED;
      }
      else if (this->last_state == STATE_FULLSCREEN_ENTERED &&
          wparam == SIZE_RESTORED) {
          ForceChildRefresh();
          EmitEvent("leave-full-screen");
          last_state = STATE_NORMAL;
      }
      else if (wparam == SIZE_MAXIMIZED) {
          EmitEvent("maximize");
          last_state = STATE_MAXIMIZED;
      }
      else if (wparam == SIZE_MINIMIZED) {
          EmitEvent("minimize");
          last_state = STATE_MINIMIZED;
      }
      else if (wparam == SIZE_RESTORED) {
          if (last_state == STATE_MAXIMIZED) {
              EmitEvent("unmaximize");
              last_state = STATE_NORMAL;
          }
          else if (last_state == STATE_MINIMIZED) {
              EmitEvent("restore");
              last_state = STATE_NORMAL;
          }
      }
      break;
    }

    case WM_ACTIVATE: {
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;
    }
    case WM_SIZING: {
        EmitEvent("resize");
        break;
    }

    case WM_MOVING: {
        EmitEvent("move");
        break;
    }
    case WM_NCACTIVATE: {
        char* eventName;
        if (wparam == TRUE) {
            eventName = "focus";
        }
        else {
            eventName = "blur";
        }
        EmitEvent(eventName);
        break;
    }

    default: break;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void FlutterWindow::EmitEvent(const char* eventName)
{
    auto params = flutter::EncodableMap();
    params.emplace(flutter::EncodableValue("eventName"), flutter::EncodableValue(eventName));
    auto args = flutter::EncodableValue(std::move(params));
    window_channel_->InvokeMethod(0, "onEvent", &args);
}

void FlutterWindow::Destroy() {
  if (window_channel_) {
    window_channel_ = nullptr;
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
}

FlutterWindow::~FlutterWindow() {
  this->Destroy();
  if (window_handle_) {
    std::cout << "window_handle leak." << std::endl;
  }
  UnregisterWindowClass();
}

void DesktopMultiWindowSetWindowCreatedCallback(WindowCreatedCallback callback) {
  _g_window_created_callback = callback;
}