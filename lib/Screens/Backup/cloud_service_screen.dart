import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/onedrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/webdav_service_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../generated/l10n.dart';

class CloudServiceScreen extends StatefulWidget {
  const CloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/cloud";

  @override
  State<CloudServiceScreen> createState() => _CloudServiceScreenState();
}

class _CloudServiceScreenState extends State<CloudServiceScreen>
    with TickerProviderStateMixin {
  final GroupButtonController _typeController = GroupButtonController();
  CloudServiceType _currentType = CloudServiceType.Webdav;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    _typeController.selectIndex(_currentType.index);
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Icons.close_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.cloudBackupServiceSetting,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        center: !ResponsiveUtil.isLandscape(),
        actions: [
          ItemBuilder.buildBlankIconButton(context),
          const SizedBox(width: 5),
        ],
      ),
      body: EasyRefresh(
        child: _buildBody(),
      ),
    );
  }

  _buildBody() {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      children: [
        Column(
          children: [
            // Container(
            //   constraints: const BoxConstraints(maxWidth: 82),
            //   alignment: Alignment.center,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(16),
            //     border:
            //         Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5),
            //   ),
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(16),
            //     child: Image.asset(
            //       'assets/logo.png',
            //       height: 80,
            //       width: 80,
            //       fit: BoxFit.contain,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 20),
            _typeInfo(),
            const SizedBox(height: 10),
            SizedBox(
              height: 500,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                children: const [
                  WebDavServiceScreen(),
                  OneDriveServiceScreen(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _typeInfo() {
    return ItemBuilder.buildContainerItem(
      context: context,
      topRadius: true,
      bottomRadius: true,
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          ItemBuilder.buildGroupTile(
            context: context,
            title: S.current.cloudType,
            controller: _typeController,
            constraintWidth: false,
            buttons: CloudServiceType.toStrings(),
            onSelected: (value, index, isSelected) {
              setState(() {
                _currentType = index.toCloudServiceType;
              });
              pageController.jumpToPage(index);
            },
          ),
        ],
      ),
    );
  }
}
