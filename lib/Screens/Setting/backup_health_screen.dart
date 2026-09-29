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
  final List<BackupHealthResult> _results = [];
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
      _results.clear();
    });
    try {
      await for (final result in BackupHealthService.checkAll()) {
        if (!mounted) return;
        setState(() => _results.add(result));
      }
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
    final scheme = Theme.of(context).colorScheme;
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.backupHealthTitle,
      showTitleBar: true,
      showBack: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, color: scheme.primary, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  appLocalizations.backupHealthReadOnly,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                appLocalizations.backupHealthResults,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _checking ? null : _check,
              icon: const Icon(LucideIcons.refreshCw, size: 17),
              label: Text(appLocalizations.backupHealthCheckNow),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_checking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(appLocalizations.backupHealthChecking),
              ],
            ),
          ),
        for (final result in _results) _resultCard(context, result),
        if (_checked && _failedToStart)
          _messageCard(context, appLocalizations.backupHealthCheckFailed),
        if (_checked && !_failedToStart && _results.isEmpty)
          _messageCard(context, appLocalizations.backupHealthNoSources),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _messageCard(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _resultCard(BuildContext context, BackupHealthResult result) {
    final scheme = Theme.of(context).colorScheme;
    final good = result.isHealthy;
    final color = good ? scheme.primary : scheme.error;
    final source =
        result.isLocal ? appLocalizations.backupHealthLocal : result.sourceName;
    final status = _statusText(result.status);
    final backupTime = result.backupTime;
    final timeText = backupTime == null
        ? null
        : '${MaterialLocalizations.of(context).formatMediumDate(backupTime)} '
            '${TimeOfDay.fromDateTime(backupTime).format(context)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              good ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(status,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: color)),
                if (good) ...[
                  const SizedBox(height: 6),
                  Text(
                    appLocalizations.backupHealthCounts(
                      result.tokenCount ?? 0,
                      result.categoryCount ?? 0,
                      result.bindingCount ?? 0,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (result.fileName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    result.fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (timeText != null) ...[
                  const SizedBox(height: 2),
                  Text(timeText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(BackupHealthStatus status) {
    switch (status) {
      case BackupHealthStatus.healthy:
        return appLocalizations.backupHealthHealthy;
      case BackupHealthStatus.noBackup:
        return appLocalizations.backupHealthNoBackup;
      case BackupHealthStatus.noPassword:
        return appLocalizations.backupHealthNoPassword;
      case BackupHealthStatus.unavailable:
        return appLocalizations.backupHealthUnavailable;
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
