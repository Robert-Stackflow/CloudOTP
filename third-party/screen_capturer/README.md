# screen_capturer

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] [![All Contributors][all-contributors-image]](#contributors)

[pub-image]: https://img.shields.io/pub/v/screen_capturer.svg
[pub-url]: https://pub.dev/packages/screen_capturer
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

[all-contributors-image]: https://img.shields.io/github/all-contributors/leanflutter/screen_capturer?color=ee8449

This plugin allows Flutter desktop apps to take screenshots.

---

English | [简体中文](./README-ZH.md)

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [screen_capturer](#screen_capturer)
  - [Platform Support](#platform-support)
  - [Quick Start](#quick-start)
    - [Installation](#installation)
      - [Windows requirements](#windows-requirements)
    - [Usage](#usage)
    - [macOS](#macos)
  - [Platform Differences](#platform-differences)
    - [CaptureMode](#capturemode)
  - [Who's using it?](#whos-using-it)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Platform Support

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|  ✔️   |  ✔️   |   ✔️    |

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  screen_capturer: ^0.2.1
```

Or

```yaml
dependencies:
  screen_capturer:
    git:
      path: packages/screen_capturer
      url: https://github.com/leanflutter/screen_capturer.git
      ref: main
```

#### Windows requirements

Be sure to modify your Visual Studio installation and ensure that **"C++ ATL for latest v142 build tools (x86 & x64)"** is installed!

### Usage

### macOS

Change the file `macos/Runner/DebugProfile.entitlements` or `macos/Runner/Release.entitlements` as follows:

> Required only for sandbox mode.

```diff
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
+	<key>com.apple.security.temporary-exception.mach-register.global-name</key>
+	<string>com.apple.screencapture.interactive</string>
</dict>
</plist>
```

```dart
import 'package:screen_capturer/screen_capturer.dart';

CapturedData? capturedData = await screenCapturer.capture(
  mode: CaptureMode.region, // screen, window
  imagePath: '<path>',
  copyToClipboard: true,
);
```

> Please see the example app of this plugin for a full example.

## Platform Differences

### CaptureMode

| Name     | Description                                                                        | Linux | macOS | Windows |
| -------- | ---------------------------------------------------------------------------------- | ----- | ----- | ------- |
| `region` | Drag the cursor around an object to form a rectangle.                              | ✔️    | ✔️    | ✔️      |
| `screen` | Capture the entire screen.                                                         | ✔️    | ✔️    | ✔️      |
| `window` | Select a window, that you want to capture. (linux capture only the current window) | ➖    | ✔️    | ✔️      |

## Who's using it?

- [Biyi (比译)](https://biyidev.com/) - A convenient translation and dictionary app.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lijy91"><img src="https://avatars.githubusercontent.com/u/3889523?v=4?s=100" width="100px;" alt="LiJianying"/><br /><sub><b>LiJianying</b></sub></a><br /><a href="https://github.com/leanflutter/screen_capturer/commits?author=lijy91" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/amit548"><img src="https://avatars.githubusercontent.com/u/36206377?v=4?s=100" width="100px;" alt="Amit Mondal"/><br /><sub><b>Amit Mondal</b></sub></a><br /><a href="https://github.com/leanflutter/screen_capturer/commits?author=amit548" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lightrabbit"><img src="https://avatars.githubusercontent.com/u/1521765?v=4?s=100" width="100px;" alt="lightrabbit"/><br /><sub><b>lightrabbit</b></sub></a><br /><a href="https://github.com/leanflutter/screen_capturer/commits?author=lightrabbit" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://liuyu.xin/"><img src="https://avatars.githubusercontent.com/u/79075347?v=4?s=100" width="100px;" alt="liuyuxin"/><br /><sub><b>liuyuxin</b></sub></a><br /><a href="https://github.com/leanflutter/screen_capturer/commits?author=gvenusleo" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://boring.cool/"><img src="https://avatars.githubusercontent.com/u/16132584?v=4?s=100" width="100px;" alt="kalykun"/><br /><sub><b>kalykun</b></sub></a><br /><a href="https://github.com/leanflutter/screen_capturer/commits?author=kungege" title="Documentation">📖</a></td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <td align="center" size="13px" colspan="7">
        <img src="https://raw.githubusercontent.com/all-contributors/all-contributors-cli/1b8533af435da9854653492b1327a23a4dbd0a10/assets/logo-small.svg">
          <a href="https://all-contributors.js.org/docs/en/bot/usage">Add your contributions</a>
        </img>
      </td>
    </tr>
  </tfoot>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

## License

[MIT](./LICENSE)
