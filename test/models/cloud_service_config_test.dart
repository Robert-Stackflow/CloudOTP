import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:flutter_test/flutter_test.dart';

CloudServiceConfig _webDavConfig(String endpoint) {
  return CloudServiceConfig.init(
    type: CloudServiceType.Webdav,
    endpoint: endpoint,
    account: 'user',
    secret: 'password',
  );
}

void main() {
  test('WebDAV HTTPS configuration is valid by default', () async {
    final config = _webDavConfig('https://dav.example.com');

    expect(config.hasConfiguration, isTrue);
    expect(await config.isValid(), isTrue);
  });

  test('configuration presence is separate from connection validity', () async {
    final config = _webDavConfig('http://192.168.1.2/dav');

    expect(config.hasConfiguration, isTrue);
    expect(await config.isValid(), isFalse);

    final emptyConfig = CloudServiceConfig.init(type: CloudServiceType.Webdav);
    expect(emptyConfig.hasConfiguration, isFalse);
  });

  test('OAuth configuration is only present after authorization', () {
    final config = CloudServiceConfig.init(type: CloudServiceType.OneDrive);

    expect(config.hasConfiguration, isFalse);
    config.configured = true;
    expect(config.hasConfiguration, isTrue);
  });

  test('WebDAV HTTP requires an explicit persisted opt-in', () async {
    final config = _webDavConfig(' HTTP://192.168.1.2/dav ');

    expect(config.usesInsecureWebDavHttp, isTrue);
    expect(await config.isValid(), isFalse);

    config.allowsInsecureWebDavHttp = true;
    expect(await config.isValid(), isTrue);

    final restored = CloudServiceConfig.fromMap(config.toMap());
    expect(restored.allowsInsecureWebDavHttp, isTrue);
    expect(await restored.isValid(), isTrue);
  });

  test('removing the HTTP opt-in preserves the rest of the remark data', () {
    final config = _webDavConfig('http://192.168.1.2/dav');
    config.remark['title'] = 'Home NAS';
    config.allowsInsecureWebDavHttp = true;

    config.allowsInsecureWebDavHttp = false;

    expect(config.allowsInsecureWebDavHttp, isFalse);
    expect(config.title, 'Home NAS');
  });
}
