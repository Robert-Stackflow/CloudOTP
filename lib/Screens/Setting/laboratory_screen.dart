import 'dart:async';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../Platform/ios/autofill_domain.dart';
import '../../Platform/ios/ios_services.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/biometric_util.dart';
import 'base_setting_screen.dart';

String laboratoryTitle(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'zh' => '实验室',
      'ja' => 'ラボ',
      _ => 'Laboratory',
    };

class LaboratoryScreen extends BaseSettingScreen {
  const LaboratoryScreen({super.key, super.padding, super.showTitleBar});
  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends BaseDynamicState<LaboratoryScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> _status = Map.of(IOSServices.cachedStatus ?? {});
  bool _busy = false;
  bool _ready = IOSServices.cachedStatus != null;
  String text(String zh, String en, [String? ja]) =>
      switch (Localizations.localeOf(context).languageCode) {
        'zh' => zh,
        'ja' => ja ?? en,
        _ => en,
      };
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await IOSServices.status();
      if (status['autofillSystemEnabled'] == true) {
        unawaited(IOSServices.syncAutoFill());
      }
      if (mounted) {
        setState(() {
          _status = status;
          _ready = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final previousPreventLock = appProvider.preventLock;
    appProvider.preventLock = true;
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) IToast.showTop(error.message ?? error.code);
    } finally {
      appProvider.preventLock = previousPreventLock;
      await _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableAutoFill() async {
    final allowed = await IOSServices.channel.invokeMethod<bool>(
        'enableAutoFill', {
      'reason':
          text('验证身份以启用验证码自动填充', 'Verify your identity to enable code AutoFill')
    });
    if (allowed == true) {
      try {
        await IOSServices.syncAutoFill(reportErrors: true);
      } catch (_) {
        await IOSServices.channel.invokeMethod('disableAutoFill');
        rethrow;
      }
    }
  }

  void _toggleAutoFill() {
    if (_status['autofillEnabled'] == true) {
      _perform(() async {
        await IOSServices.channel.invokeMethod('disableAutoFill');
      });
    } else {
      DialogBuilder.showConfirmDialog(context,
          title: text('启用自动填充？', 'Enable AutoFill?'),
          message: text(
              '系统扩展将保存本机 TOTP 副本。每次填充使用 Face ID 或设备密码验证，不要求主应用的手势或数据库密码；关闭后删除副本，不上传 iCloud。',
              'The extension stores a device-only TOTP copy. Every fill requires Face ID or the device passcode, not the main app gesture or database password. Disabling deletes the copy. No iCloud sync.'),
          onTapConfirm: () => _perform(_enableAutoFill));
    }
  }

  EntryItem entry(
          String title, String description, Future<void> Function() action,
          {bool enabled = true}) =>
      EntryItem(
        title: title,
        description: description,
        showTrailing: !_busy && enabled,
        onTap: _ready && !_busy && enabled ? () => _perform(action) : null,
      );
  @override
  Widget build(BuildContext context) => ItemBuilder.buildSettingScreen(
          context: context,
          title: laboratoryTitle(context),
          showTitleBar: widget.showTitleBar,
          padding: widget.padding,
          children: [
            ...[
              CaptionItem(
                  title: text('验证码自动填充', 'Verification code AutoFill'),
                  children: [
                    CheckboxItem(
                        title: text('启用自动填充', 'Enable AutoFill'),
                        description: text('仅同步标准 TOTP，每次填充需要系统身份验证。',
                            'Standard TOTP only; system authentication is required for every fill.'),
                        value: _status['autofillEnabled'] == true,
                        disabled: !_ready ||
                            _busy ||
                            _status['autofillAvailable'] != true,
                        onTap: _toggleAutoFill),
                    if (_ready && _status['autofillAvailable'] != true)
                      EntryItem(
                          title: text('当前签名不支持自动填充',
                              'AutoFill is unavailable with this signing configuration'),
                          description: text(
                              '需要具备资格的 Apple Developer Program 团队签名自动填充版本。',
                              'The AutoFill build requires an eligible Apple Developer Program team.'),
                          showTrailing: false),
                    entry(
                        text('系统自动填充设置', 'System AutoFill settings'),
                        _status['autofillSystemEnabled'] == true
                            ? text('CloudOTP 已启用', 'CloudOTP is enabled')
                            : text('在系统中开启 CloudOTP，需要 iOS 18 或更新版本。',
                                'Enable CloudOTP in system settings. Requires iOS 18 or later.'),
                        () async {
                      await IOSServices.channel
                          .invokeMethod('openAutoFillSettings');
                    }, enabled: _status['autofillAvailable'] == true),
                    entry(
                        text('同步自动填充令牌', 'Sync AutoFill tokens'),
                        text('令牌变更也会自动同步。',
                            'Token changes also sync automatically.'),
                        () => IOSServices.syncAutoFill(reportErrors: true),
                        enabled: _status['autofillEnabled'] == true),
                    EntryItem(
                        title: text('网站匹配', 'Website matching'),
                        description: text('为令牌指定网站域名，提供对应登录页的验证码建议。',
                            'Assign website domains for matching code suggestions.'),
                        showTrailing: _status['autofillEnabled'] == true,
                        onTap: _busy || _status['autofillEnabled'] != true
                            ? null
                            : () => RouteUtil.pushCupertinoRoute(
                                context, const _AutoFillDomainsScreen())),
                  ]),
              CaptionItem(title: text('身份验证', 'Authentication'), children: [
                entry(
                    text('验证 Face ID / Touch ID', 'Verify Face ID / Touch ID'),
                    text('生物识别解锁开关仍在安全设置中。',
                        'Biometric unlock preferences remain in Security settings.'),
                    () async {
                  if (await BiometricUtil.authenticateIOS() && mounted) {
                    IToast.showTop(text('身份验证成功', 'Identity verified'));
                  }
                }),
              ]),
              CaptionItem(title: text('通知', 'Notifications'), children: [
                CheckboxItem(
                    title: text('备份结果通知', 'Backup result notifications'),
                    description: text('仅在后台备份结束时提醒，不显示账户或验证码。',
                        'Background backup results only; no accounts or verification codes.'),
                    value: _status['notificationsEnabled'] == true &&
                        [2, 3, 4].contains(_status['notifications']),
                    disabled: !_ready || _busy,
                    onTap: () => _perform(() async {
                          if (_status['notificationsEnabled'] == true &&
                              [2, 3, 4].contains(_status['notifications'])) {
                            await IOSServices.channel
                                .invokeMethod('disableNotifications');
                          } else {
                            final allowed = await IOSServices.channel
                                .invokeMethod<bool>('requestNotifications');
                            if (allowed != true && mounted) {
                              IToast.showTop(text('请在系统设置中允许通知',
                                  'Allow notifications in system settings'));
                            }
                          }
                        })),
                entry(text('系统通知设置', 'System notification settings'), '',
                    () async {
                  await IOSServices.channel
                      .invokeMethod('openNotificationSettings');
                }),
              ]),
              CaptionItem(title: text('剪贴板', 'Clipboard'), children: [
                CheckboxItem(
                    title: text('跨设备复制验证码', 'Copy codes across devices'),
                    description: text('允许 Apple 通用剪贴板传输验证码；默认关闭，30 秒后过期。',
                        'Allow Apple Universal Clipboard; off by default, codes expire after 30 seconds.'),
                    value: _status['universalClipboard'] == true,
                    disabled: !_ready || _busy,
                    onTap: () => _perform(() async {
                          await IOSServices.channel.invokeMethod(
                              'universalClipboard', {
                            'enabled': _status['universalClipboard'] != true
                          });
                        })),
              ]),
            ],
            const SizedBox(height: 30),
          ]);
}

class _AutoFillDomainsScreen extends BaseSettingScreen {
  const _AutoFillDomainsScreen();
  @override
  State<_AutoFillDomainsScreen> createState() => _AutoFillDomainsScreenState();
}

class _AutoFillDomainsScreenState
    extends BaseDynamicState<_AutoFillDomainsScreen> {
  List<OtpToken> _tokens = [];
  Map<String, dynamic> _domains = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tokens = (await TokenDao.listTokens())
        .where((t) => t.tokenType == OtpTokenType.TOTP)
        .toList();
    if (mounted) {
      setState(() {
        _tokens = tokens;
        _domains = IOSServices.autoFillDomains;
      });
    }
  }

  String text(String zh, String en) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  void _edit(OtpToken token) {
    BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (_) => InputBottomSheet(
              title: token.issuer,
              hint: 'example.com',
              text: _domains[token.uid] as String? ?? '',
              keyboardType: TextInputType.url,
              validator: (value) => (value as String? ?? '').trim().isEmpty ||
                      normalizeAutoFillDomain(value as String) != null
                  ? null
                  : text('请输入有效域名，例如 example.com',
                      'Enter a valid domain, such as example.com'),
              onValidConfirm: (value) async {
                final domain = normalizeAutoFillDomain(value);
                final updated = Map<String, dynamic>.from(_domains);
                if (domain == null) {
                  updated.remove(token.uid);
                } else {
                  updated[token.uid] = domain;
                }
                try {
                  await IOSServices.saveDomains(updated);
                  await IOSServices.syncAutoFill(reportErrors: true);
                  if (mounted) setState(() => _domains = updated);
                } on PlatformException catch (error) {
                  IToast.showTop(error.message ?? error.code);
                }
              },
            ));
  }

  @override
  Widget build(BuildContext context) => ItemBuilder.buildSettingScreen(
          context: context,
          title: text('网站匹配', 'Website matching'),
          showTitleBar: true,
          padding: widget.padding,
          children: [
            CaptionItem(title: text('TOTP 令牌', 'TOTP tokens'), children: [
              for (final token in _tokens)
                EntryItem(
                    title: token.issuer,
                    description:
                        '${token.account} · ${_domains[token.uid] ?? ""}',
                    onTap: () => _edit(token)),
            ])
          ]);
}
