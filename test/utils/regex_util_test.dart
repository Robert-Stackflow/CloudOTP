import 'package:cloudotp/Utils/regex_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts complete WebDAV URLs with custom ports and paths', () {
    expect(RegexUtil.isUrlOrIp('https://xxx.ink:15006/'), isTrue);
    expect(
        RegexUtil.isUrlOrIp('https://x.technology:15006/dav/files/a/'), isTrue);
    expect(RegexUtil.isUrlOrIp('http://localhost:8080/dav'), isTrue);
    expect(RegexUtil.isUrlOrIp('localhost:8080'), isTrue);
    expect(RegexUtil.isUrlOrIp('localhost:8080', requireScheme: true), isFalse);
  });

  test('rejects invalid ports, hosts and trailing content', () {
    expect(RegexUtil.isUrlOrIp('https://example.com:65536/'), isFalse);
    expect(RegexUtil.isUrlOrIp('https://999.999.999.999/'), isFalse);
    expect(RegexUtil.isUrlOrIp('https://example.com/ extra'), isFalse);
    expect(RegexUtil.isUrlOrIp('https://example.com.evil@other.com'), isFalse);
  });
}
