# screen_capturer

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] [![All Contributors][all-contributors-image]](#contributors)

[pub-image]: https://img.shields.io/pub/v/screen_capturer.svg
[pub-url]: https://pub.dev/packages/screen_capturer
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

[all-contributors-image]: https://img.shields.io/github/all-contributors/leanflutter/screen_capturer?color=ee8449

这个插件允许 Flutter 桌面应用调整窗口的大小和位置。

---

[English](./README.md) | 简体中文

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [screen_capturer](#screen_capturer)
  - [平台支持](#平台支持)
  - [快速开始](#快速开始)
    - [安装](#安装)
      - [Windows requirements](#windows-requirements)
    - [用法](#用法)
    - [macOS](#macos)
  - [平台差异](#平台差异)
    - [CaptureMode](#capturemode)
  - [谁在用使用它？](#谁在用使用它)
  - [许可证](#许可证)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 平台支持

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|  ✔️   |  ✔️   |   ✔️    |

## 快速开始

### 安装

将此添加到你的软件包的 pubspec.yaml 文件：

```yaml
dependencies:
  screen_capturer: ^0.2.1
```

或

```yaml
dependencies:
  screen_capturer:
    git:
      path: packages/screen_capturer
      url: https://github.com/leanflutter/screen_capturer.git
      ref: main
```

#### Windows requirements

请务必修改你的 Visual Studio 安装，并确保 **"C++ ATL for latest v142 build tools (x86 & x64)"** 已安装

### 用法

### macOS

更改文件 `macos/Runner/DebugProfile.entitlements` 或 `macos/Runner/Release.entitlements` 如下：

> 仅在沙盒模式下需要。

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

> 请看这个插件的示例应用，以了解完整的例子。

## 平台差异

### CaptureMode

| Name     | Description                                | Linux | macOS | Windows |
| -------- | ------------------------------------------ | ----- | ----- | ------- |
| `region` | 在对象周围拖动光标以形成一个矩形。         | ✔️    | ✔️    | ✔️      |
| `screen` | 捕获整个屏幕。                             | ✔️    | ✔️    | ✔️      |
| `window` | 选择要捕获的窗口。（linux 只捕获当前窗口） | ➖    | ✔️    | ✔️      |

## 谁在用使用它？

- [Biyi (比译)](https://biyidev.com/) - 一个便捷的翻译和词典应用程序。

## 贡献者

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

## 许可证

[MIT](./LICENSE)
