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

import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/Custom/loading_icon.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';

import '../../Database/config_dao.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class BackupLogScreen extends StatefulWidget {
  const BackupLogScreen({
    super.key,
    this.isOverlay = false,
  });

  final bool isOverlay;

  @override
  BackupLogScreenState createState() => BackupLogScreenState();
}

class BackupLogScreenState extends State<BackupLogScreen> {
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
            appBar: ItemBuilder.buildAppBar(
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                S.current.backupLogs,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .apply(fontWeightDelta: 2),
              ),
              center: canBackup && appProvider.autoBackupLogs.isNotEmpty,
              leading: Icons.arrow_back_rounded,
              onLeadingTap: () {
                Navigator.pop(context);
              },
              actions: [
                canBackup && appProvider.autoBackupLogs.isNotEmpty
                    ? ItemBuilder.buildIconButton(
                        context: context,
                        icon: Icon(
                          Icons.cleaning_services_outlined,
                          color: Theme.of(context).iconTheme.color,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(10),
                        onTap: clear,
                      )
                    : ItemBuilder.buildBlankIconButton(context),
                const SizedBox(width: 5),
                if (ResponsiveUtil.isLandscape())
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: ItemBuilder.buildBlankIconButton(context),
                  ),
              ],
            ),
            body: _buildBody(),
          );
  }

  _buildDesktopBody() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(rootContext).shadowColor,
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ).scale(2)
        ],
      ),
      width: !ResponsiveUtil.isLandscape()
          ? null
          : min(300, MediaQuery.sizeOf(context).width - 80),
      height: !ResponsiveUtil.isLandscape()
          ? null
          : min(appProvider.autoBackupLogs.isEmpty ? 200 : 400,
              MediaQuery.sizeOf(context).height - 80),
      child: _buildBody(),
    );
  }

  clear() {
    appProvider.clearAutoBackupLogs();
    appProvider.autoBackupLoadingStatus = LoadingStatus.none;
    if (widget.isOverlay) {
      context.contextMenuOverlay.hide();
    }
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
                  S.current.backupLogs,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
              ),
              const Spacer(),
              if (canBackup && appProvider.autoBackupLogs.isNotEmpty)
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: const Icon(
                    Icons.cleaning_services_outlined,
                    size: 16,
                  ),
                  onTap: clear,
                ),
            ],
          ),
        if (widget.isOverlay) const SizedBox(height: 10),
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
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                Text(
                  S.current.haveNotSetBckupPassword,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                ItemBuilder.buildRoundButton(
                  context,
                  text: S.current.goToSetBackupPassword,
                  background: Theme.of(context).primaryColor,
                  onTap: () {
                    if (widget.isOverlay) {
                      context.contextMenuOverlay.hide();
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
          ),
        if (canBackup && appProvider.autoBackupLogs.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: ItemBuilder.buildEmptyPlaceholder(
              context: context,
              text: S.current.noBackupLogs,
            ),
          ),
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

class BackupLogItemState extends State<BackupLogItem> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: widget.isOverlay
            ? MyTheme.getCardBackground(context)
            : Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.log.triggerType.label,
                      style: Theme.of(context).textTheme.bodyMedium?.apply(
                            fontSizeDelta: widget.isOverlay ? 0 : 1,
                          ),
                    ),
                    const Spacer(),
                    ItemBuilder.buildRoundButton(
                      context,
                      radius: 5,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      text: widget.log.lastStatusItem.labelShort,
                      textStyle: Theme.of(context).textTheme.labelSmall?.apply(
                          color: Colors.white,
                          fontSizeDelta: widget.isOverlay ? 0 : 1),
                      background: widget.log.lastStatus.color,
                    ),
                    const SizedBox(width: 5),
                    ItemBuilder.buildIconButton(
                      context: context,
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Theme.of(context).textTheme.labelSmall?.color),
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
    return ItemBuilder.buildHtmlWidget(
      context,
      textStyle: Theme.of(context)
          .textTheme
          .labelSmall
          ?.apply(fontSizeDelta: widget.isOverlay ? 0 : 1),
      List.generate(
        widget.log.status.length,
        (i) {
          AutoBackupLogStatusItem statusItem = widget.log.status[i];
          return '[${Utils.timestampToDateString(statusItem.timestamp)}]: ${statusItem.label(widget.log)}';
        },
      ).join('<br>'),
    );
  }
}
