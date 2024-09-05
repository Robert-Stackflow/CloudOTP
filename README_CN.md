## 介绍

基于 Flutter 的双因素验证器，支持Android和Windows平台，支持云备份。

## Highlights

- 基于Flutter架构重构，支持Android和Windows
- 支持TOTP、HOTP、MOTP、Steam、Yandex
- 支持扫码添加、识别图片、手动输入密钥
- 支持自定义图标和分类、支持排序和多种令牌布局（简洁、紧凑、列表、聚焦）
- 支持深色模式、多种语言、多种主题
- 支持本地备份和自动备份、支持WebDav、Onedrive、GoogleDrive、Dropbox、S3存储等多种云备份方式
- 支持导入/导出加密文件、URI列表
- 支持从Aegis、andOTP、Bitwarden、EntAuth、FreeOTP+、Google Authenticator、2FAS、TOTP Authenticator、Winauth导入数据
- 支持数据库加密、手势密码

## Screenshots

<img src="tools/art/mobile_1.png" alt="Mobile_1" style="zoom: 25%;" />

<img src="tools/art/desktop_1.png" alt="Desktop_1" style="zoom: 25%;" />

<img src="tools/art/mobile_2.png" alt="Mobile_2" style="zoom: 25%;" />

<img src="tools/art/mobile_3.png" alt="Mobile_3" style="zoom: 25%;" />

<img src="tools/art/desktop_2.png" alt="Desktop_2" style="zoom: 25%;" />

## TODOs

- 桌面端支持

  - 多窗口支持
  - 快捷键功能优化

- 小功能/小Bug

  - 开机自启动后最小化到托盘

  - 托盘锁定功能——未设置/已禁用
  - 修改语言时Tabbar全部未随之更改

- 次优先级

  - 自定义主题
  - 导入字体文件
  - icon逻辑修改——同一个icon多种匹配规则