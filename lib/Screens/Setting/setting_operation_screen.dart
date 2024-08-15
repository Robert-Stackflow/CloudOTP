import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_password_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloudotp/Utils/Tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Database/database_manager.dart';
import '../../Database/token_dao.dart';
import '../../Models/github_response.dart';
import '../../Resources/fonts.dart';
import '../../Resources/theme_color_data.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cache_util.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/locale_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';

class OperationSettingScreen extends StatefulWidget {
  const OperationSettingScreen({super.key});

  static const String routeName = "/setting/operation";

  @override
  State<OperationSettingScreen> createState() => _OperationSettingScreenState();
}

class _OperationSettingScreenState extends State<OperationSettingScreen>
    with TickerProviderStateMixin {
  bool clipToCopy = HiveUtil.getBool(HiveUtil.clickToCopyKey);
  bool autoCopyNextCode = HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey);
  bool autoHideCode = HiveUtil.getBool(HiveUtil.autoHideCodeKey);
  bool defaultHideCode = HiveUtil.getBool(HiveUtil.defaultHideCodeKey);
  bool dragToReorder = HiveUtil.getBool(HiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());

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
          title: S.current.operationSetting,
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
              ..._operationSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _operationSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.operationSetting),
      ItemBuilder.buildRadioItem(
        context: context,
        value: clipToCopy,
        title: S.current.clickToCopy,
        description: S.current.clickToCopyTip,
        onTap: () {
          setState(() {
            clipToCopy = !clipToCopy;
            HiveUtil.put(HiveUtil.clickToCopyKey, clipToCopy);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        disabled: !clipToCopy,
        value: autoCopyNextCode,
        title: S.current.autoCopyNextCode,
        description: S.current.autoCopyNextCodeTip,
        onTap: () {
          setState(() {
            autoCopyNextCode = !autoCopyNextCode;
            HiveUtil.put(HiveUtil.autoCopyNextCodeKey, autoCopyNextCode);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoHideCode,
        title: S.current.autoHideCode,
        description: S.current.autoHideCodeTip,
        onTap: () {
          setState(() {
            autoHideCode = !autoHideCode;
            appProvider.autoHideCode = autoHideCode;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: defaultHideCode,
        title: S.current.defaultHideCode,
        description: S.current.defaultHideCodeTip,
        onTap: () {
          setState(() {
            defaultHideCode = !defaultHideCode;
            HiveUtil.put(HiveUtil.defaultHideCodeKey, defaultHideCode);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: dragToReorder,
        title: S.current.dragToReorder,
        description: S.current.dragToReorderTip,
        onTap: () {
          setState(() {
            dragToReorder = !dragToReorder;
            appProvider.dragToReorder = dragToReorder;
            HiveUtil.put(HiveUtil.dragToReorderKey, dragToReorder);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        bottomRadius: true,
        title: S.current.resetCopyTimes,
        description: S.current.resetCopyTimesTip,
        onTap: () async {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.resetCopyTimesTitle,
            message: S.current.resetCopyTimesConfirmMessage,
            onTapConfirm: () async {
              await TokenDao.resetTokenCopyTimes();
              homeScreenState?.resetCopyTimes();
              IToast.showTop(S.current.resetSuccess);
            },
            onTapCancel: () {},
          );
        },
      ),
    ];
  }

}
