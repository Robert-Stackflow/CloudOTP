import 'package:flutter/material.dart';
import 'package:cloudotp/Models/github_response.dart';
import 'package:cloudotp/Utils/cache_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/locale_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => _GeneralSettingScreenState();
}

class _GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  String _cacheSize = "";
  List<Tuple2<String, Locale?>> _supportedLocaleTuples = [];
  bool inAppBrowser = HiveUtil.getBool(HiveUtil.inappWebviewKey);
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = HiveUtil.getBool(HiveUtil.autoCheckUpdateKey);
  bool enableCloseToTray = HiveUtil.getBool(HiveUtil.enableCloseToTrayKey);
  bool recordWindowState = HiveUtil.getBool(HiveUtil.recordWindowStateKey);
  bool enableCloseNotice = HiveUtil.getBool(HiveUtil.enableCloseNoticeKey);

  @override
  void initState() {
    super.initState();
    filterLocale();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void getCacheSize() {
    CacheUtil.loadCache().then((value) {
      setState(() {
        _cacheSize = value;
      });
    });
  }

  void filterLocale() {
    _supportedLocaleTuples = [];
    List<Locale> locales = S.delegate.supportedLocales;
    _supportedLocaleTuples.add(Tuple2(S.current.followSystem, null));
    for (Locale locale in locales) {
      dynamic tuple = LocaleUtil.getTuple(locale);
      if (tuple != null) {
        _supportedLocaleTuples.add(tuple);
      }
    }
  }

  Future<void> fetchReleases(bool showTip) async {
    setState(() {});
    Utils.getReleases(
      context: context,
      showLoading: showTip,
      showUpdateDialog: showTip,
      showNoUpdateToast: showTip,
      onGetCurrentVersion: (currentVersion) {
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        setState(() {
          this.latestVersion = latestVersion;
          this.latestReleaseItem = latestReleaseItem;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.generalSetting,
            context: context,
            transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              Selector<AppProvider, Locale?>(
                selector: (context, globalProvider) => globalProvider.locale,
                builder: (context, locale, child) => ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.language,
                  tip: LocaleUtil.getLabel(locale)!,
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    filterLocale();
                    BottomSheetBuilder.showListBottomSheet(
                      context,
                      (context) => TileList.fromOptions(
                        _supportedLocaleTuples,
                        (item2) {
                          appProvider.locale = item2;
                          Navigator.pop(context);
                        },
                        selected: locale,
                        context: context,
                        title: S.current.chooseLanguage,
                        onCloseTap: () => Navigator.pop(context),
                      ),
                    );
                  },
                ),
              ),
              if (ResponsiveUtil.isMobile()) const SizedBox(height: 10),
              if (ResponsiveUtil.isMobile())
                ItemBuilder.buildRadioItem(
                  value: inAppBrowser,
                  context: context,
                  title: "内置浏览器",
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    setState(() {
                      inAppBrowser = !inAppBrowser;
                      HiveUtil.put(HiveUtil.inappWebviewKey, inAppBrowser);
                    });
                  },
                ),
              if (ResponsiveUtil.isDesktop()) ..._desktopSetting(),
              const SizedBox(height: 10),
              ItemBuilder.buildRadioItem(
                value: autoCheckUpdate,
                topRadius: true,
                context: context,
                title: "自动检查更新",
                onTap: () {
                  setState(() {
                    autoCheckUpdate = !autoCheckUpdate;
                    HiveUtil.put(HiveUtil.autoCheckUpdateKey, autoCheckUpdate);
                  });
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.checkUpdates,
                bottomRadius: true,
                description: Utils.compareVersion(latestVersion,currentVersion) > 0
                    ? "新版本：$latestVersion"
                    : S.current.checkUpdatesAlreadyLatest,
                descriptionColor: Utils.compareVersion(latestVersion,currentVersion) > 0
                    ? Colors.redAccent
                    : null,
                tip: currentVersion,
                onTap: () {
                  fetchReleases(true);
                },
              ),
              const SizedBox(height: 10),
              if (ResponsiveUtil.isMobile())
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.clearCache,
                  topRadius: true,
                  bottomRadius: true,
                  tip: _cacheSize,
                  onTap: () {
                    CustomLoadingDialog.showLoading(title: "清除缓存中...");
                    getTemporaryDirectory().then((tempDir) {
                      CacheUtil.delDir(tempDir).then((value) {
                        CacheUtil.loadCache().then((value) {
                          setState(() {
                            _cacheSize = value;
                            CustomLoadingDialog.dismissLoading();
                            IToast.showTop(S.current.clearCacheSuccess);
                          });
                        });
                      });
                    });
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  _desktopSetting() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "关闭主界面时",
        tip: enableCloseToTray ? "最小化到系统托盘" : "退出CloudOTP",
        topRadius: true,
        onTap: () {
          List<Tuple2<String, dynamic>> options = [
            const Tuple2("最小化到系统托盘", 0),
            const Tuple2("退出CloudOTP", 1),
          ];
          BottomSheetBuilder.showListBottomSheet(
            context,
                (sheetContext) => TileList.fromOptions(
              options,
                  (idx) {
                Navigator.pop(sheetContext);
                if (idx == 0) {
                  setState(() {
                    enableCloseToTray = true;
                    HiveUtil.put(
                        HiveUtil.enableCloseToTrayKey, enableCloseToTray);
                  });
                } else if (idx == 1) {
                  setState(() {
                    enableCloseToTray = false;
                    HiveUtil.put(
                        HiveUtil.enableCloseToTrayKey, enableCloseToTray);
                  });
                }
              },
              selected: enableCloseToTray ? 0 : 1,
              title: "关闭主界面时",
              context: context,
              onCloseTap: () => Navigator.pop(sheetContext),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          );
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: "记忆窗口位置和大小",
        value: recordWindowState,
        description: "关闭后，每次打开CloudOTP都会居中显示且具有默认窗口大小",
        bottomRadius: true,
        onTap: () async {
          setState(() {
            recordWindowState = !recordWindowState;
            HiveUtil.put(HiveUtil.recordWindowStateKey, recordWindowState);
          });
          HiveUtil.setWindowSize(await windowManager.getSize());
          HiveUtil.setWindowPosition(await windowManager.getPosition());
        },
      ),
    ];
  }
}
