#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  biometric_storage
  flutter_secure_storage_linux
  gtk
  handy_window
  hotkey_manager_linux
  isar_flutter_libs
  local_notifier
  local_proxy
  screen_capturer_linux
  screen_retriever_linux
  sodium_libs
  tray_manager
  url_launcher_linux
  window_manager
  window_to_front
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/linux plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
