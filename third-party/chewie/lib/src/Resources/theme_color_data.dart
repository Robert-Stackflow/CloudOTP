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

import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class ChewieThemeColorData {
  bool isDarkMode;

  String id;

  String name;

  String? description;

  Color primaryColor;

  Color canvasColor;

  Color scaffoldBackgroundColor;

  Color cardColor;

  Color hintColor;

  Color indicatorColor;

  Color hoverColor;

  Color splashColor;

  Color highlightColor;

  Color shadowColor;

  Color iconColor;

  Color appBarBackgroundColor;

  Color appBarSurfaceTintColor;

  Color appBarShadowColor;

  double appBarElevation;

  double appBarScrollUnderElevation;

  Color textColor;

  Color textLightGreyColor;

  Color textDarkGreyColor;

  Color buttonPrimaryColor;

  Color buttonSecondaryColor;

  Color buttonDisabledColor;

  Color buttonHoverColor;

  Color buttonLightHoverColor;

  Color textSelectionColor;

  Color textSelectionHandleColor;

  Color cursorColor;

  Color dividerColor;

  Color borderColor;

  Color scrollBarThumbColor;

  Color scrollBarThumbHoverColor;

  Color scrollBarTrackColor;

  Color scrollBarTrackHoverColor;

  Color successColor;

  Color warningColor;

  Color errorColor;

  String get i18nName {
    switch (id.toLowerCase()) {
      case 'purewhite':
        return chewieLocalizations.themePureWhite;
      case 'softlight':
        return chewieLocalizations.themeSoftLight;
      case 'githublight':
        return chewieLocalizations.themeGitHubLight;
      case 'pureblack':
        return chewieLocalizations.themePureBlack;
      case 'blueiron':
        return chewieLocalizations.themeBlueIron;
      case 'githubdark':
        return chewieLocalizations.themeGitHubDark;
      default:
        return name;
    }
  }

  ChewieThemeColorData({
    this.isDarkMode = false,
    required this.id,
    required this.name,
    this.description,
    required this.cardColor,
    required this.primaryColor,
    required this.scaffoldBackgroundColor,
    required this.appBarBackgroundColor,
    required this.appBarSurfaceTintColor,
    required this.appBarShadowColor,
    this.appBarElevation = 0.0,
    this.appBarScrollUnderElevation = 1.0,
    required this.hoverColor,
    required this.splashColor,
    required this.highlightColor,
    required this.iconColor,
    required this.shadowColor,
    required this.canvasColor,
    required this.dividerColor,
    required this.cursorColor,
    required this.textColor,
    required this.indicatorColor,
    required this.hintColor,
    required this.borderColor,
    required this.textLightGreyColor,
    required this.textDarkGreyColor,
    required this.textSelectionColor,
    required this.textSelectionHandleColor,
    required this.buttonPrimaryColor,
    required this.buttonSecondaryColor,
    required this.buttonHoverColor,
    required this.buttonLightHoverColor,
    required this.buttonDisabledColor,
    required this.scrollBarThumbColor,
    required this.scrollBarThumbHoverColor,
    required this.scrollBarTrackColor,
    required this.scrollBarTrackHoverColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
  });

  static List<ChewieThemeColorData> defaultLightThemes = [
    ChewieThemeColorData(
      id: "PureWhite",
      name: "极简白",
      canvasColor: const Color(0xFFF7F8F9),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFF1F1F1),
      primaryColor: const Color(0xFF11b566),
      cursorColor: const Color(0xFF11b566),
      indicatorColor: const Color(0xFF11b566),
      textSelectionColor: const Color(0xFF11b566).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF11b566),
      hintColor: const Color(0xFF1F1F1F),
      iconColor: const Color(0xFF333333),
      hoverColor: const Color(0x33C8C8C8),
      splashColor: const Color(0x66c8c8c8),
      highlightColor: const Color(0x66bcbcbc),
      shadowColor: const Color(0x12000000),
      dividerColor: const Color(0xFFEAEAEA),
      borderColor: const Color(0xFFE7E5E4),
      appBarShadowColor: const Color(0xFFF6F6F6),
      appBarBackgroundColor: const Color(0xFFF7F8F9),
      appBarSurfaceTintColor: const Color(0xFFF7F8F9),
      textColor: const Color(0xFF333333),
      textLightGreyColor: const Color(0xFFB0B8C0),
      textDarkGreyColor: const Color(0xFF71767B),
      buttonPrimaryColor: const Color(0xFF11b566),
      buttonSecondaryColor: const Color(0xFFF2F2F2),
      buttonHoverColor: const Color(0xFFF2F2F2),
      buttonLightHoverColor: const Color(0xFFECECED),
      buttonDisabledColor: const Color(0xFF96BBFA),
      scrollBarThumbColor: const Color(0xFFC4C4C4),
      scrollBarThumbHoverColor: const Color(0xFFB5B5B5),
      scrollBarTrackColor: const Color(0xFFF0F0F0),
      scrollBarTrackHoverColor: const Color(0xFFE0E0E0),
      successColor: const Color(0xFF4CAF50),
      warningColor: const Color(0xFFFFC107),
      errorColor: const Color(0xFFF44336),
    ),
    ChewieThemeColorData(
      id: "SoftLight",
      name: "柔和光明",
      canvasColor: const Color(0xFFF0F0F0),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      cardColor: const Color(0xFFF2F2F2),
      primaryColor: const Color(0xFF3A3A3A),
      hintColor: const Color(0xFF9E9E9E),
      cursorColor: const Color(0xFF3A3A3A),
      indicatorColor: const Color(0xFF3A3A3A),
      textSelectionColor: const Color(0xFF3A3A3A).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF3A3A3A),
      iconColor: const Color(0xFF6F6F6F),
      hoverColor: const Color(0x33E8E8E8),
      splashColor: const Color(0x66E8E8E8),
      highlightColor: const Color(0x66D1D1D1),
      shadowColor: const Color(0x12000000),
      dividerColor: const Color(0xFFE0E0E0),
      borderColor: const Color(0xFFE0E0E0),
      appBarShadowColor: const Color(0xFFE1E1E1),
      appBarBackgroundColor: const Color(0xFFF0F0F0),
      appBarSurfaceTintColor: const Color(0xFFF0F0F0),
      textColor: const Color(0xFF2D2D2D),
      textLightGreyColor: const Color(0xFF9E9E9E),
      textDarkGreyColor: const Color(0xFF636363),
      buttonPrimaryColor: const Color(0xFF1976D2),
      buttonSecondaryColor: const Color(0xFFE0E0E0),
      buttonHoverColor: const Color(0xFF2196F3),
      buttonLightHoverColor: const Color(0xFF90CAF9),
      buttonDisabledColor: const Color(0xFFB0BEC5),
      scrollBarThumbColor: const Color(0xFFC1C1C1),
      scrollBarThumbHoverColor: const Color(0xFF9E9E9E),
      scrollBarTrackColor: const Color(0xFFF5F5F5),
      scrollBarTrackHoverColor: const Color(0xFFE0E0E0),
      successColor: const Color(0xFF4CAF50),
      warningColor: const Color(0xFFFFC107),
      errorColor: const Color(0xFFF44336),
    ),
    ChewieThemeColorData(
      id: "GitHubLight",
      name: "GitHub 浅色",
      canvasColor: const Color(0xFFF6F8FA),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFEAEDF0),
      hintColor: const Color(0xFF57606A),
      primaryColor: const Color(0xFF1f883d),
      cursorColor: const Color(0xFF1f883d),
      indicatorColor: const Color(0xFF1f883d),
      textSelectionColor: const Color(0xFF1f883d).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF1f883d),
      iconColor: const Color(0xFF59636e),
      hoverColor: const Color(0x66E8E8E8),
      splashColor: const Color(0x88E8E8E8),
      highlightColor: const Color(0x88D1D1D1),
      shadowColor: const Color(0x25292e52),
      dividerColor: const Color(0xFFd1d9e0),
      borderColor: const Color(0xFFd1d9e0),
      appBarShadowColor: const Color(0xFFF6F8FA),
      appBarBackgroundColor: const Color(0xFFF6F8FA),
      appBarSurfaceTintColor: const Color(0xFFF6F8FA),
      textColor: const Color(0xFF1f2328),
      textLightGreyColor: const Color(0xFF59636E),
      textDarkGreyColor: const Color(0xFF59636E),
      buttonPrimaryColor: const Color(0xFF2DA44E),
      buttonSecondaryColor: const Color(0xFFF6F8FA),
      buttonHoverColor: const Color(0xFFEAECEF),
      buttonLightHoverColor: const Color(0xFFD8DEE4),
      buttonDisabledColor: const Color(0xFFC9D1D9),
      scrollBarThumbColor: const Color(0xFFC1C1C1),
      scrollBarThumbHoverColor: const Color(0xFFA8A8A8),
      scrollBarTrackColor: const Color(0xFFF0F0F0),
      scrollBarTrackHoverColor: const Color(0xFFE0E0E0),
      successColor: const Color(0xFF2DA44E),
      warningColor: const Color(0xFFD29922),
      errorColor: const Color(0xFFCF6679),
    ),
  ];

  static List<ChewieThemeColorData> defaultDarkThemes = [
    ChewieThemeColorData(
      id: "PureBlack",
      name: "极简黑",
      canvasColor: const Color(0xFF212121),
      scaffoldBackgroundColor: const Color(0xFF171717),
      cardColor: const Color(0xFF252525),
      primaryColor: const Color(0xFF11b566),
      cursorColor: const Color(0xFF11b566),
      indicatorColor: const Color(0xFF11b566),
      textSelectionColor: const Color(0xFF11b566).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF11b566),
      hintColor: const Color(0xFFE8E8E8),
      textColor: const Color(0xFFE0E0E0),
      textLightGreyColor: const Color(0xFFA0A0A0),
      textDarkGreyColor: const Color(0xFF5C5C5C),
      iconColor: const Color(0xFFCACACA),
      hoverColor: const Color(0x44383838),
      splashColor: const Color(0x12cccccc),
      highlightColor: const Color(0x12cfcfcf),
      dividerColor: const Color(0xFF303030),
      borderColor: const Color(0xFF383838),
      shadowColor: Colors.black.withAlpha(84),
      appBarShadowColor: const Color(0xFF1F1F1F),
      appBarBackgroundColor: const Color(0xFF212121),
      appBarSurfaceTintColor: const Color(0xFF212121),
      buttonPrimaryColor: const Color(0xFF11b566),
      buttonSecondaryColor: const Color(0xFF333333),
      buttonDisabledColor: const Color(0xFF4A4A4A),
      buttonHoverColor: const Color(0xFF333333),
      buttonLightHoverColor: const Color(0xFF2C2C2C),
      scrollBarThumbColor: const Color(0xFF737373),
      scrollBarThumbHoverColor: const Color(0xFF868686),
      scrollBarTrackColor: const Color(0xFF303030),
      scrollBarTrackHoverColor: const Color(0xFF404040),
      successColor: const Color(0xFF81C784),
      warningColor: const Color(0xFFFFA726),
      errorColor: const Color(0xFFCF6679),
    ),
    ChewieThemeColorData(
      id: "BlueIron",
      name: "蓝铁",
      scaffoldBackgroundColor: const Color(0xFF1D2733),
      canvasColor: const Color(0xFF242E39),
      cardColor: const Color(0xFF2E3A45),
      primaryColor: const Color(0xFF14C2BB),
      hintColor: const Color(0xFF14C2BB),
      cursorColor: const Color(0xFF14C2BB),
      indicatorColor: const Color(0xFF14C2BB),
      textSelectionColor: const Color(0xFF14C2BB).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF14C2BB),
      textColor: const Color(0xFFB8B8B8),
      textLightGreyColor: const Color(0xFF94A3B8),
      textDarkGreyColor: const Color(0xFF5C677D),
      iconColor: const Color(0xFFB8B8B8),
      hoverColor: const Color(0x22C8C8C8),
      splashColor: const Color(0x22CCCCCC),
      highlightColor: const Color(0x22CFCFCF),
      shadowColor: const Color(0xFF1B2530),
      appBarShadowColor: const Color(0xFF1B2530),
      appBarBackgroundColor: const Color(0xFF242E39),
      appBarSurfaceTintColor: const Color(0xFF242E39),
      buttonPrimaryColor: const Color(0xFFF2F2F2),
      buttonSecondaryColor: const Color(0xFF333333),
      buttonHoverColor: const Color(0xFF333333),
      buttonLightHoverColor: const Color(0xFF2C2C2C),
      buttonDisabledColor: const Color(0xFF4A4A4A),
      dividerColor: const Color(0xFF2D3743),
      borderColor: const Color(0xFF2D3743),
      scrollBarThumbColor: const Color(0xFF5A5A5A),
      scrollBarThumbHoverColor: const Color(0xFF242E39),
      scrollBarTrackColor: const Color(0xFF2D3743),
      scrollBarTrackHoverColor: const Color(0xFF404040),
      successColor: const Color(0xFF81C784),
      warningColor: const Color(0xFFFFA726),
      errorColor: const Color(0xFFCF6679),
    ),
    ChewieThemeColorData(
      id: "GithubDark",
      name: "Github深色",
      canvasColor: const Color(0xFF0d1117),
      scaffoldBackgroundColor: const Color(0xFF010409),
      cardColor: const Color(0xFF1E242A),
      primaryColor: const Color(0xFF1f6feb),
      hintColor: const Color(0xFFE8E8E8),
      cursorColor: const Color(0xFF1f6feb),
      indicatorColor: const Color(0xFF1f6feb),
      textSelectionColor: const Color(0xFF1f6feb).withAlpha(70),
      textSelectionHandleColor: const Color(0xFF1f6feb),
      textColor: const Color(0xFFf0f6fc),
      textLightGreyColor: const Color(0xFFA0A0A0),
      textDarkGreyColor: const Color(0xFF9198a1),
      iconColor: const Color(0xFFCACACA),
      hoverColor: const Color(0x44383838),
      splashColor: const Color(0x12cccccc),
      highlightColor: const Color(0x12cfcfcf),
      dividerColor: const Color(0xFF2f353d),
      borderColor: const Color(0xFF3d444d),
      shadowColor: Colors.black.withAlpha(84),
      appBarShadowColor: const Color(0xFF1F1F1F),
      appBarBackgroundColor: const Color(0xFF0d1117),
      appBarSurfaceTintColor: const Color(0xFF0d1117),
      buttonPrimaryColor: const Color(0xFF1f6feb),
      buttonSecondaryColor: const Color(0xFF333333),
      buttonDisabledColor: const Color(0xFF4A4A4A),
      buttonHoverColor: const Color(0xFF333333),
      buttonLightHoverColor: const Color(0xFF2C2C2C),
      scrollBarThumbColor: const Color(0xFF737373),
      scrollBarThumbHoverColor: const Color(0xFF868686),
      scrollBarTrackColor: const Color(0xFF303030),
      scrollBarTrackHoverColor: const Color(0xFF404040),
      successColor: const Color(0xFF81C784),
      warningColor: const Color(0xFFFFA726),
      errorColor: const Color(0xFFCF6679),
    ),
  ];

  ThemeData toThemeData() {
    TextStyle displayLarge = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 57,
      letterSpacing: -0.25,
      color: textColor,
    );

    TextStyle displayMedium = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 45,
      letterSpacing: 0.0,
      color: textColor,
    );

    TextStyle displaySmall = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 36,
      letterSpacing: 0.0,
      color: textColor,
    );

    TextStyle headlineLarge = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 32,
      letterSpacing: 0.0,
      height: 1.3,
      color: textColor,
    );

    TextStyle headlineMedium = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 28,
      letterSpacing: 0.0,
      height: 1.3,
      color: textColor,
    );

    TextStyle headlineSmall = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 24,
      letterSpacing: 0.0,
      height: 1.3,
      color: textColor,
    );

    TextStyle titleLarge = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: 0.1,
      color: textColor,
    );

    TextStyle titleMedium = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      letterSpacing: 0.1,
      color: textColor,
    );

    TextStyle titleSmall = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      letterSpacing: 0.1,
      height: 1.2,
      color: textColor,
    );

    TextStyle bodyLarge = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      letterSpacing: 0.5,
      color: textColor,
    );

    TextStyle bodyMedium = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      letterSpacing: 0.25,
      color: textColor,
    );

    TextStyle bodySmall = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 12,
      letterSpacing: 0.4,
      color: textDarkGreyColor,
    );

    TextStyle labelLarge = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      letterSpacing: 0.1,
      color: textLightGreyColor,
    );

    TextStyle labelMedium = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      letterSpacing: 0.5,
      color: textLightGreyColor,
    );

    TextStyle labelSmall = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.5,
      color: textLightGreyColor,
    );

    return ThemeData(
      fontFamily: CustomFont.getCurrentFont().fontFamily,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      hintColor: hintColor,
      indicatorColor: indicatorColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: canvasColor,
      dividerColor: dividerColor,
      shadowColor: shadowColor,
      splashColor: splashColor,
      highlightColor: highlightColor,
      hoverColor: hoverColor,
      cardColor: cardColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return canvasColor;
          } else if (states.contains(WidgetState.disabled)) {
            return Colors.grey;
          } else {
            return textLightGreyColor.withAlpha(200);
          }
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return textLightGreyColor.withAlpha(40);
          }
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return canvasColor;
          }
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return canvasColor;
          }
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return canvasColor;
          }
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: primaryColor, width: 2),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: iconColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: textSelectionColor,
        selectionHandleColor: textSelectionHandleColor,
      ),
      textTheme: TextTheme(
        labelSmall: labelSmall,
        labelMedium: labelMedium,
        labelLarge: labelLarge,
        titleSmall: titleSmall,
        titleMedium: titleMedium,
        titleLarge: titleLarge,
        bodySmall: bodySmall,
        bodyMedium: bodyMedium,
        bodyLarge: bodyLarge,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
      ),
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        scrolledUnderElevation: appBarScrollUnderElevation,
        shadowColor: appBarShadowColor,
        backgroundColor: appBarBackgroundColor,
        surfaceTintColor: appBarSurfaceTintColor,
      ),
      tabBarTheme: const TabBarTheme(
        splashFactory: NoSplash.splashFactory,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: buttonPrimaryColor,
        hoverColor: buttonHoverColor,
        disabledColor: buttonDisabledColor,
        textTheme: ButtonTextTheme.primary,
        shape: const RoundedRectangleBorder(
            borderRadius: ChewieDimens.borderRadius8),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return scrollBarThumbHoverColor;
          } else {
            return scrollBarThumbColor;
          }
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return scrollBarTrackHoverColor;
          } else {
            return scrollBarTrackColor;
          }
        }),
        radius: ChewieDimens.radius8,
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return 6.0;
          } else {
            return 4.0;
          }
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: bodySmall,
        errorStyle: TextStyle(color: errorColor),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "isDarkMode": isDarkMode ? 1 : 0,
        "id": id,
        "name": name,
        "description": description,
        "primaryColor": primaryColor.toHex(),
        "canvasColor": canvasColor.toHex(),
        "scaffoldBackgroundColor": scaffoldBackgroundColor.toHex(),
        "cardColor": cardColor.toHex(),
        "hintColor": hintColor.toHex(),
        "indicatorColor": indicatorColor.toHex(),
        "splashColor": splashColor.toHex(),
        "highlightColor": highlightColor.toHex(),
        "shadowColor": shadowColor.toHex(),
        'hoverColor': hoverColor.toHex(),
        "iconColor": iconColor.toHex(),
        "appBarBackgroundColor": appBarBackgroundColor.toHex(),
        "appBarSurfaceTintColor": appBarSurfaceTintColor.toHex(),
        "appBarShadowColor": appBarShadowColor.toHex(),
        "appBarElevation": appBarElevation,
        "appBarScrollUnderElevation": appBarScrollUnderElevation,
        "textColor": textColor.toHex(),
        "textLightGreyColor": textLightGreyColor.toHex(),
        "textDarkGreyColor": textDarkGreyColor.toHex(),
        "buttonPrimaryColor": buttonPrimaryColor.toHex(),
        "buttonSecondaryColor": buttonSecondaryColor.toHex(),
        "buttonDisabledColor": buttonDisabledColor.toHex(),
        "buttonHoverColor": buttonHoverColor.toHex(),
        'buttonLightHoverColor': buttonLightHoverColor.toHex(),
        "textSelectionColor": textSelectionColor.toHex(),
        "textSelectionHandleColor": textSelectionHandleColor.toHex(),
        "cursorColor": cursorColor.toHex(),
        "dividerColor": dividerColor.toHex(),
        "borderColor": borderColor.toHex(),
        "scrollBarThumbColor": scrollBarThumbColor.toHex(),
        "scrollBarThumbHoverColor": scrollBarThumbHoverColor.toHex(),
        "scrollBarTrackColor": scrollBarTrackColor.toHex(),
        "scrollBarTrackHoverColor": scrollBarTrackHoverColor.toHex(),
        'successColor': successColor.toHex(),
        'warningColor': warningColor.toHex(),
        'errorColor': errorColor.toHex(),
      };

  factory ChewieThemeColorData.fromJson(Map<String, dynamic> map) {
    return ChewieThemeColorData(
      id: map['id'] ?? "",
      isDarkMode: map['isDarkMode'] == 1,
      name: map['name'] ?? "",
      description: map['description'] as String?,
      primaryColor: HexColor.fromHex(map['primaryColor'] ?? "#FFFFFFFF"),
      canvasColor: HexColor.fromHex(map['canvasColor'] ?? "#FFFFFFFF"),
      scaffoldBackgroundColor:
          HexColor.fromHex(map['scaffoldBackgroundColor'] ?? "#FFFFFFFF"),
      cardColor: HexColor.fromHex(map['cardColor'] ?? "#FFFFFFFF"),
      hintColor: HexColor.fromHex(map['hintColor'] ?? "#80FFFFFF"),
      indicatorColor: HexColor.fromHex(map['indicatorColor'] ?? "#FFFFFFFF"),
      splashColor: HexColor.fromHex(map['splashColor'] ?? "#29FFFFFF"),
      highlightColor: HexColor.fromHex(map['highlightColor'] ?? "#29FFFFFF"),
      hoverColor: HexColor.fromHex(map['hoverColor'] ?? "#29FFFFFF"),
      shadowColor: HexColor.fromHex(map['shadowColor'] ?? "#40000000"),
      iconColor: HexColor.fromHex(map['iconColor'] ?? "#FFFFFFFF"),
      appBarBackgroundColor:
          HexColor.fromHex(map['appBarBackgroundColor'] ?? "#FF1F1F1F"),
      appBarSurfaceTintColor:
          HexColor.fromHex(map['appBarSurfaceTintColor'] ?? "#FFFFFFFF"),
      appBarShadowColor:
          HexColor.fromHex(map['appBarShadowColor'] ?? "#40000000"),
      appBarElevation: (map['appBarElevation'] as num?)?.toDouble() ?? 0.0,
      appBarScrollUnderElevation:
          (map['appBarScrollUnderElevation'] as num?)?.toDouble() ?? 0.0,
      textColor: HexColor.fromHex(map['textColor'] ?? "#FFFFFFFF"),
      textLightGreyColor:
          HexColor.fromHex(map['textLightGreyColor'] ?? "#FFBDBDBD"),
      textDarkGreyColor:
          HexColor.fromHex(map['textDarkGreyColor'] ?? "#FF757575"),
      buttonPrimaryColor:
          HexColor.fromHex(map['buttonPrimaryColor'] ?? "#FF6200EE"),
      buttonSecondaryColor:
          HexColor.fromHex(map['buttonSecondaryColor'] ?? "#FF03DAC6"),
      buttonDisabledColor:
          HexColor.fromHex(map['buttonDisabledColor'] ?? "#FFBDBDBD"),
      buttonHoverColor:
          HexColor.fromHex(map['buttonHoverColor'] ?? "#296200EE"),
      buttonLightHoverColor:
          HexColor.fromHex(map['buttonLightHoverColor'] ?? "#FF2C2C2C"),
      textSelectionColor:
          HexColor.fromHex(map['textSelectionColor'] ?? "#FFBB86FC"),
      textSelectionHandleColor:
          HexColor.fromHex(map['textSelectionHandleColor'] ?? "#FF3700B3"),
      cursorColor: HexColor.fromHex(map['cursorColor'] ?? "#FFBB86FC"),
      dividerColor: HexColor.fromHex(map['dividerColor'] ?? "#FFBDBDBD"),
      borderColor: HexColor.fromHex(map['borderColor'] ?? "#FF6200EE"),
      scrollBarThumbColor:
          HexColor.fromHex(map['scrollBarThumbColor'] ?? "#FFBDBDBD"),
      scrollBarThumbHoverColor:
          HexColor.fromHex(map['scrollBarThumbHoverColor'] ?? "#FF3700B3"),
      scrollBarTrackColor:
          HexColor.fromHex(map['scrollBarTrackColor'] ?? "#FF6200EE"),
      scrollBarTrackHoverColor:
          HexColor.fromHex(map['scrollBarTrackHoverColor'] ?? "#FF3700B3"),
      successColor: HexColor.fromHex(map['successColor'] ?? "#FF4CAF50"),
      warningColor: HexColor.fromHex(map['warningColor'] ?? "#FFFFC107"),
      errorColor: HexColor.fromHex(map['errorColor'] ?? "#FFF44336"),
    );
  }
}
