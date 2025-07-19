import 'package:awesome_chewie/src/Resources/theme_color_data.dart';
import 'package:awesome_chewie/src/Utils/General/color_util.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Resources/colors.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/styles.dart';

class ChewieTheme {
  ChewieTheme._();

  static bool get isDarkMode =>
      Theme.of(chewieProvider.rootContext).brightness == Brightness.dark;

  static ThemeData getTheme({required bool isDarkMode}) {
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: isDarkMode
          ? ChewieColors.defaultPrimaryColorDark
          : ChewieColors.defaultPrimaryColor,
      hintColor: isDarkMode
          ? ChewieColors.defaultPrimaryColorDark
          : ChewieColors.defaultPrimaryColor,
      indicatorColor: isDarkMode
          ? ChewieColors.defaultPrimaryColorDark
          : ChewieColors.defaultPrimaryColor,
      scaffoldBackgroundColor:
          isDarkMode ? ChewieColors.backgroundDark : ChewieColors.background,
      canvasColor: isDarkMode
          ? ChewieColors.materialBackgroundDark
          : ChewieColors.materialBackground,
      dividerColor: isDarkMode
          ? ChewieColors.dividerColorDark
          : ChewieColors.dividerColor,
      shadowColor:
          isDarkMode ? ChewieColors.shadowColorDark : ChewieColors.shadowColor,
      splashColor:
          isDarkMode ? ChewieColors.splashColorDark : ChewieColors.splashColor,
      highlightColor: isDarkMode
          ? ChewieColors.highlightColorDark
          : ChewieColors.highlightColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? ChewieColors.materialBackgroundDark
                : ChewieColors.materialBackground;
          } else {
            return isDarkMode
                ? ChewieColors.textGrayColorDark
                : ChewieColors.textGrayColor;
          }
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? ChewieColors.defaultPrimaryColorDark
                : ChewieColors.defaultPrimaryColor;
          } else {
            return null;
          }
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? ChewieColors.defaultPrimaryColorDark
                : ChewieColors.defaultPrimaryColor;
          } else {
            return isDarkMode
                ? ChewieColors.materialBackgroundDark
                : ChewieColors.materialBackground;
          }
        }),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: isDarkMode ? ChewieColors.iconColorDark : ChewieColors.iconColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: ChewieColors.defaultPrimaryColor.withAlpha(70),
        selectionHandleColor: ChewieColors.defaultPrimaryColor,
      ),
      textTheme: TextTheme(
        labelSmall:
            isDarkMode ? ChewieStyles.labelSmallDark : ChewieStyles.labelSmall,
        titleSmall:
            isDarkMode ? ChewieStyles.captionDark : ChewieStyles.caption,
        titleMedium: isDarkMode ? ChewieStyles.titleDark : ChewieStyles.title,
        bodySmall:
            isDarkMode ? ChewieStyles.bodySmallDark : ChewieStyles.bodySmall,
        bodyMedium:
            isDarkMode ? ChewieStyles.bodyMediumDark : ChewieStyles.bodyMedium,
        titleLarge:
            isDarkMode ? ChewieStyles.titleLargeDark : ChewieStyles.titleLarge,
        bodyLarge: isDarkMode ? ChewieStyles.textDark : ChewieStyles.text,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0.0,
        backgroundColor: isDarkMode
            ? ChewieColors.appBarBackgroundDark
            : ChewieColors.appBarBackground,
      ),
    );
  }

  static ScrollbarThemeData get scrollbarTheme =>
      Theme.of(chewieProvider.rootContext).scrollbarTheme;

  static TextTheme get textTheme =>
      Theme.of(chewieProvider.rootContext).textTheme;

  static TextStyle get titleSmall => textTheme.titleSmall!;

  static TextStyle get titleMedium => textTheme.titleMedium!;

  static TextStyle get titleLarge => textTheme.titleLarge!;

  static TextStyle get labelSmall => textTheme.labelSmall!;

  static TextStyle get labelMedium => textTheme.labelMedium!;

  static TextStyle get labelLarge => textTheme.labelLarge!;

  static TextStyle get bodySmall => textTheme.bodySmall!;

  static TextStyle get bodyMedium => textTheme.bodyMedium!;

  static TextStyle get bodyLarge => textTheme.bodyLarge!;

  static List<BoxShadow> get defaultBoxShadow {
    return [
      BoxShadow(
        color: Theme.of(chewieProvider.rootContext).shadowColor,
        offset: const Offset(0, 4),
        blurRadius: 10,
        spreadRadius: 1,
      ).scale(2),
    ];
  }

  static BoxDecoration get defaultDecoration {
    return BoxDecoration(
      color: ChewieTheme.canvasColor,
      border: ChewieTheme.border,
      boxShadow: ChewieTheme.defaultBoxShadow,
      borderRadius: ChewieDimens.defaultBorderRadius,
    );
  }

  static BoxDecoration getDefaultDecoration([
    double radius = 8,
    double borderWidth = 1,
  ]) {
    return BoxDecoration(
      color: ChewieTheme.canvasColor,
      border: Border.all(color: ChewieTheme.borderColor, width: borderWidth),
      boxShadow: ChewieTheme.defaultBoxShadow,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BorderSide dividerSideWithWidth(double width) =>
      BorderSide(color: ChewieTheme.dividerColor, width: width);

  static BorderSide borderSideWithWidth(double width) =>
      BorderSide(color: ChewieTheme.borderColor, width: width);

  static BorderSide get borderSide => borderSideWithWidth(0.8);

  static BorderSide get dividerSide => dividerSideWithWidth(0.5);

  static Border borderWithWidth(double width) =>
      Border.fromBorderSide(borderSideWithWidth(width));

  static Border dividerWithWidth(double width) =>
      Border.fromBorderSide(dividerSideWithWidth(width));

  static Border get border => borderWithWidth(0.8);

  static Border get divider => dividerWithWidth(1);

  static Border get topBorder => Border(top: borderSide);

  static Border get bottomBorder => Border(bottom: borderSide);

  static Border get topDivider => Border(top: dividerSide);

  static Border get bottomDivider => Border(bottom: dividerSide);

  static Border bottomDividerWithWidth(double? width) => width != null
      ? Border(bottom: dividerSideWithWidth(width))
      : bottomDivider;

  static Border bottomBorderWithWidth(double width) =>
      Border(bottom: borderSideWithWidth(width));

  static Border get rightBorder => Border(right: borderSide);

  static Border get rightDivider => Border(right: dividerSide);

  static getBackground(BuildContext context) {
    return ChewieUtils.currentBrightness(context) == Brightness.light
        ? canvasColor
        : scaffoldBackgroundColor;
  }

  static Color getForeground(BuildContext context) {
    return ChewieUtils.currentBrightness(context) == Brightness.light
        ? scaffoldBackgroundColor
        : canvasColor;
  }

  static Color get background {
    return ChewieUtils.currentBrightness(chewieProvider.rootContext) ==
            Brightness.light
        ? scaffoldBackgroundColor
        : scaffoldBackgroundColor;
  }

  static Color get itemBackground {
    if (ResponsiveUtil.isLandscapeLayout()) {
      return canvasColor;
    }
    return ChewieUtils.currentBrightness(chewieProvider.rootContext) ==
            Brightness.light
        ? canvasColor
        : scaffoldBackgroundColor;
  }

  static Color get appBarBackgroundColor =>
      Theme.of(chewieProvider.rootContext).appBarTheme.backgroundColor!;

  static Color get primaryColor =>
      Theme.of(chewieProvider.rootContext).primaryColor;

  static Color get primaryButtonColor =>
      ColorUtil.getContrastColor(primaryColor);

  static Color get primaryColor120 =>
      Theme.of(chewieProvider.rootContext).primaryColor.withAlpha(120);

  static Color get primaryColor60 =>
      Theme.of(chewieProvider.rootContext).primaryColor.withAlpha(60);

  static Color get primaryColor40 =>
      Theme.of(chewieProvider.rootContext).primaryColor.withAlpha(40);

  static Color get primaryColor40WithoutAlpha =>
      ColorUtil.convertAlphaToOpaque(primaryColor40);

  static Color get canvasColor =>
      Theme.of(chewieProvider.rootContext).canvasColor;

  static Color get shadowColor =>
      Theme.of(chewieProvider.rootContext).shadowColor;

  static Color get cardColor => Theme.of(chewieProvider.rootContext).cardColor;

  static Color get scaffoldBackgroundColor =>
      Theme.of(chewieProvider.rootContext).scaffoldBackgroundColor;

  static Color get dividerColor =>
      Theme.of(chewieProvider.rootContext).dividerColor;

  static Color get splashColor =>
      Theme.of(chewieProvider.rootContext).splashColor;

  static Color get highlightColor =>
      Theme.of(chewieProvider.rootContext).highlightColor;

  static Color get hoverColor =>
      Theme.of(chewieProvider.rootContext).hoverColor;

  static ChewieThemeColorData get themeColorData =>
      ColorUtil.isDark(chewieProvider.rootContext)
          ? chewieProvider.darkTheme
          : chewieProvider.lightTheme;

  static Color get borderColor => themeColorData.borderColor;

  static Color get textLightGreyColor => themeColorData.textLightGreyColor;

  static Color get textDarkGreyColor => themeColorData.textDarkGreyColor;

  static Color get successColor => themeColorData.successColor;

  static Color get warningColor => themeColorData.warningColor;

  static Color get errorColor => themeColorData.errorColor;

  static Color get linkColor =>
      isDarkMode ? ChewieColors.linkColorDark : ChewieColors.linkColor;

  static Color get buttonLightHoverColor =>
      themeColorData.buttonLightHoverColor;

  static Color get barrierColor => ResponsiveUtil.isLandscapeLayout()
      ? ChewieTheme.scaffoldBackgroundColor.withValues(alpha: 0.7)
      : Colors.black54;

  static Color get iconColor =>
      Theme.of(chewieProvider.rootContext).iconTheme.color!;

  static EdgeInsetsGeometry get responsiveListFlowPadding {
    return ResponsiveUtil.isLandscapeLayout()
        ? const EdgeInsets.all(8).add(const EdgeInsets.only(bottom: 16))
        : const EdgeInsets.only(bottom: 16);
  }

  static double get responsiveMainAxisSpacing {
    return ResponsiveUtil.isLandscapeLayout() ? 6 : 0;
  }

  static double get responsiveCrossAxisSpacing {
    return ResponsiveUtil.isLandscapeLayout() ? 6 : 0;
  }

  static double get responsiveMainAxisSpacingForMedia {
    return ResponsiveUtil.isLandscapeLayout() ? 6 : 2;
  }

  static double get responsiveCrossAxisSpacingForMedia {
    return ResponsiveUtil.isLandscapeLayout() ? 6 : 2;
  }
}
