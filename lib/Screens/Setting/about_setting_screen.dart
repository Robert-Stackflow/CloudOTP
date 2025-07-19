/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Screens/Setting/base_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/egg_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../l10n/l10n.dart';

const countThreholdLevel1 = 3;
const countThreholdLevel2 = 6;
const countThreholdLevel3 = 12;
const countThreholdLevel4 = 18;
const countThreholdLevel5 = 24;

class AboutSettingScreen extends BaseSettingScreen {
  const AboutSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/about";

  @override
  State<AboutSettingScreen> createState() => _AboutSettingScreenState();
}

class _AboutSettingScreenState extends BaseDynamicState<AboutSettingScreen>
    with TickerProviderStateMixin {
  int count = 0;
  late String appName = "";
  bool inAppBrowser = ChewieHiveUtil.getBool(ChewieHiveUtil.inappWebviewKey);

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
    appName = ResponsiveUtil.appName;
    versionDetail =
        "${ResponsiveUtil.platformName} ${ResponsiveUtil.version}+${ResponsiveUtil.buildNumber}";
    if (Platform.isWindows) {
      WindowsVersion version = FileUtil.checkWindowsVersion(windowsKeyPath);
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
    return ItemBuilder.buildSettingScreen(
      context: context,
      backgroundColor: Colors.transparent,
      title: appLocalizations.about,
      showBorder: true,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        const SizedBox(height: 30),
        ..._buildLogo(),
        _buildRepo(),
        _buildApp(),
        _buildContact(),
        const SizedBox(height: 30),
      ],
    );
  }

  _buildLogo() {
    return [
      Center(
        child: ClickableGestureDetector(
          onLongPressStart: (details) {
            if (_timer != null) _timer!.cancel();
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
                    AssetFiles.logo,
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
      Container(
        margin: const EdgeInsets.only(top: 8),
        alignment: Alignment.center,
        child: Text(
          appName,
          style: ChewieTheme.titleLarge,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 3),
        alignment: Alignment.center,
        child: Text(
          versionDetail,
          style: ChewieTheme.bodySmall,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 3),
        alignment: Alignment.center,
        child: Text(
          appLocalizations.licenseDetail(appLicense),
          style: ChewieTheme.bodySmall,
        ),
      ),
    ];
  }

  _buildRepo() {
    return SearchableCaptionItem(
      title: appLocalizations.projectRepoAbout,
      searchConfig: widget.searchConfig,
      searchText: widget.searchText,
      children: [
        EntryItem(
          title: appLocalizations.changelog,
          showLeading: true,
          onTap: () {
            RouteUtil.pushDialogRoute(context, const UpdateLogScreen());
          },
          leading: LucideIcons.scrollText,
        ),
        EntryItem(
          title: appLocalizations.bugReport,
          onTap: () {
            UriUtil.launchUrlUri(context, issueUrl);
          },
          showLeading: true,
          leading: LucideIcons.bug,
          trailing: LucideIcons.externalLink,
        ),
        EntryItem(
          title: appLocalizations.githubRepo,
          onTap: () {
            UriUtil.launchUrlUri(context, repoUrl);
          },
          showLeading: true,
          leading: LucideIcons.github,
          trailing: LucideIcons.externalLink,
        ),
      ],
    );
  }

  _buildApp() {
    return SearchableCaptionItem(
      title: appLocalizations.appAbout,
      searchConfig: widget.searchConfig,
      searchText: widget.searchText,
      children: [
        EntryItem(
          title: chewieLocalizations.rate,
          showLeading: true,
          onTap: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              (context) => const StarBottomSheet(),
              responsive: true,
            );
          },
          leading: LucideIcons.medal,
        ),
        EntryItem(
          title: appLocalizations.shareApp,
          showLeading: true,
          onTap: () {
            UriUtil.share(shareAppText);
          },
          leading: LucideIcons.share2,
        ),
        EntryItem(
          title: appLocalizations.officialWebsite,
          onTap: () {
            UriUtil.launchUrlUri(context, officialWebsite);
          },
          showLeading: true,
          leading: LucideIcons.house,
          trailing: LucideIcons.externalLink,
        ),
      ],
    );
  }

  _buildContact() {
    return SearchableCaptionItem(
      title: appLocalizations.contactAbout,
      searchConfig: widget.searchConfig,
      searchText: widget.searchText,
      children: [
        EntryItem(
          title: appLocalizations.contact,
          onTap: () {
            UriUtil.launchEmailUri(
              context,
              feedbackEmail,
              subject: feedbackSubject,
              body: feedbackBody,
            );
          },
          showLeading: true,
          leading: LucideIcons.contact,
          trailing: LucideIcons.atSign,
        ),
        EntryItem(
          title: appLocalizations.telegramGroup,
          onTap: () {
            UriUtil.openExternal(telegramLink);
          },
          showLeading: true,
          leading: LucideIcons.telescope,
          trailing: LucideIcons.externalLink,
        ),
      ],
    );
  }
}
