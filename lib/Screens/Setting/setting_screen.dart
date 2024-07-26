import 'package:cloudotp/Screens/Setting/apperance_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/general_setting_screen.dart';
import 'package:flutter/material.dart';

import '../../Utils/route_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import 'about_setting_screen.dart';
import 'experiment_setting_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  static const String routeName = "/setting";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.setting, context: context, transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.basicSetting),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.generalSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const GeneralSettingScreen());
                },
                leading: Icons.settings_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.apprearanceSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const AppearanceSettingScreen());
                },
                leading: Icons.color_lens_outlined,
              ),
              // ItemBuilder.buildEntryItem(
              //   context: context,
              //   title: S.current.operationSetting,
              //   showLeading: true,
              //   onTap: () {
              //     RouteUtil.pushCupertinoRoute(
              //         context, const OperationSettingScreen());
              //   },
              //   leading: Icons.touch_app_outlined,
              // ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.experimentSetting,
                showLeading: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const ExperimentSettingScreen());
                },
                leading: Icons.flag_outlined,
              ),
              const SizedBox(height: 10),
              _buildAbout(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _buildAbout() {
    return ItemBuilder.buildEntryItem(
      context: context,
      title: S.current.about,
      bottomRadius: true,
      topRadius: true,
      showLeading: true,
      padding: 15,
      onTap: () {
        RouteUtil.pushCupertinoRoute(context, const AboutSettingScreen());
      },
      leading: Icons.info_outline_rounded,
    );
  }
}
