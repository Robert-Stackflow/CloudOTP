# CloudOTP

**CloudOTP** 是一款现代、跨平台的双因素身份验证器，使用 Flutter 构建。

支持 Android、Windows 和 Linux，提供安全的云备份、强大的令牌管理功能。

## 🚀 功能亮点

### 🌐 跨平台支持

- 基于 Flutter 构建，可在 **Android**、**Windows** 和 **Linux** 上流畅运行
- 界面为 **手机**、**平板** 和 **桌面** 环境精心优化

### 🔐 OTP 协议支持

- 支持 **TOTP**、**HOTP**、**MOTP**、**Steam** 和 **Yandex** 等令牌算法

### ➕ 令牌管理

- 通过 **二维码扫描**、**图片识别** 或 **手动输入** 添加令牌
- 支持自定义图标与分类
- 多种布局模式：**简洁**、**紧凑**、**列表**、**聚焦**
- 支持 **排序** 和 **搜索**

### 🌓 主题与界面

- 完全响应式和自适应 UI，适配所有设备尺寸
- 支持 **深色模式**、**多种配色主题** 与 **多语言界面**

### ☁️ 云备份与同步

- 支持 **本地备份** 与 **自动云备份**
- 集成多种云服务：**WebDAV**、**OneDrive**、**Dropbox**、**S3**、**Google Drive**、**Box**、**华为云**、**阿里云盘**

### 🔁 导入与导出

- 支持导出/导入为 **加密文件** 或 **URI 列表**
- 一键导入支持：**Aegis**、**andOTP**、**Bitwarden**、**EntAuth**、**FreeOTP+**、**Google Authenticator**、**2FAS**、**TOTP Authenticator**、**WinAuth**

### 🛡️ 安全性

- 本地数据库加密存储
- 支持 **手势密码** 解锁
- 支持 **生物识别** 解锁

## 📦 安装指南

### 📱 Android

**请选择合适的 ABI 架构版本，**如不确定设备架构，建议下载 `universal` 版本

| 版本          | 说明                                                       |
| ------------- | ---------------------------------------------------------- |
| `arm64-v8a`   | 适用于大多数现代 64 位 Android 设备（推荐）                |
| `armeabi-v7a` | 适用于多数旧款 32 位 Android 设备                          |
| `x86_64`      | 适用于 Android 模拟器或部分 x86 平板（不推荐普通用户使用） |
| `universal`   | 支持所有 CPU 架构，文件体积较大（推荐大多数用户使用）      |

### 💻 Windows

| 版本               | 说明                                      |
| ------------------ | ----------------------------------------- |
| `Installer (.exe)` | 标准安装程序，支持自动更新                |
| `Portable (.zip)`  | 免安装版，可直接运行于任意文件夹或 U 盘中 |

> **注意：** 当前仅支持 **x86_64（64 位）** 的 Windows 系统。

### 🐧 Linux

#### 📦 推荐方式：Flatpak 安装

可通过 [Flathub](https://flathub.org/apps/com.cloudchewie.cloudotp) 安装：

```bash
flatpak install flathub com.cloudchewie.cloudotp
```

安装后可通过应用菜单启动，或运行：

```bash
flatpak run com.cloudchewie.cloudotp
```

#### 📥 直接下载

| 架构     | 提供格式          | 说明                              |
| -------- | ----------------- | --------------------------------- |
| `x86_64` | `.deb`, `.tar.gz` | 适用于大多数现代 Linux 系统       |
| `arm64`  | `.deb`, `.tar.gz` | 适用于 Raspberry Pi 等 ARM64 设备 |

## 🧪 开发环境配置

```bash
git clone https://github.com/Robert-Stackflow/CloudOTP.git
cd cloudotp
flutter pub get
flutter gen-l10n
cd third-party/chewie
flutter gen-l10n
cd ../../
flutter run -d windows   # 也可指定 android、linux 等平台
```

## 📝 开发计划

* [ ] iOS 支持（通过 macOS 构建）
* [ ] 自定义主题
* [ ] 导入自定义图标

## 🤝 欢迎贡献

欢迎提交 PR、反馈问题或提出功能建议！

你可以浏览 [issues 页面](https://github.com/Robert-Stackflow/CloudOTP/issues)，或者直接提交代码贡献

## 📄 许可证

本项目遵循 GPL-3.0 协议，详情请查阅 [LICENSE](https://chatgpt.com/c/LICENSE) 文件

## 📷 截图

<img src="tools/art/mobile_1.png" alt="Mobile_1" style="zoom: 25%;" />

<img src="tools/art/desktop_1.png" alt="Desktop_1" style="zoom: 25%;" />

<img src="tools/art/mobile_2.png" alt="Mobile_2" style="zoom: 25%;" />

<img src="tools/art/mobile_3.png" alt="Mobile_3" style="zoom: 25%;" />

<img src="tools/art/desktop_2.png" alt="Desktop_2" style="zoom: 25%;" />