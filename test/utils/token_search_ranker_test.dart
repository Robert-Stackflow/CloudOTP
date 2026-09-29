import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/token_search_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches full pinyin and initials with lower priority than text', () {
    final chinese = OtpToken.init(issuer: '网易云');
    final exact = OtpToken.init(issuer: 'wyy');

    expect(TokenSearchRanker.score(chinese, 'wangyiyun'), isNotNull);
    expect(TokenSearchRanker.score(chinese, 'wyy'), isNotNull);
    expect(TokenSearchRanker.score(exact, 'wyy'),
        greaterThan(TokenSearchRanker.score(chinese, 'wyy')!));
  });

  test('prioritizes issuer text and invalidates a changed token index', () {
    final token = OtpToken.init(issuer: 'Cloud OTP')..account = 'Alice';
    expect(TokenSearchRanker.score(token, 'cloudotp'),
        greaterThan(TokenSearchRanker.score(token, 'alice')!));
    token.issuer = 'Example';
    expect(TokenSearchRanker.score(token, 'cloudotp'), isNull);
  });
}
