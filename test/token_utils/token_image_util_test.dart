import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icon matching favors exact names and refreshes its index', () {
    final original = TokenImageUtil.brandLogos;
    addTearDown(() => TokenImageUtil.brandLogos = original);

    TokenImageUtil.brandLogos = ['wgetcloud.png', 'cloudflare.png'];
    expect(TokenImageUtil.matchBrandLogos('wgetcloud').first, 'wgetcloud.png');

    TokenImageUtil.brandLogos = ['wexample.png'];
    expect(TokenImageUtil.matchBrandLogos('wgetcloud'), isEmpty);
    expect(TokenImageUtil.matchBrandLogos('wexample').first, 'wexample.png');
  });
}
