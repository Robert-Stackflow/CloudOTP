# CloudOTP

**CloudOTP** is a modern, cross-platform two-factor authenticator built with Flutter. 

It supports Android, Windows, and Linux, offering secure cloud backups, powerful token management, and a polished UI optimized for mobile, tablet, and desktop.

## 🚀 Highlights

### 🌐 Cross-Platform Support

- Built with Flutter, runs seamlessly on **Android**, **Windows**, and **Linux**
- UI fully optimized for **mobile**, **tablet**, and **desktop** environments

### 🔐 OTP Protocols

- Supports **TOTP**, **HOTP**, **MOTP**, **Steam**, and **Yandex** token algorithms

### ➕ Token Management

- Add tokens via **QR code scanning**, **image recognition**, or **manual entry**
- Custom icons and categories
- Flexible layout modes: **Simple**, **Compact**, **List**, and **Spotlight**
- Supports **sorting** and **searching** for quick access

### 🌓 Themes & UI

- Fully responsive and adaptive UI for all device sizes
- Supports **dark mode**, **multiple color themes**, and **multi-language UI**

### ☁️ Backup & Sync

- Supports **local** and **automatic cloud backup**
- Integrates with **WebDAV**, **OneDrive**, **Dropbox**, **S3**, **Google Drive**, **Box**, **Huawei Cloud**, **Aliyun Drive**

### 🔁 Import/Export

- Export/import as **encrypted files** or **URI lists**
- One-click import from: **Aegis**, **andOTP**, **Bitwarden**, **EntAuth**, **FreeOTP+**, **Google Authenticator**, **2FAS**, **TOTP Authenticator**, **WinAuth**

### 🛡️ Security

- Encrypted database storage
- Supports **gesture password** for app access
- Supports **biometric unlock**

## 📦 Installation

### 📱 Android

**Choose the correct ABI:**

| Variant       | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `arm64-v8a`   | For modern 64-bit Android devices (recommended for most users) |
| `armeabi-v7a` | For most older 32-bit Android devices                        |
| `x86_64`      | For Android emulators or specific x86 tablets (not for regular devices) |
| `universal`   | Supports **all CPU architectures**, larger file size (recommended for most) |

If unsure, use the `universal` version. You can use tools like [Droid Info](https://play.google.com/store/apps/details?id=com.vndnguyen.deviceinfo) to check your device's architecture.

### 💻 Windows

| Variant            | Description                                                  |
| ------------------ | ------------------------------------------------------------ |
| `Installer (.exe)` | Standard Windows installer with Start Menu integration and auto-updates |
| `Portable (.zip)`  | No installation required, can be run from any folder or USB stick |

> **Note:** Currently, only **x86_64 (64-bit)** Windows systems are supported.

### 🐧 Linux

#### 📦 Recommended: Flatpak

Install via [Flathub](https://flathub.org/apps/com.cloudchewie.cloudotp):

```bash
flatpak install flathub com.cloudchewie.cloudotp
```

Once installed, launch it via your app menu or by running:

```bash
flatpak run com.cloudchewie.cloudotp
```

#### 📥 Direct Downloads

Also available as `.deb` and `.tar.gz` packages from the [Releases](https://github.com/your-repo/releases) page.

| Architecture | Formats Available | Notes                         |
| ------------ | ----------------- | ----------------------------- |
| `x86_64`     | `.deb`, `.tar.gz` | For most modern Linux systems |
| `arm64`      | `.deb`, `.tar.gz` | For devices like Raspberry Pi |

## 🧪 Development Setup

```bash
git clone https://github.com/Robert-Stackflow/CloudOTP.git
cd cloudotp
flutter pub get
flutter gen-l10n
cd third-party/chewie
flutter gen-l10n
cd ../../
flutter run -d windows   # or android, linux
````

## 📝 Roadmap

* [ ] iOS support (via macOS build)
* [ ] Custom theme
* [ ] Import custom icons

## 🤝 Contributing

Contributions, issues and feature requests are welcome!

Feel free to check the [issues page](https://github.com/Robert-Stackflow/CloudOTP/issues) or submit a PR.

## 📄 License

This project is licensed under the GPL-V3.0 License - see the [LICENSE](LICENSE) file for details.

## 📷 Screenshots

<img src="tools/art/mobile_1.png" alt="Mobile_1" style="zoom: 25%;" />

<img src="tools/art/desktop_1.png" alt="Desktop_1" style="zoom: 25%;" />

<img src="tools/art/mobile_2.png" alt="Mobile_2" style="zoom: 25%;" />

<img src="tools/art/mobile_3.png" alt="Mobile_3" style="zoom: 25%;" />

<img src="tools/art/desktop_2.png" alt="Desktop_2" style="zoom: 25%;" />

