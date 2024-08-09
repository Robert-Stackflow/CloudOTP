import 'dart:math';

import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Widgets/Custom/loading_icon.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';

import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class BackupLogScreen extends StatefulWidget {
  const BackupLogScreen({super.key});

  @override
  BackupLogScreenState createState() => BackupLogScreenState();
}

class BackupLogScreenState extends State<BackupLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ).scale(2),
        ],
      ),
      width: min(300, MediaQuery.sizeOf(context).width - 80),
      height: min(appProvider.autoBackupLogs.isEmpty ? 200 : 400,
          MediaQuery.sizeOf(context).height - 80),
      child: _buildBody(),
    );
  }

  _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Row(
          children: [
            const SizedBox(width: 5),
            Text(
              S.current.backupLogs,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.apply(fontWeightDelta: 2),
            ),
            const Spacer(),
            ItemBuilder.buildIconButton(
              context: context,
              icon: const Icon(
                Icons.cleaning_services_outlined,
                size: 16,
              ),
              onTap: () {
                appProvider.clearAutoBackupLogs();
                appProvider.autoBackupLoadingStatus = LoadingStatus.none;
                context.contextMenuOverlay.hide();
              },
            ),
            const SizedBox(width: 5),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(
          appProvider.autoBackupLogs.length,
          (index) {
            return BackupLogItem(
              log: appProvider.autoBackupLogs[index],
            );
          },
        ),
        if (appProvider.autoBackupLogs.isEmpty)
          ItemBuilder.buildEmptyPlaceholder(
            context: context,
            text: S.current.noBackupLogs,
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
        color: MyTheme.getCardBackground(context),
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
            padding: const EdgeInsets.all(8),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    ItemBuilder.buildRoundButton(
                      context,
                      radius: 5,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      text: widget.log.lastStatus.labelShort,
                      textStyle: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.apply(color: Colors.white),
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
      textStyle: Theme.of(context).textTheme.labelSmall,
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
