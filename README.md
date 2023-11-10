## Introduction

This is a awesome two-factor authenticator for Android which supports dropbox.

The algorithm part comes from https://github.com/freeotp/freeotp-android.

## Highlights

- Support TOTP and HOTP
- Support manual filling and QR code scanning to add tokens
- Support import/export of JSON/URI file
- Support import/export of encrypted files (using standard AES-256 algorithm)
- Support backing up encrypted files to Dropbox
- Support password lock and biometric identification
- Support dark mode and switching theme colors
- Support multiple languages: English, Simplified Chinese, Traditional Chinese, Japanese

## Screenshots

<img src="art/lightmode.jpg" alt="Light Mode" style="zoom: 25%;" /><img src="art/darkmode.jpg" alt="Dark Mode" style="zoom: 25%;" /><img src="art/addtoken.jpg" alt="Add Token" style="zoom: 25%;" />

<img src="art/setting.jpg" alt="Setting" style="zoom: 25%;" /><img src="art/theme.jpg" alt="Theme" style="zoom: 25%;" /><img src="art/lock.jpg" alt="Lock" style="zoom: 25%;" />

<img src="art/export_import.jpg" alt="Export and  Import" style="zoom: 25%;" /><img src="art/dropbox.jpg" alt="Dropbox" style="zoom: 25%;" />
## TODO

- [ ] Support Google Drive
- [ ] Support WebDAV services such as Box
- [ ] Support more encryption algorithms
- [ ] Support encrypting local SQLite database
- [ ] Support desktop widgets

### Known Bugs

- [ ] When exporting a file, if you overwrite an existing file, the original article content cannot be cleared.
- [ ] When importing an encrypted file, if the file name is illegal (such as containing spaces), the import will fail.