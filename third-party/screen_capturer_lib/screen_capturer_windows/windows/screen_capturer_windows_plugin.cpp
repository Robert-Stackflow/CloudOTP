#include "screen_capturer_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <atlimage.h>
#include <codecvt>
#include <fstream>
#include <map>
#include <memory>
#include <sstream>

const double kBaseDpi = 96.0;

namespace screen_capturer_windows {

// static
void ScreenCapturerWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "dev.leanflutter.plugins/screen_capturer",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ScreenCapturerWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ScreenCapturerWindowsPlugin::ScreenCapturerWindowsPlugin() {}

ScreenCapturerWindowsPlugin::~ScreenCapturerWindowsPlugin() {}

void ScreenCapturerWindowsPlugin::CaptureScreen(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  HWND hwnd = GetDesktopWindow();

  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  std::string image_path =
      std::get<std::string>(args.at(flutter::EncodableValue("imagePath")));
//  bool copy_to_clipboard =
//       std::get<bool>(args.at(flutter::EncodableValue("copyToClipboard")));

  flutter::EncodableMap result_map = flutter::EncodableMap();

  HDC hdcScreen;
  HDC hdcWindow;
  HDC hdcMemDC = NULL;
  HBITMAP hbitmap = NULL;

  // Retrieve the handle to a display device context for the client
  // area of the window.
  hdcScreen = GetDC(NULL);
  hdcWindow = GetDC(hwnd);

  // Create a compatible DC, which is used in a BitBlt from the window DC.
  hdcMemDC = CreateCompatibleDC(hdcWindow);

  if (!hdcMemDC) {
    result->Error("Failed", "CreateCompatibleDC has failed");
    return;
  }

  // Get the client area for size calculation.
  RECT rcClient;
  GetClientRect(hwnd, &rcClient);

  // This is the best stretch mode.
  SetStretchBltMode(hdcWindow, HALFTONE);

  // The source DC is the entire screen, and the destination DC is the current
  // window (HWND).
  if (!StretchBlt(hdcWindow, 0, 0, rcClient.right, rcClient.bottom, hdcScreen,
                  0, 0, GetSystemMetrics(SM_CXSCREEN),
                  GetSystemMetrics(SM_CYSCREEN), SRCCOPY)) {
    result->Error("Failed", "StretchBlt has failed");
    return;
  }

  // Create a compatible bitmap from the Window DC.
  hbitmap = CreateCompatibleBitmap(hdcWindow, rcClient.right - rcClient.left,
                                   rcClient.bottom - rcClient.top);

  if (!hbitmap) {
    result->Error("Failed", "CreateCompatibleBitmap Failed");
    return;
  }

  // Select the compatible bitmap into the compatible memory DC.
  SelectObject(hdcMemDC, hbitmap);

  // Bit block transfer into our compatible memory DC.
  if (!BitBlt(hdcMemDC, 0, 0, rcClient.right - rcClient.left,
              rcClient.bottom - rcClient.top, hdcWindow, 0, 0, SRCCOPY)) {
    result->Error("Failed", "BitBlt has failed");
    return;
  }

  if (!image_path.empty()) {
    bool saved = SaveHbitmapToPngFile(hbitmap, image_path);

    if (saved) {
        std::cout << "saved: " << image_path << std::endl;
      result_map[flutter::EncodableValue("imagePath")] =
          flutter::EncodableValue(image_path.c_str());
    }
  }

  DeleteObject(hbitmap);
  DeleteObject(hdcMemDC);
  ReleaseDC(NULL, hdcScreen);
  ReleaseDC(hwnd, hdcWindow);

  result->Success(flutter::EncodableValue(result_map));
}

void ScreenCapturerWindowsPlugin::ReadImageFromClipboard(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  HBITMAP hbitmap = NULL;

  OpenClipboard(nullptr);
  hbitmap = (HBITMAP)GetClipboardData(CF_BITMAP);
  CloseClipboard();

  if (hbitmap == NULL) {
    result->Success();
    return;
  }

  std::vector<BYTE> pngBuf = Hbitmap2PNG(hbitmap);
  result->Success(flutter::EncodableValue(pngBuf));
  pngBuf.clear();
}

void ScreenCapturerWindowsPlugin::SaveClipboardImageAsPngFile(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());

  std::string image_path =
      std::get<std::string>(args.at(flutter::EncodableValue("imagePath")));

  flutter::EncodableMap result_map = flutter::EncodableMap();
  HBITMAP hbitmap = NULL;

  OpenClipboard(nullptr);
  hbitmap = (HBITMAP)GetClipboardData(CF_BITMAP);
  CloseClipboard();

  bool saved = SaveHbitmapToPngFile(hbitmap, image_path);

  if (saved) {
    result_map[flutter::EncodableValue("imagePath")] =
        flutter::EncodableValue(image_path.c_str());
  }

  result->Success(flutter::EncodableValue(result_map));
}

std::vector<BYTE> ScreenCapturerWindowsPlugin::Hbitmap2PNG(HBITMAP hbitmap) {
  std::vector<BYTE> buf;
  if (hbitmap != NULL) {
    IStream* stream = NULL;
    CreateStreamOnHGlobal(0, TRUE, &stream);
    CImage image;
    ULARGE_INTEGER liSize;

    // screenshot to png and save to stream
    image.Attach(hbitmap);
    image.Save(stream, Gdiplus::ImageFormatPNG);
    IStream_Size(stream, &liSize);
    DWORD len = liSize.LowPart;
    IStream_Reset(stream);
    buf.resize(len);
    IStream_Read(stream, &buf[0], len);
    stream->Release();
  }
  return buf;
}

bool ScreenCapturerWindowsPlugin::SaveHbitmapToPngFile(HBITMAP hbitmap,
                                                       std::string image_path) {
  if (hbitmap != NULL) {
    std::vector<BYTE> buf;
    IStream* stream = NULL;
    CreateStreamOnHGlobal(0, TRUE, &stream);
    CImage image;
    ULARGE_INTEGER liSize;

    // screenshot to png and save to stream
    image.Attach(hbitmap);
    image.Save(stream, Gdiplus::ImageFormatPNG);
    IStream_Size(stream, &liSize);
    DWORD len = liSize.LowPart;
    IStream_Reset(stream);
    buf.resize(len);
    IStream_Read(stream, &buf[0], len);
    stream->Release();

    // put the imapge in the file
    std::fstream fi;
    fi.open(image_path, std::fstream::binary | std::fstream::out);
    fi.write(reinterpret_cast<const char*>(&buf[0]), buf.size() * sizeof(BYTE));
    fi.close();

    return true;
  }
  return false;
}

void ScreenCapturerWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string method_name = method_call.method_name();

  if (method_name.compare("captureScreen") == 0) {
    CaptureScreen(method_call, std::move(result));
  } else if (method_name.compare("readImageFromClipboard") == 0) {
    ReadImageFromClipboard(method_call, std::move(result));
  } else if (method_name.compare("saveClipboardImageAsPngFile") == 0) {
    SaveClipboardImageAsPngFile(method_call, std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace screen_capturer_windows
