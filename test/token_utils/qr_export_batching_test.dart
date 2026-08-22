import 'dart:convert';

import 'package:cloudotp/Models/Proto/CloudOtpToken/cloudotp_token_payload.pb.dart';
import 'package:cloudotp/Models/Proto/OtpMigration/otp_migration.pb.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/constant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Google Authenticator QR batches preserve every token within the limit',
      () async {
    final tokens = List.generate(30, (index) {
      return OtpToken.init(
        issuer: 'Issuer-${_repeat('x', 40)}-$index',
        secret: 'JBSWY3DPEHPK3PXP',
      )..account = 'account-${_repeat('y', 40)}-$index@example.com';
    });

    final result = await ExportTokenUtil.exportToGoogleAuthentcatorQrcodes(
      showLoading: false,
      selectedTokens: tokens,
    );
    final qrcodes = List<String>.from(result![0] as List);
    var exportedCount = 0;
    for (final qrcode in qrcodes) {
      final encoded = Uri.parse(qrcode).queryParameters['data']!;
      expect(utf8.encode(encoded).length, lessThanOrEqualTo(maxBytesLength));
      final payload = OtpMigrationPayload.fromBuffer(base64Decode(encoded));
      exportedCount += payload.otpParameters.length;
    }

    expect(qrcodes.length, greaterThan(1));
    expect(exportedCount, tokens.length);
    expect(result[1], 0);
  });

  test('CloudOTP QR batches move the overflow token to a new payload',
      () async {
    final tokens = List.generate(24, (index) {
      return OtpToken.init(
        issuer: 'Issuer-$index',
        secret: 'JBSWY3DPEHPK3PXP',
      )
        ..account = 'account-$index@example.com'
        ..description = 'description-${_repeat('z', 80)}-$index';
    });

    final qrcodes = await ExportTokenUtil.exportToQrcodes(
      showLoading: false,
      selectedTokens: tokens,
    );
    var exportedCount = 0;
    for (final qrcode in qrcodes!) {
      final encoded = Uri.parse(qrcode).queryParameters['tokens']!;
      expect(utf8.encode(encoded).length, lessThanOrEqualTo(maxBytesLength));
      final payload = CloudOtpTokenPayload.fromBuffer(base64Decode(encoded));
      exportedCount += payload.tokenParameters.length;
    }

    expect(qrcodes.length, greaterThan(1));
    expect(exportedCount, tokens.length);
  });
}

String _repeat(String value, int count) => List.filled(count, value).join();
