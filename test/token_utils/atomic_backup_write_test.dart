import 'dart:io';
import 'dart:typed_data';

import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cloudotp-backup-test-');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('verified backup is renamed to its final path', () async {
    final destination = File('${directory.path}/backup.bin');
    final data = Uint8List.fromList([1, 2, 3, 4]);

    final result = await ExportTokenUtil.writeBackupAtomically(
      destination,
      data,
    );

    expect(result.path, destination.path);
    expect(await destination.readAsBytes(), data);
    expect(
      directory.listSync().where((entry) => entry.path.contains('.part-')),
      isEmpty,
    );
  });

  test('an existing backup is preserved instead of overwritten', () async {
    final destination = File('${directory.path}/backup.bin');
    final original = Uint8List.fromList([9, 8, 7]);
    await destination.writeAsBytes(original, flush: true);

    await expectLater(
      ExportTokenUtil.writeBackupAtomically(
        destination,
        Uint8List.fromList([1, 2, 3]),
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await destination.readAsBytes(), original);
    expect(
      directory.listSync().where((entry) => entry.path.contains('.part-')),
      isEmpty,
    );
  });

  test('backup names remain unique for the same clock instant', () {
    final instant = DateTime(2026, 8, 2, 12, 30, 15, 123, 456);

    final first = ExportTokenUtil.getExportFileName('bin', now: instant);
    final second = ExportTokenUtil.getExportFileName('bin', now: instant);

    expect(second, isNot(first));
    expect(first, startsWith('CloudOTP-Backup-2026-08-02-12-30-15-'));
    expect(second, endsWith('.bin'));
  });
}
