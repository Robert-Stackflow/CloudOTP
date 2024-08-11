import 'dart:math';

import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Screens/Setting/setting_screen.dart';
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
  const BackupLogScreen({super.key});

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
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtil.isLandscape()
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
              center: true,
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
              ],
            ),
            body: _buildBody(),
          );
  }

  _buildDesktopBody() {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
        borderRadius: BorderRadius.circular(10),
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
    if (ResponsiveUtil.isLandscape()) {
      context.contextMenuOverlay.hide();
    }
  }

  _buildBody() {
    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: ResponsiveUtil.isLandscape() ? 10 : 0),
      physics: ResponsiveUtil.isLandscape()
          ? null
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      children: [
        if (ResponsiveUtil.isLandscape())
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
        if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
        ...List.generate(
          appProvider.autoBackupLogs.length,
          (index) {
            return BackupLogItem(
              log: appProvider.autoBackupLogs[index],
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
                    if (ResponsiveUtil.isLandscape()) {
                      context.contextMenuOverlay.hide();
                      RouteUtil.pushDesktopFadeRoute(const SettingScreen());
                    } else {
                      RouteUtil.pushCupertinoRoute(
                          context, const SettingScreen());
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

  const BackupLogItem({super.key, required this.log});

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
        color: ResponsiveUtil.isLandscape()
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
            padding: EdgeInsets.all(ResponsiveUtil.isLandscape() ? 8 : 12),
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
                            fontSizeDelta: ResponsiveUtil.isLandscape() ? 0 : 1,
                          ),
                    ),
                    const Spacer(),
                    ItemBuilder.buildRoundButton(
                      context,
                      radius: 5,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      text: widget.log.lastStatus.labelShort,
                      textStyle: Theme.of(context).textTheme.labelSmall?.apply(
                          color: Colors.white,
                          fontSizeDelta: ResponsiveUtil.isLandscape() ? 0 : 1),
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
          ?.apply(fontSizeDelta: ResponsiveUtil.isLandscape() ? 0 : 1),
      List.generate(
        widget.log.status.length,
        (i) {
          AutoBackupLogStatusItem statusItem = widget.log.status[i];
          return '[${Utils.timestampToDateString(statusItem.timestamp)}]: ${statusItem.status.label(widget.log)}';
        },
      ).join('<br>'),
    );
  }
}
