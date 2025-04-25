import 'dart:ui';

import 'widgets/sub_drag_to_resize_area.dart';
import 'window_controller_impl.dart';

/// The [WindowController] instance that is used to control this window.
abstract class WindowController {
  WindowController();

  factory WindowController.fromWindowId(int id) {
    return WindowControllerMainImpl(id);
  }

  factory WindowController.main() {
    return WindowControllerMainImpl(0);
  }

  /// The id of the window.
  /// 0 means the main window.
  int get windowId;

  /// Close the window.
  Future<void> close();

  /// Show the window.
  Future<void> show();

  /// Hide the window.
  Future<void> hide();

  /// Focus the window.
  Future<void> focus();

  /// Start dragging the window.
  Future<void> startDragging();

  /// Maximize the window.
  Future<void> maximize();

  /// Unmaximize the window.
  Future<void> unmaximize();

  /// Judge if the window is maximized.
  Future<bool> isMaximized();

  /// Minimize the window
  Future<void> minimize();

  /// show the window of window
  Future<void> showTitleBar(bool show);

  /// Indicate if the window is in fullscreen mode.
  Future<bool> isFullScreen();

  /// Make the window full screen or not
  Future<void> setFullscreen(bool fullscreen);

  /// Set the window frame rect.
  Future<void> setFrame(Rect frame);

  /// Get the window frame rect.
  Future<Rect> getFrame() async {
    return Future.value(Rect.zero);
  }

  /// Center the window on the screen.
  Future<void> center();

  /// Set the window's title.
  Future<void> setTitle(String title);

  /// available only on macOS.
  Future<void> setFrameAutosaveName(String name);

  /// start resizing
  Future<void> startResizing(SubWindowResizeEdge resizeEdge);

  /// Check if is intercepting the native close signal.
  Future<bool> isPreventClose();

  /// Set if intercept the native close signal. May useful when combine with the onclose event listener.
  /// This will also prevent the manually triggered close event.
  Future<void> setPreventClose(bool isPreventClose);

  /// Get x11 id for specific window
  ///
  /// This is only valid in x11/Linux.
  Future<int> getXID();
}
