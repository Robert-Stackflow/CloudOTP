import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_operation_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_privacy_screen.dart';
import 'package:flutter/material.dart';

import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class SettingNavigationScreen extends StatefulWidget {
  const SettingNavigationScreen({super.key});

  static const String routeName = "/setting/navigation";

  @override
  State<SettingNavigationScreen> createState() =>
      _SettingNavigationScreenState();
}

class _SettingNavigationScreenState extends State<SettingNavigationScreen>
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
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.setting,
                context: context,
                transparent: true,
              )
            : ItemBuilder.buildAppBar(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  S.current.setting,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
                center: true,
                actions: [
                  ItemBuilder.buildBlankIconButton(context),
                  const SizedBox(width: 5),
                ],
              ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.generalSetting,
                leading: Icons.color_lens_outlined,
                showLeading: true,
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const GeneralSettingScreen());
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.operationSetting,
                leading: Icons.handyman_outlined,
                showLeading: true,
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const OperationSettingScreen());
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.backupSetting,
                leading: Icons.backup_outlined,
                showLeading: true,
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const BackupSettingScreen());
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.safeSetting,
                leading: Icons.privacy_tip_outlined,
                showLeading: true,
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const PrivacySettingScreen());
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
