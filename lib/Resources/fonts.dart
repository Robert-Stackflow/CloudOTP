import "dart:io";

import "package:cloudotp/Utils/file_util.dart";
import "package:cloudotp/Utils/ilogger.dart";
import "package:cloudotp/Utils/responsive_util.dart";
import "package:flutter/cupertino.dart";
import "package:path/path.dart";

import "../Utils/app_provider.dart";
import "../Utils/font_util.dart";
import "../Utils/hive_util.dart";
import "../Utils/itoast.dart";
import "../Utils/utils.dart";
import "../Widgets/Dialog/progress_dialog.dart";
import "../generated/l10n.dart";

class CustomFont {
  static const CustomFont Default =
      CustomFont(fontName: "跟随系统", fontFamily: "", fontUrl: "");
  static const CustomFont LxgwWenKai = CustomFont(
      fontName: "霞鹜文楷",
      fontFamily: "LxgwWenKai",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/LXGWWenKai-Regular.ttf");
  static const CustomFont LxgwWenKaiGB = CustomFont(
      fontName: "霞鹜文楷-GB",
      fontFamily: "LxgwWenKaiGB",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/LXGWWenKaiGB-Regular.ttf");
  static const CustomFont LxgwWenKaiLite = CustomFont(
      fontName: "霞鹜文楷-Lite",
      fontFamily: "LxgwWenKaiLite",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/LXGWWenKaiLite-Regular.ttf");
  static const CustomFont LxgwWenKaiScreen = CustomFont(
      fontName: "霞鹜文楷-Screen",
      fontFamily: "LxgwWenKaiScreen",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/LXGWWenKaiGB-Screen.ttf");
  static const CustomFont SmileySans = CustomFont(
      fontName: "得意黑",
      fontFamily: "SmileySansOblique",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/SmileySans-Oblique.ttf");
  static const CustomFont HarmonyOSSans = CustomFont(
      fontName: "HarmonyOS Sans",
      fontFamily: "HarmonyOSSansSC",
      fontUrl:
          "https://pkgs.cloudchewie.com/fonts/HarmonyOSSansSC-Regular.ttf");
  static const CustomFont MiSans = CustomFont(
      fontName: "MiSans",
      fontFamily: "MiSans",
      fontUrl: "https://pkgs.cloudchewie.com/fonts/MiSans-Regular.ttf");
  static const List<CustomFont> defaultFonts = [
    Default,
    LxgwWenKaiGB,
    LxgwWenKaiScreen,
    MiSans,
    HarmonyOSSans,
    SmileySans,
  ];

  final String fontName;
  final String fontFamily;
  final String fontUrl;

  const CustomFont({
    required this.fontName,
    required this.fontFamily,
    required this.fontUrl,
  });

  factory CustomFont.fromJson(Map<String, dynamic> json) {
    return CustomFont(
      fontName: json["fontName"],
      fontFamily: json["fontFamily"],
      fontUrl: json["fontUrl"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fontName": fontName,
      "fontFamily": fontFamily,
      "fontUrl": fontUrl,
    };
  }

  String get intlFontName {
    switch (this) {
      case Default:
        return S.current.followSystem;
      case LxgwWenKai:
        return S.current.lxgw;
      case LxgwWenKaiGB:
        return S.current.lxgwGB;
      case LxgwWenKaiLite:
        return S.current.lxgwLite;
      case LxgwWenKaiScreen:
        return S.current.lxgwScreen;
      case MiSans:
        return S.current.miSans;
      case SmileySans:
        return S.current.smileySans;
      case HarmonyOSSans:
        return S.current.harmonyOSSans;
      default:
        return fontName;
    }
  }

  @override
  int get hashCode => {
        fontName.hashCode,
        fontFamily.hashCode,
        fontUrl.hashCode,
      }.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is CustomFont) {
      return other.fontFamily == fontFamily;
    }
    return false;
  }

  static List<CustomFont> getAllFonts() {
    return List.from(defaultFonts)..addAll(HiveUtil.getCustomFonts());
  }

  static dynamic getCurrentFont() {
    dynamic fontFamily = HiveUtil.get(HiveUtil.fontFamilyKey, defaultValue: 0);
    List<CustomFont> allFonts = getAllFonts();
    if (fontFamily is int) {
      int index = fontFamily;
      if (index < allFonts.length) {
        return allFonts[Utils.patchEnum(index, allFonts.length)];
      }
      return Default;
    } else {
      return allFonts.firstWhere(
        (element) => element.fontFamily == fontFamily,
        orElse: () => Default,
      );
    }
  }

  static Future<CustomFont?> copyFont({
    required String filePath,
  }) async {
    try {
      File file = File(filePath);
      String fileName = FileUtil.getFileNameWithExtension(filePath);
      String newPath = join(await FileUtil.getFontDir(), fileName);
      String fontName = FileUtil.getFileName(fileName);
      String fontFamily = fontName;
      List<CustomFont> allFonts = getAllFonts();
      if (allFonts.where((e) => e.fontFamily == fontFamily).isNotEmpty) {
        fontFamily = "$fontName-${DateTime.now().millisecondsSinceEpoch}";
      }
      await file.copy(newPath);
      FontUtil.file(filepath: newPath, fontFamily: fontFamily).load();
      return CustomFont(
          fontName: fontName, fontFamily: fontFamily, fontUrl: fileName);
    } catch (e) {
      ILogger.error("Failed to copy font file", e);
      return null;
    }
  }

  static Future<void> deleteFont(CustomFont font) async {
    if (defaultFonts.contains(font)) return;
    File file = File(join(await FileUtil.getFontDir(), font.fontUrl));
    if (file.existsSync()) await file.delete();
  }

  static Future<bool> isFontFileExist(CustomFont font) async {
    String fileName = font.fontUrl;
    fileName = FileUtil.getFileNameWithExtension(fileName);
    File file = File(join(await FileUtil.getFontDir(), fileName));
    return file.existsSync();
  }

  static downloadFont({
    BuildContext? context,
    bool showToast = true,
    Function(bool)? onFinished,
    Function(double)? onReceiveProgress,
    CustomFont? customFont,
  }) async {
    customFont ??= getCurrentFont();
    if (customFont != Default) {
      await FontUtil.url(
        fontFamily: customFont!.fontFamily,
        url: customFont.fontUrl,
      ).load(onReceiveProgress: onReceiveProgress).then((value) {
        onFinished?.call(value);
        if (showToast && context != null) {
          if (value == true) {
            IToast.showTop(S.current.fontFamlyLoadSuccess);
          } else {
            IToast.showTop(S.current.fontFamlyLoadFailed);
          }
        }
      });
    } else {
      onFinished?.call(true);
      return Future(() => true);
    }
  }

  static void loadFont(
    BuildContext context,
    CustomFont item, {
    bool autoRestartApp = false,
  }) async {
    var dialog = showProgressDialog(msg: S.current.alreadyDownload);
    await HiveUtil.put(HiveUtil.fontFamilyKey, item.fontFamily);
    await downloadFont(
      context: context,
      showToast: false,
      onFinished: (value) {
        dialog.dismiss();
        appProvider.darkTheme = appProvider.darkTheme;
        appProvider.lightTheme = appProvider.lightTheme;
        if (autoRestartApp) {
          ResponsiveUtil.restartApp(context);
        }
      },
      onReceiveProgress: (progress) {
        dialog.updateProgress(progress: progress);
      },
    );
  }
}
