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

import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../TokenUtils/export_token_util.dart';
import '../../../Utils/utils.dart';
import '../../../generated/l10n.dart';

class LocalBackupsBottomSheet extends StatefulWidget {
  const LocalBackupsBottomSheet({
    super.key,
    required this.onSelected,
  });

  final Function(FileSystemEntity) onSelected;

  @override
  LocalBackupsBottomSheetState createState() => LocalBackupsBottomSheetState();
}

class LocalBackupsBottomSheetState extends State<LocalBackupsBottomSheet> {
  List<FileSystemEntity> files = const [];
  List<FileSystemEntity> defaultPathBackupFiles = const [];

  @override
  void initState() {
    ExportTokenUtil.getLocalBackups().then((value) {
      setState(() {
        files = value[0];
        defaultPathBackupFiles = value[1];
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        defaultPathBackupFiles.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      });
    });
    super.initState();
  }

  Radius radius = ChewieDimens.radius16;

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
        S.current
            .cloudBackupFiles(files.length + defaultPathBackupFiles.length),
        style:
            Theme.of(context).textTheme.titleMedium?.apply(fontWeightDelta: 2),
      ),
    );
  }

  _buildButtons() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) => _buildItem(
        index < files.length
            ? files[index]
            : defaultPathBackupFiles[index - files.length],
        index >= files.length,
      ),
      itemCount: files.length + defaultPathBackupFiles.length,
    );
  }

  _buildItem(FileSystemEntity file, bool isDefaultPath) {
    String size = CacheUtil.renderSize(file.statSync().size.toDouble(),
        fractionDigits: 0);
    String time = TimeUtil.formatTimestamp(
        file.statSync().modified.millisecondsSinceEpoch);
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
                      FileUtil.getFileNameWithExtension(file.path),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "$time    $size${isDefaultPath ? "    ${S.current.fromInternalBackupPath}" : ""}",
                      style: Theme.of(context).textTheme.bodySmall,
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
                  CustomLoadingDialog.showLoading(title: S.current.deleting);
                  try {
                    await file.delete();
                    setState(() {
                      files.remove(file);
                    });
                    IToast.showTop(S.current.deleteSuccess);
                  } catch (e, t) {
                    ILogger.error(
                        "Failed to delete backup file from local", e, t);
                    IToast.showTop(S.current.deleteFailed);
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
