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
import 'package:cloudotp/Screens/Setting/setting_appearance_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_operation_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_safe_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';

class MobileSettingNavigationScreen extends StatefulWidget {
  const MobileSettingNavigationScreen({super.key});

  static const String routeName = "/setting/navigation";

  @override
  State<MobileSettingNavigationScreen> createState() =>
      _MobileSettingNavigationScreenState();
}

class _MobileSettingNavigationScreenState
    extends BaseDynamicState<MobileSettingNavigationScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveAppBar(
          title: appLocalizations.setting,
          showBack: true,
          showBorder: true,
          actions: const [
            BlankIconButton(),
            SizedBox(width: 5),
          ],
        ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              EntryItem(
                title: appLocalizations.generalSetting,
                leading: LucideIcons.settings2,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                    context,
                    GeneralSettingScreen(key: generalSettingScreenKey),
                  );
                },
              ),
              EntryItem(
                title: appLocalizations.appearanceSetting,
                leading: LucideIcons.paintbrushVertical,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const AppearanceSettingScreen());
                },
              ),
              EntryItem(
                title: appLocalizations.operationSetting,
                leading: LucideIcons.pointer,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const OperationSettingScreen());
                },
              ),
              EntryItem(
                title: appLocalizations.backupSetting,
                leading: LucideIcons.cloudUpload,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const BackupSettingScreen());
                },
              ),
              EntryItem(
                title: appLocalizations.safeSetting,
                leading: LucideIcons.shieldCheck,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const SafeSettingScreen());
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
