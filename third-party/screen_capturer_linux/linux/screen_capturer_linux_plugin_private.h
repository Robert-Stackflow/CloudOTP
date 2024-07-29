#include <flutter_linux/flutter_linux.h>

#include "include/screen_capturer_linux/screen_capturer_linux_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

static void read_image_from_clipboard(FlMethodCall* method_call);