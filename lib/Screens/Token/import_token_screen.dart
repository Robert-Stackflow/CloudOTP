import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../TokenUtils/import_token_util.dart';

class ImportTokenScreen extends StatefulWidget {
  const ImportTokenScreen({
    super.key,
  });

  static const String routeName = "/token/import";

  @override
  State<ImportTokenScreen> createState() => _ImportTokenScreenState();
}

class _ImportTokenScreenState extends State<ImportTokenScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
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
          "添加令牌",
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
          ItemBuilder.buildEntryItem(
            context: context,
            title: "导入URI格式",
            topRadius: true,
            description: "纯文本格式的OTPAuth URI列表",
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
            bottomRadius: true,
            title: "导入JSON格式",
            description: "JSON格式的令牌信息列表",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
