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
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../../Utils/utils.dart';
import '../../../l10n/l10n.dart';

class WebDavBackupsBottomSheet extends StatefulWidget {
  const WebDavBackupsBottomSheet({
    super.key,
    required this.files,
    required this.onSelected,
    required this.cloudService,
  });

  final List<WebDavFileInfo> files;
  final Function(WebDavFileInfo) onSelected;
  final WebDavCloudService cloudService;

  @override
  WebDavBackupsBottomSheetState createState() =>
      WebDavBackupsBottomSheetState();
}

class WebDavBackupsBottomSheetState extends BaseDynamicState<WebDavBackupsBottomSheet> {
  late List<WebDavFileInfo> files;

  @override
  void initState() {
    files = widget.files;
    super.initState();
  }

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    var mainBody = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
            top: radius,
            bottom: ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
        color: ChewieTheme.scaffoldBackgroundColor,
        border: ChewieTheme.border,
        boxShadow: ChewieTheme.defaultBoxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(),
          Flexible(
            child: _buildButtons(),
          ),
        ],
      ),
    );
    return ResponsiveUtil.isWideLandscape()
        ? Center(child: mainBody)
        : mainBody;
  }

  _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: radius),
        color: ChewieTheme.canvasColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      alignment: Alignment.center,
      child: Text(
        appLocalizations.cloudBackupFiles(widget.files.length),
        style:
            ChewieTheme.titleMedium?.apply(fontWeightDelta: 2),
      ),
    );
  }

  _buildButtons() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) => _buildItem(files[index]),
      itemCount: files.length,
    );
  }

  _buildItem(WebDavFileInfo file) {
    String size =
        CacheUtil.renderSize(file.size?.toDouble() ?? 0, fractionDigits: 0);
    String time =
        TimeUtil.formatTimestamp(file.mTime?.millisecondsSinceEpoch ?? 0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.5,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name ?? "",
                      style: ChewieTheme.titleMedium,
                    ),
                    Text(
                      "$time    $size",
                      style: ChewieTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: const Icon(LucideIcons.import, size: 20),
                onTap: () async {
                  Navigator.pop(context);
                  widget.onSelected(file);
                },
              ),
              const SizedBox(width: 5),
              CircleIconButton(
                icon:
                    const Icon(LucideIcons.trash, color: Colors.red, size: 20),
                onTap: () async {
                  CustomLoadingDialog.showLoading(title: appLocalizations.deleting);
                  try {
                    await widget.cloudService.deleteFile(file.path ?? "");
                    setState(() {
                      files.remove(file);
                    });
                    IToast.showTop(appLocalizations.deleteSuccess);
                  } catch (e, t) {
                    ILogger.error("Failed to delete file from webdav", e, t);
                    IToast.showTop(appLocalizations.deleteFailed);
                  }
                  CustomLoadingDialog.dismissLoading();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
