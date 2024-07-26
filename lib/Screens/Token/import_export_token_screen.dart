import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../TokenUtils/import_token_util.dart';

class ImportExportTokenScreen extends StatefulWidget {
  const ImportExportTokenScreen({
    super.key,
  });

  static const String routeName = "/token/import";

  @override
  State<ImportExportTokenScreen> createState() =>
      _ImportExportTokenScreenState();
}

class _ImportExportTokenScreenState extends State<ImportExportTokenScreen>
    with TickerProviderStateMixin {
  String appName = "CloudOTP";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) => setState(() {
          appName = info.appName;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        forceShowClose: true,
        leading: Icons.close_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          "导入导出",
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
      body: _buildBody(),
    );
  }

  _buildBody() {
    return EasyRefresh(
      child: ListView(
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtil.isLandscape() ? 20 : 16, vertical: 10),
        children: [
          const SizedBox(height: 10),
          ItemBuilder.buildCaptionItem(context: context, title: "导入"),
          ItemBuilder.buildEntryItem(
            context: context,
            title: "导入URI格式",
            bottomRadius: true,
            description: "导入纯文本格式的OTPAuth URI列表，每行对应一个令牌",
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                dialogTitle: "选择文件",
                type: FileType.any,
                lockParentWindow: true,
              );
              if (result != null) {
                ImportTokenUtil.importUriFile(result.files.single.path!);
              }
            },
          ),
          const SizedBox(height: 10),
          ItemBuilder.buildCaptionItem(context: context, title: "导出"),
          ItemBuilder.buildEntryItem(
            context: context,
            title: "导出加密文件",
            description: "将令牌信息及其分类和图标导出到加密的二进制文件中，仅适用于$appName",
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                dialogTitle: "选择文件",
                type: FileType.any,
                allowedExtensions: ['txt'],
                lockParentWindow: true,
              );
              if (result != null) {
                ImportTokenUtil.importUriFile(result.files.single.path!);
              }
            },
          ),
          ItemBuilder.buildEntryItem(
            context: context,
            title: "导出URI格式",
            bottomRadius: true,
            description: "将令牌信息（不包含分类和图标）导出到未经加密的纯文本格式文件，兼容性较高",
            onTap: () async {
              String? result = await FilePicker.platform.saveFile(
                dialogTitle: "选择文件",
                type: FileType.any,
                allowedExtensions: ['txt'],
                lockParentWindow: true,
              );
              if (result != null) {
                ExportTokenUtil.exportUriFile(result);
              }
            },
          ),
        ],
      ),
    );
  }
}
