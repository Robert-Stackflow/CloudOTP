import 'dart:typed_data';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

void main() {
  testWidgets('recognized OTP QR analysis completes and returns the token',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const uri =
        'otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example';
    final imageBytes = _renderQrCode(uri);

    late List<dynamic> result;
    await tester.runAsync(() async {
      result = await ImportTokenUtil.analyzeImage(
        imageBytes,
        context: context,
        showLoading: false,
        showSingleTokenDialog: false,
      ).timeout(const Duration(seconds: 10));
    });

    expect(result, hasLength(2));
    final tokens = List<OtpToken>.from(result.first as List);
    expect(tokens, hasLength(1));
    expect(tokens.single.issuer, 'Example');
    expect(tokens.single.account, 'alice@example.com');
  });
}

Uint8List _renderQrCode(String content) {
  final matrix = Encoder.encode(content, ErrorCorrectionLevel.l).matrix!;
  const moduleScale = 8;
  const quietZoneModules = 4;
  final imageSize = (matrix.width + quietZoneModules * 2) * moduleScale;
  final image = img.Image(width: imageSize, height: imageSize);

  for (int y = 0; y < imageSize; y++) {
    for (int x = 0; x < imageSize; x++) {
      image.setPixelRgb(x, y, 255, 255, 255);
    }
  }
  for (int y = 0; y < matrix.height; y++) {
    for (int x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) != 1) continue;
      final startX = (x + quietZoneModules) * moduleScale;
      final startY = (y + quietZoneModules) * moduleScale;
      for (int dy = 0; dy < moduleScale; dy++) {
        for (int dx = 0; dx < moduleScale; dx++) {
          image.setPixelRgb(startX + dx, startY + dy, 0, 0, 0);
        }
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
