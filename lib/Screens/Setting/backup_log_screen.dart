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

import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/config_dao.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';

class BackupLogScreen extends StatefulWidget {
  const BackupLogScreen({
    super.key,
    this.isOverlay = false,
  });

  final bool isOverlay;

  @override
  BackupLogScreenState createState() => BackupLogScreenState();
}

class BackupLogScreenState extends BaseDynamicState<BackupLogScreen> {
  String _autoBackupPassword = "";

  bool get canBackup => _autoBackupPassword.isNotEmpty;

  @override
  void initState() {
    super.initState();
    ConfigDao.getConfig().then((config) {
      setState(() {
        _autoBackupPassword = config.backupPassword;
      });
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (appProvider.autoBackupLoadingStatus == LoadingStatus.failed) {
        appProvider.autoBackupLoadingStatus = LoadingStatus.none;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.isOverlay
        ? _buildDesktopBody()
        : Scaffold(
            appBar: ResponsiveAppBar(
              backgroundColor: Colors.transparent,
              title: appLocalizations.backupLogs,
              showBack: true,
              showBorder: true,
              onTapBack: () {
                Navigator.pop(context);
              },
              actions: [
                canBackup && appProvider.autoBackupLogs.isNotEmpty
                    ? CircleIconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: ChewieTheme.iconColor,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(10),
                        onTap: clear,
                      )
                    : const BlankIconButton(),
                const SizedBox(width: 5),
                if (ResponsiveUtil.isLandscapeLayout())
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: const BlankIconButton(),
                  ),
              ],
            ),
            body: _buildBody(),
          );
  }

  _buildDesktopBody() {
    return Container(
      decoration: BoxDecoration(
        color: ChewieTheme.scaffoldBackgroundColor,
        borderRadius: ChewieDimens.borderRadius8,
        border: ChewieTheme.border,
        boxShadow: ChewieTheme.defaultBoxShadow,
      ),
      width: !ResponsiveUtil.isLandscapeLayout()
          ? null
          : min(300, MediaQuery.sizeOf(context).width - 80),
      height: !ResponsiveUtil.isLandscapeLayout()
          ? null
          : min(appProvider.autoBackupLogs.isEmpty ? 200 : 400,
              MediaQuery.sizeOf(context).height - 80),
      child: _buildBody(),
    );
  }

  clear() {
    appProvider.clearAutoBackupLogs();
    appProvider.autoBackupLoadingStatus = LoadingStatus.none;
  }

  _buildBody() {
    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: widget.isOverlay ? 10 : 0),
      physics: widget.isOverlay
          ? null
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      children: [
        if (widget.isOverlay)
          Row(
            children: [
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  appLocalizations.backupLogs,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
              ),
              const Spacer(),
              if (canBackup && appProvider.autoBackupLogs.isNotEmpty)
                CircleIconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                  ),
                  onTap: clear,
                ),
            ],
          ),
        if (widget.isOverlay && appProvider.autoBackupLogs.isNotEmpty)
          const SizedBox(height: 10),
        ...List.generate(
          appProvider.autoBackupLogs.length,
          (index) {
            return BackupLogItem(
              log: appProvider.autoBackupLogs[index],
              isOverlay: widget.isOverlay,
            );
          },
        ),
        if (!canBackup)
          Column(
            children: [
              Text(
                appLocalizations.haveNotSetBackupPassword,
                style: ChewieTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              RoundIconTextButton(
                text: appLocalizations.goToSetBackupPassword,
                background: ChewieTheme.primaryColor,
                onPressed: () {
                  if (widget.isOverlay) {
                    RouteUtil.pushDialogRoute(
                        context,
                        const BackupSettingScreen(
                            jumpToAutoBackupPassword: true));
                  } else {
                    RouteUtil.pushCupertinoRoute(
                        context,
                        const BackupSettingScreen(
                            jumpToAutoBackupPassword: true));
                  }
                },
              ),
            ],
          ),
        if (canBackup && appProvider.autoBackupLogs.isEmpty)
          EmptyPlaceholder(text: appLocalizations.noBackupLogs, topPadding: 30),
      ],
    );
  }
}

class BackupLogItem extends StatefulWidget {
  final AutoBackupLog log;

  final bool isOverlay;

  const BackupLogItem({super.key, required this.log, required this.isOverlay});

  @override
  BackupLogItemState createState() => BackupLogItemState();
}

class BackupLogItemState extends BaseDynamicState<BackupLogItem> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: ChewieTheme.canvasColor,
        borderRadius: ChewieDimens.borderRadius8,
        child: InkWell(
          borderRadius: ChewieDimens.borderRadius8,
          onTap: !expanded
              ? () {
                  setState(() {
                    expanded = true;
                  });
                }
              : null,
          child: Container(
            padding: EdgeInsets.all(widget.isOverlay ? 8 : 12),
            decoration: BoxDecoration(
              borderRadius: ChewieDimens.borderRadius8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.log.triggerType.label,
                      style: ChewieTheme.bodyMedium.apply(
                        fontSizeDelta: widget.isOverlay ? 0 : 1,
                      ),
                    ),
                    const Spacer(),
                    RoundIconTextButton(
                      radius: 5,
                      height: 24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      text: widget.log.lastStatusItem.labelShort,
                      textStyle: ChewieTheme.labelSmall?.apply(
                          color: Colors.white,
                          fontSizeDelta: widget.isOverlay ? 0 : 1),
                      background: widget.log.lastStatus.color,
                    ),
                    const SizedBox(width: 5),
                    CircleIconButton(
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: ChewieTheme.labelSmall?.color),
                      onTap: () {
                        setState(() {
                          expanded = !expanded;
                        });
                      },
                    ),
                  ],
                ),
                if (expanded) const SizedBox(height: 5),
                if (expanded) _buildList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildList() {
    return CustomHtmlWidget(
      content: List.generate(
        widget.log.status.length,
        (i) {
          AutoBackupLogStatusItem statusItem = widget.log.status[i];
          return '[${TimeUtil.timestampToDateString(statusItem.timestamp)}]: ${statusItem.label(widget.log)}';
        },
      ).join('<br>'),
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.apply(fontSizeDelta: widget.isOverlay ? 0 : 1),
    );
  }
}
