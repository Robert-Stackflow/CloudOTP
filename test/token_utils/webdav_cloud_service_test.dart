import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebDAV file paths use URL separators on every platform', () {
    expect(WebDavCloudService.remoteFilePath('backup.bin'),
        '/CloudOTP/backup.bin');
    expect(WebDavCloudService.remoteFilePath('/CloudOTP/backup.bin'),
        '/CloudOTP/backup.bin');
    expect(WebDavCloudService.remoteFilePath(r'\CloudOTP\backup.bin'),
        '/CloudOTP/backup.bin');
  });

  test('backup sorting tolerates missing modification times', () {
    final files = <WebDavFileInfo>[
      WebDavFileInfo(name: 'unknown.bin'),
      WebDavFileInfo(name: 'old.bin', cTime: DateTime.utc(2024, 1, 1)),
      WebDavFileInfo(name: 'new.bin', mTime: DateTime.utc(2025, 1, 1)),
    ];

    WebDavCloudService.sortBackupsNewestFirst(files);

    expect(
        files.map((file) => file.name), ['new.bin', 'old.bin', 'unknown.bin']);
  });
}
