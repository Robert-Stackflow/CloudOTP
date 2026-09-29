import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../TokenUtils/Backup/backup_health_service.dart';
import '../../l10n/l10n.dart';

class BackupHealthScreen extends StatefulWidget {
  const BackupHealthScreen({super.key});

  @override
  State<BackupHealthScreen> createState() => _BackupHealthScreenState();
}

class _BackupHealthScreenState extends State<BackupHealthScreen> {
  List<BackupHealthResult> _results = [];
  bool _checking = false;
  bool _checked = false;
  bool _failedToStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _checked = false;
      _failedToStart = false;
    });
    try {
      final nextResults = <BackupHealthResult>[];
      await for (final result in BackupHealthService.checkAll()) {
        if (!mounted) return;
        nextResults.add(result);
        setState(() => _results = List.of(nextResults));
      }
      if (mounted) setState(() => _results = nextResults);
    } catch (error, stackTrace) {
      ILogger.error('Failed to start backup health check', error, stackTrace);
      if (mounted) setState(() => _failedToStart = true);
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _checked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.backupHealthTitle,
      showTitleBar: true,
      showBack: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                appLocalizations.backupHealthResults,
                style: ChewieTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            RoundIconTextButton(
              height: 36,
              minHeight: 36,
              radius: 9,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: _checking ? null : _check,
              icon: _checking
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ChewieTheme.primaryColor,
                      ),
                    )
                  : Icon(LucideIcons.refreshCw,
                      size: 16, color: ChewieTheme.primaryColor),
              text: _checking
                  ? appLocalizations.backupHealthChecking
                  : _checked
                      ? appLocalizations.backupHealthCheckAgain
                      : appLocalizations.backupHealthCheckNow,
              color: ChewieTheme.primaryColor,
              textStyle: ChewieTheme.bodySmall.copyWith(
                color: ChewieTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final result in _results) _resultCard(context, result),
        if (_checked && _failedToStart)
          TipBanner.error(appLocalizations.backupHealthCheckFailed),
        if (_checked && !_failedToStart && _results.isEmpty)
          TipBanner.info(appLocalizations.backupHealthNoSources),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _resultCard(BuildContext context, BackupHealthResult result) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor(result.status, scheme);
    final source =
        result.isLocal ? appLocalizations.backupHealthLocal : result.sourceName;
    final status = _statusText(result.status);
    final backupTime = result.backupTime;
    final timeText = backupTime == null
        ? null
        : '${MaterialLocalizations.of(context).formatMediumDate(backupTime)} '
            '${TimeOfDay.fromDateTime(backupTime).format(context)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChewieTheme.borderColor, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ChewieTheme.primaryColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  result.isLocal ? LucideIcons.hardDrive : LucideIcons.cloud,
                  color: ChewieTheme.primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _statusTag(status, color, result.status),
                    if (result.isHealthy) ...[
                      const SizedBox(height: 9),
                      Text(
                        appLocalizations.backupHealthCounts(
                          result.tokenCount ?? 0,
                          result.categoryCount ?? 0,
                          result.bindingCount ?? 0,
                        ),
                        style: ChewieTheme.bodySmall,
                      ),
                    ],
                    if (result.fileName != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        result.fileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChewieTheme.bodySmall,
                      ),
                    ],
                    if (timeText != null) ...[
                      const SizedBox(height: 3),
                      Text(timeText, style: ChewieTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag(String text, Color color, BackupHealthStatus status) {
    final icon = status == BackupHealthStatus.healthy
        ? LucideIcons.circleCheck
        : status == BackupHealthStatus.needsSetup ||
                status == BackupHealthStatus.noBackup
            ? LucideIcons.info
            : LucideIcons.triangleAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ChewieTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BackupHealthStatus status, ColorScheme scheme) {
    switch (status) {
      case BackupHealthStatus.healthy:
        return Colors.green.shade700;
      case BackupHealthStatus.needsSetup:
        return ChewieTheme.iconColor;
      case BackupHealthStatus.noBackup:
      case BackupHealthStatus.noPassword:
        return Colors.orange.shade700;
      default:
        return scheme.error;
    }
  }

  String _statusText(BackupHealthStatus status) {
    switch (status) {
      case BackupHealthStatus.healthy:
        return appLocalizations.backupHealthHealthy;
      case BackupHealthStatus.noBackup:
        return appLocalizations.backupHealthNoBackup;
      case BackupHealthStatus.noPassword:
        return appLocalizations.backupHealthNoPassword;
      case BackupHealthStatus.needsSetup:
        return appLocalizations.cloudStatusNeedsSetup;
      case BackupHealthStatus.unavailable:
        return appLocalizations.backupHealthUnavailable;
      case BackupHealthStatus.listFailed:
        return appLocalizations.backupHealthListFailed;
      case BackupHealthStatus.downloadFailed:
        return appLocalizations.backupHealthDownloadFailed;
      case BackupHealthStatus.fileTooLarge:
        return appLocalizations.backupFileTooLarge;
      case BackupHealthStatus.invalidPasswordOrCorrupted:
        return appLocalizations.invalidPasswordOrDataCorrupted;
      case BackupHealthStatus.unsupportedVersion:
        return appLocalizations.backupVersionUnsupport;
      case BackupHealthStatus.invalidFormat:
        return appLocalizations.fileNotBackup;
      case BackupHealthStatus.failed:
        return appLocalizations.backupHealthCheckFailed;
    }
  }
}
