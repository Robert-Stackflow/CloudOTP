import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/dropbox_service_screen.dart';
import 'package:cloudotp/Screens/Backup/onedrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/s3_service_screen.dart';
import 'package:cloudotp/Screens/Backup/webdav_service_screen.dart';
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
          Navigator.pop(context);
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeInfo(),
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              children: const [
                OneDriveServiceScreen(),
                DropboxServiceScreen(),
                WebDavServiceScreen(),
                S3CloudServiceScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _typeInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ItemBuilder.buildContainerItem(
        context: context,
        topRadius: true,
        bottomRadius: true,
        child: Column(
          children: [
            ItemBuilder.buildGroupTile(
              context: context,
              controller: _typeController,
              constraintWidth: false,
              buttons: CloudServiceType.toEnableStrings(),
              onSelected: (value, index, isSelected) {
                setState(() {
                  _currentType = index.toCloudServiceType;
                });
                pageController.jumpToPage(index);
              },
              title: '',
            ),
          ],
        ),
      ),
    );
  }
}
