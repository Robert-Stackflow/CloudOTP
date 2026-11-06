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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_appearance_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_operation_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_safe_screen.dart';
import 'package:cloudotp/Screens/Token/category_screen.dart';
import 'package:cloudotp/Screens/feature_showcase_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/l10n.dart';
import '../../Screens/Setting/laboratory_screen.dart';

class MoreBottomSheet extends StatefulWidget {
  const MoreBottomSheet({
    super.key,
    this.showSelect = false,
    this.onSelect,
  });

  final bool showSelect;
  final VoidCallback? onSelect;

  @override
  State<MoreBottomSheet> createState() => _MoreBottomSheetState();
}

class _MoreBottomSheetState extends BaseDynamicState<MoreBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: ChewieDimens.defaultRadius,
              bottom: ResponsiveUtil.isWideDevice()
                  ? ChewieDimens.defaultRadius
                  : Radius.zero,
            ),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.responsiveBorder,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildActionBoxes(),
              _buildSettingsGroup(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(LucideIcons.ellipsisVertical,
                color: ChewieTheme.primaryColor, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            appLocalizations.more,
            style:
                ChewieTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBoxes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        children: [
          if (widget.showSelect)
            Expanded(
              child: _buildActionBox(
                icon: LucideIcons.listChecks,
                title: appLocalizations.select,
                onTap: () {
                  Navigator.pop(context);
                  widget.onSelect?.call();
                },
              ),
            ),
          if (widget.showSelect) const SizedBox(width: 8),
          Expanded(
            child: _buildActionBox(
              icon: LucideIcons.shapes,
              title: appLocalizations.category,
              onTap: () {
                Navigator.pop(context);
                RouteUtil.pushCupertinoRoute(context, const CategoryScreen());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ChewieTheme.canvasColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ChewieTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: ChewieTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChewieTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CaptionItem(
        title: appLocalizations.setting,
        initiallyExpanded: true,
        children: [
          EntryItem(
            title: appLocalizations.generalSetting,
            showLeading: true,
            leading: LucideIcons.settings2,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(
                  context, const GeneralSettingScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.appearanceSetting,
            showLeading: true,
            leading: LucideIcons.paintbrushVertical,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(
                  context, const AppearanceSettingScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.operationSetting,
            showLeading: true,
            leading: LucideIcons.pointer,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(
                  context, const OperationSettingScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.backupSetting,
            showLeading: true,
            leading: LucideIcons.cloudUpload,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(
                  context, const BackupSettingScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.safeSetting,
            showLeading: true,
            leading: LucideIcons.shieldCheck,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(context, const SafeSettingScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.about,
            showLeading: true,
            leading: LucideIcons.info,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(context, const AboutSettingScreen());
            },
          ),
          if (ResponsiveUtil.isIOS()) EntryItem(
            title: laboratoryTitle(context), showLeading: true, leading: LucideIcons.flaskConical,
            onTap: () {
              Navigator.pop(context);
              RouteUtil.pushCupertinoRoute(context, const LaboratoryScreen());
            },
          ),
          EntryItem(
            title: appLocalizations.featureShowcase,
            showLeading: true,
            leading: LucideIcons.telescope,
            onTap: () {
              Navigator.pop(context);
              if (ResponsiveUtil.isLandscapeLayout()) {
                FeatureShowcaseScreen.showAsDialog(context);
              } else {
                RouteUtil.pushCupertinoRoute(
                    context, const FeatureShowcaseScreen());
              }
            },
          ),
          if (kDebugMode)
            EntryItem(
              title: "Reset Welcome",
              showLeading: true,
              leading: LucideIcons.rotateCcw,
              onTap: () {
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.haveShownWelcome4Key, false);
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.haveShownCoachMarkKey, false);
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.haveShownDesktopCoachMarkKey, false);
                Navigator.pop(context);
                IToast.showTop("Welcome screen reset");
              },
            ),
        ],
      ),
    );
  }
}
