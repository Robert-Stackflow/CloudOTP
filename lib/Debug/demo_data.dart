import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../Models/opt_token.dart';
import '../Models/token_category.dart';
import '../Utils/Base32/base32.dart';

/// Explicit developer fixture. Never runs on a normal app launch or in release.
class DemoData {
  static const dataset = 'ios-preview-v1';
  static const completionKey = 'debugDemoDataIosPreviewV1';
  static const services = [
    'Google',
    'Microsoft',
    'Slack',
    'Notion',
    'Dropbox',
    'Zoom',
    'Atlassian',
    'Figma',
    'Apple',
    'Amazon',
    'Facebook',
    'Instagram',
    'Discord',
    'Reddit',
    'Spotify',
    'GitHub',
    'GitLab',
    'AWS',
    'Cloudflare',
    'Vercel',
  ];
  static const categoryNames = ['示例 · 工作', '示例 · 个人', '示例 · 开发'];
  static String tokenUid(int index) => 'cloudotp-$dataset-token-${index + 1}';
  static String categoryUid(int index) =>
      'cloudotp-$dataset-category-${index + 1}';
  static int categoryFor(int index) => index < 8
      ? 0
      : index < 15
          ? 1
          : 2;

  static OtpToken token(int index, int seq) {
    final number = (index + 1).toString().padLeft(2, '0');
    return OtpToken.init(
      issuer: '${services[index]} · 示例',
      secret: base32.encode(
          Uint8List.fromList(utf8.encode('CloudOTP PUBLIC DEMO KEY $number'))),
    )
      ..uid = tokenUid(index)
      ..seq = seq
      ..account = 'demo$number@example.com'
      ..imagePath = '${services[index].toLowerCase()}.png'
      ..algorithm = index % 7 == 0 ? OtpAlgorithm.SHA256 : OtpAlgorithm.SHA1
      ..digits = index % 7 == 0 ? OtpDigits.D8 : OtpDigits.D6
      ..description = '仅用于界面演示，公开示例密钥，不可用于真实账户。'
      ..remark = {'demo_dataset': dataset};
  }

  static Future<({int tokens, int categories})> seed(Database database) {
    return database.transaction((transaction) async {
      var insertedTokens = 0;
      var insertedCategories = 0;
      final tokenMax = (await transaction
              .rawQuery('SELECT COALESCE(MAX(seq), 0) AS value FROM otp_token'))
          .first['value'] as int;
      final categoryMax = (await transaction.rawQuery(
              'SELECT COALESCE(MAX(seq), 0) AS value FROM token_category'))
          .first['value'] as int;
      Future<bool> exists(String table, String uid) async {
        final rows = await transaction.query(table,
            columns: ['remark'], where: 'uid = ?', whereArgs: [uid]);
        if (rows.isEmpty) return false;
        if ((jsonDecode(rows.first['remark'] as String)
                as Map)['demo_dataset'] !=
            dataset) {
          throw StateError('Demo identifier conflicts with existing data');
        }
        return true;
      }

      for (var i = 0; i < categoryNames.length; i++) {
        if (!await exists('token_category', categoryUid(i))) {
          final category =
              TokenCategory.title(title: categoryNames[i], tUid: categoryUid(i))
                ..seq = categoryMax + categoryNames.length - i
                ..description = 'CloudOTP 界面演示分类'
                ..remark = {'demo_dataset': dataset};
          await transaction.insert(
              'token_category', category.toMap()..remove('id'));
          insertedCategories++;
        }
      }
      for (var i = 0; i < services.length; i++) {
        if (!await exists('otp_token', tokenUid(i))) {
          await transaction.insert('otp_token',
              token(i, tokenMax + services.length - i).toMap()..remove('id'));
          insertedTokens++;
        }
        final category = categoryUid(categoryFor(i));
        final bindings = await transaction.query('token_category_binding',
            where: 'token_uid = ? AND category_uid = ?',
            whereArgs: [tokenUid(i), category]);
        if (bindings.isEmpty) {
          await transaction.insert('token_category_binding',
              {'token_uid': tokenUid(i), 'category_uid': category});
        }
      }
      return (tokens: insertedTokens, categories: insertedCategories);
    });
  }
}
