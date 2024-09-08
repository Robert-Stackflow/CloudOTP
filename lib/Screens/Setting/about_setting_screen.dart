import 'dart:async';
import 'dart:io';

import 'package:cloudotp/Screens/Setting/egg_screen.dart';
import 'package:cloudotp/Screens/Setting/update_log_screen.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Utils/uri_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/star_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Custom/no_shadow_scroll_behavior.dart';
import 'package:cloudotp/Widgets/Shake/shake_animation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Shake/shake_animation_type.dart';
import '../../Widgets/Shake/shake_animation_widget.dart';
import '../../generated/l10n.dart';

const countThreholdLevel1 = 3;
const countThreholdLevel2 = 6;
const countThreholdLevel3 = 12;
const countThreholdLevel4 = 18;
const countThreholdLevel5 = 24;

class AboutSettingScreen extends StatefulWidget {
  const AboutSettingScreen({super.key});

  static const String routeName = "/setting/about";

  @override
  State<AboutSettingScreen> createState() => _AboutSettingScreenState();
}

class _AboutSettingScreenState extends State<AboutSettingScreen>
    with TickerProviderStateMixin {
  int count = 0;
  late String appName = "";
  bool inAppBrowser = HiveUtil.getBool(HiveUtil.inappWebviewKey);

  Timer? _timer;
  Timer? _hapticTimer;
  final ShakeAnimationController _shakeAnimationController =
      ShakeAnimationController();

  String versionDetail = "";

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  Future<void> getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    versionDetail =
        "${ResponsiveUtil.platformName} ${packageInfo.version}+${packageInfo.buildNumber}";
    if (Platform.isWindows) {
      WindowsVersion version = FileUtil.checkWindowsVersion();
      if (version == WindowsVersion.portable) versionDetail += " Portable";
    }
    setState(() {});
  }

  diaplayCelebrate() {
    restore();
    RouteUtil.pushFadeRoute(context, const EggScreen());
    setState(() {});
  }

  restore() {
    count = 0;
    if (_timer != null) _timer!.cancel();
    if (_hapticTimer != null) _hapticTimer!.cancel();
    if (_shakeAnimationController.animationRuning) {
      _shakeAnimationController.stop();
    }
    setState(() {});
  }

  startShake() {
    _shakeAnimationController.start(shakeCount: 0);
  }

  setHapticTimer(Function() callback) {
    if (_hapticTimer != null) _hapticTimer!.cancel();
    _hapticTimer =
        Timer.periodic(const Duration(milliseconds: 10), (_) => callback());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtil.isLandscape()
          ? null
          : ItemBuilder.buildSimpleAppBar(
              transparent: true,
              leading: Icons.close_rounded,
              context: context,
            ),
      body: EasyRefresh(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 20),
            Center(
              child: ItemBuilder.buildClickItem(
                GestureDetector(
                  onLongPressStart: (details) {
                    if (_timer != null) _timer!.cancel();
                    _timer =
                        Timer.periodic(const Duration(seconds: 1), (timer) {
                      count = timer.tick;
                      if (count >= countThreholdLevel4 / 4) {
                        diaplayCelebrate();
                      } else if (count >= countThreholdLevel3 / 4) {
                        setHapticTimer(HapticFeedback.heavyImpact);
                      } else if (count >= countThreholdLevel2 / 4) {
                        setHapticTimer(HapticFeedback.mediumImpact);
                      } else if (count >= countThreholdLevel1 / 4) {
                        startShake();
                        setHapticTimer(HapticFeedback.lightImpact);
                      }
                      setState(() {});
                    });
                  },
                  onLongPressEnd: (details) {
                    restore();
                  },
                  child: ShakeAnimationWidget(
                    shakeAnimationController: _shakeAnimationController,
                    shakeAnimationType: ShakeAnimationType.RandomShake,
                    isForward: false,
                    shakeRange: 0.1,
                    child: Hero(
                      tag: "logo-egg",
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              alignment: Alignment.center,
              child: Text(
                appName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              alignment: Alignment.center,
              child: Text(
                versionDetail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: ScrollConfiguration(
                behavior: NoShadowScrollBehavior(),
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.changeLog,
                      topRadius: true,
                      showLeading: true,
                      onTap: () {
                        RouteUtil.pushCupertinoRoute(
                            context, const UpdateLogScreen());
                      },
                      leading: Icons.merge_type_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.bugReport,
                      onTap: () {
                        UriUtil.launchUrlUri(context, issueUrl);
                      },
                      showLeading: true,
                      leading: Icons.bug_report_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.githubRepo,
                      onTap: () {
                        UriUtil.launchUrlUri(context, repoUrl);
                      },
                      showLeading: true,
                      leading: Icons.commit_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.privacyPolicy,
                      onTap: () {
                        Locale locale = Localizations.localeOf(context);
                        UriUtil.launchUrlUri(
                            context, privacyPolicyUrl + locale.languageCode);
                      },
                      showLeading: true,
                      leading: Icons.privacy_tip_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.serviceTerm,
                      onTap: () {
                        Locale locale = Localizations.localeOf(context);
                        UriUtil.launchUrlUri(
                            context, serviceTermUrl + locale.languageCode);
                      },
                      showLeading: true,
                      bottomRadius: true,
                      leading: Icons.topic_outlined,
                    ),
                    const SizedBox(height: 10),
                    ItemBuilder.buildEntryItem(
                      topRadius: true,
                      context: context,
                      title: S.current.rate,
                      showLeading: true,
                      onTap: () {
                        BottomSheetBuilder.showBottomSheet(
                          context,
                          (context) => const StarBottomSheet(),
                          responsive: true,
                        );
                      },
                      leading: Icons.rate_review_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.shareApp,
                      showLeading: true,
                      onTap: () {
                        Share.share(shareAppText);
                      },
                      leading: Icons.share_rounded,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.contact,
                      onTap: () {
                        UriUtil.launchEmailUri(
                          context,
                          feedbackEmail,
                          subject: feedbackSubject,
                          body: feedbackBody,
                        );
                      },
                      showLeading: true,
                      leading: Icons.contact_support_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.officialWebsite,
                      onTap: () {
                        UriUtil.launchUrlUri(context, officialWebsite);
                      },
                      showLeading: true,
                      leading: Icons.language_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.telegramGroup,
                      onTap: () {
                        UriUtil.openExternal(telegramLink);
                      },
                      bottomRadius: true,
                      showLeading: true,
                      leading: Icons.telegram_outlined,
                    ),
                    const SizedBox(height: 10)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
