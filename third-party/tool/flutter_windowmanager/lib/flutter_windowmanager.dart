import 'dart:async';

import 'package:flutter/services.dart';

/// A base class for manipulating Android WindowManager.LayoutParams.
///
/// The class does not need to be instantiated directly, as it provides all
/// static flags and methods.
class FlutterWindowManager {
  // Flags for WindowManager.LayoutParams, as per
  // https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html

  /// Window flag: as long as this window is visible to the user, allow the lock screen to activate while the screen is on.
  static const int FLAG_ALLOW_LOCK_WHILE_SCREEN_ON = 0x00000001;

  /// Window flag: when set, inverts the input method focusability of the window.
  static const int FLAG_ALT_FOCUSABLE_IM = 0x00020000;

  /// Window flag: everything behind this window will be dimmed.
  static const int FLAG_DIM_BEHIND = 0x00000002;

  /// This constant was deprecated in API level 30. This value became API "by accident", and shouldn't be used by 3rd party applications.
  static const int FLAG_FORCE_NOT_FULLSCREEN = 0x00000800;

  /// This constant was deprecated in API level 30. Use WindowInsetsController#hide(int) with Type#statusBars() instead.
  static const int FLAG_FULLSCREEN = 0x00000400;

  /// Indicates whether this window should be hardware accelerated.
  static const int FLAG_HARDWARE_ACCELERATED = 0x01000000;

  /// Window flag: intended for windows that will often be used when the user is holding the screen against their face, it will aggressively filter the event stream to prevent unintended presses in this situation that may not be desired for a particular window, when such an event stream is detected, the application will receive a CANCEL motion event to indicate this so applications can handle this accordingly by taking no action on the event until the finger is released.
  static const int FLAG_IGNORE_CHEEK_PRESSES = 0x00008000;

  /// Window flag: as long as this window is visible to the user, keep the device's screen turned on and bright.
  static const int FLAG_KEEP_SCREEN_ON = 0x00000080;

  /// This constant was deprecated in API level 30. Insets will always be delivered to your application.
  static const int FLAG_LAYOUT_INSET_DECOR = 0x00010000;

  /// Window flag for attached windows: Place the window within the entire screen, ignoring any constraints from the parent window.
  static const int FLAG_LAYOUT_IN_SCREEN = 0x00000100;

  /// Window flag: allow window to extend outside of the screen.
  static const int FLAG_LAYOUT_NO_LIMITS = 0x00000200;

  /// Window flag: this window won't ever get key input focus, so the user can not send key or other button events to it.
  static const int FLAG_NOT_FOCUSABLE = 0x00000008;

  /// Window flag: this window can never receive touch events.
  static const int FLAG_NOT_TOUCHABLE = 0x00000010;

  /// Window flag: even when this window is focusable (its FLAG_NOT_FOCUSABLE is not set), allow any pointer events outside of the window to be sent to the windows behind it.
  static const int FLAG_NOT_TOUCH_MODAL = 0x00000020;

  /// Window flag: a special mode where the layout parameters are used to perform scaling of the surface when it is composited to the screen.
  static const int FLAG_SCALED = 0x00004000;

  /// Window flag: treat the content of the window as secure, preventing it from appearing in screenshots or from being viewed on non-secure displays.
  static const int FLAG_SECURE = 0x00002000;

  /// Window flag: ask that the system wallpaper be shown behind your window.
  static const int FLAG_SHOW_WALLPAPER = 0x00100000;

  /// Window flag: when set the window will accept for touch events outside of its bounds to be sent to other windows that also support split touch.
  static const int FLAG_SPLIT_TOUCH = 0x00800000;

  /// Window flag: if you have set FLAG_NOT_TOUCH_MODAL, you can set this flag to receive a single special MotionEvent with the action MotionEvent.ACTION_OUTSIDE for touches that occur outside of your window.
  static const int FLAG_WATCH_OUTSIDE_TOUCH = 0x00040000;

  /// Window flag: enable blur behind for this window.
  static const int FLAG_BLUR_BEHIND = 0x00000004;

  /// This constant was deprecated in API level 26. Use FLAG_SHOW_WHEN_LOCKED or KeyguardManager#requestDismissKeyguard instead. Since keyguard was dismissed all the time as long as an activity with this flag on its window was focused, keyguard couldn't guard against unintentional touches on the screen, which isn't desired.
  static const int FLAG_DISMISS_KEYGUARD = 0x00400000;

  /// This constant was deprecated in API level 17. This flag is no longer used.
  static const int FLAG_DITHER = 0x00001000;

  /// Flag indicating that this Window is responsible for drawing the background for the system bars.
  static const int FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS = 0x80000000;

  /// Window flag: When requesting layout with an attached window, the attached window may overlap with the screen decorations of the parent window such as the navigation bar. By including this flag, the window manager will layout the attached window within the decor frame of the parent window such that it doesn't overlap with screen decorations.
  static const int FLAG_LAYOUT_ATTACHED_IN_DECOR = 0x40000000;

  /// Window flag: allow window contents to extend in to the screen's overscan area, if there is one. The window should still correctly position its contents to take the overscan area into account.
  static const int FLAG_LAYOUT_IN_OVERSCAN = 0x02000000;

  /// Flag for a window in local focus mode.
  static const int FLAG_LOCAL_FOCUS_MODE = 0x10000000;

  /// Window flag: special flag to let windows be shown when the screen is locked. This will let application windows take precedence over key guard or any other lock screens. Can be used with FLAG_KEEP_SCREEN_ON to turn screen on and display windows directly before showing the key guard window. Can be used with FLAG_DISMISS_KEYGUARD to automatically fully dismisss non-secure keyguards. This flag only applies to the top-most full-screen window.
  static const int FLAG_SHOW_WHEN_LOCKED = 0x00080000;

  /// Window flag: when set, if the device is asleep when the touch screen is pressed, you will receive this first touch event. Usually the first touch event is consumed by the system since the user can not see what they are pressing on.
  static const int FLAG_TOUCHABLE_WHEN_WAKING = 0x00000040;

  /// Window flag: request a translucent navigation bar with minimal system-provided background protection.
  static const int FLAG_TRANSLUCENT_NAVIGATION = 0x08000000;

  /// Window flag: request a translucent status bar with minimal system-provided background protection.
  static const int FLAG_TRANSLUCENT_STATUS = 0x04000000;

  /// Window flag: when set as a window is being added or made visible, once the window has been shown then the system will poke the power manager's user activity (as if the user had woken up the device) to turn the screen on.
  static const int FLAG_TURN_SCREEN_ON = 0x00200000;

  static const MethodChannel _channel =
      const MethodChannel('flutter_windowmanager');

  /// Adds flags [flags] to the WindowManager.LayoutParams
  static Future<bool> addFlags(int flags) async {
    return await _channel.invokeMethod("addFlags", {
      "flags": flags,
    });
  }

  /// Clears flags [flags] from the WindowManager.LayoutParams
  static Future<bool> clearFlags(int flags) async {
    return await _channel.invokeMethod("clearFlags", {
      "flags": flags,
    });
  }
}
