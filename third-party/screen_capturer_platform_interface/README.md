# screen_capturer_platform_interface

[![pub version][pub-image]][pub-url]

[pub-image]: https://img.shields.io/pub/v/screen_capturer_platform_interface.svg
[pub-url]: https://pub.dev/packages/screen_capturer_platform_interface

A common platform interface for the [screen_capturer](https://pub.dev/packages/screen_capturer) plugin.

## Usage

To implement a new platform-specific implementation of screen_capturer, extend `ScreenCapturerPlatform` with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default `ScreenCapturerPlatform` by calling `ScreenCapturerPlatform.instance = MyPlatformScreenCapturer()`.

## License

[MIT](./LICENSE)
