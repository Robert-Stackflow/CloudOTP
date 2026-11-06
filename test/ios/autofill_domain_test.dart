import 'package:cloudotp/Platform/ios/autofill_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes explicit website domains without inferring brands', () {
    expect(normalizeAutoFillDomain(' EXAMPLE.com '), 'example.com');
    expect(normalizeAutoFillDomain('https://login.example.com/'),
        'login.example.com');
    expect(normalizeAutoFillDomain('GitHub'), isNull);
    expect(normalizeAutoFillDomain(''), isNull);
  });
  test('rejects URLs with credentials, paths, ports and invalid labels', () {
    for (final input in [
      'https://user:password@example.com',
      'example.com/path',
      'example.com?query=secret',
      'example.com#fragment',
      'example.com:8443',
      '-bad.example',
      'bad_.example',
      'file://example.com',
      'example..com'
    ]) {
      expect(normalizeAutoFillDomain(input), isNull, reason: input);
    }
  });
}
