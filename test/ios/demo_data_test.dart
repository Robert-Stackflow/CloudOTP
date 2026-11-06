import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Debug/demo_data.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/code_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(Sql.createTokenTable.sql);
    await database.execute(Sql.createCategoryTable.sql);
    await database.execute(Sql.createTokenCategoryBindingTable.sql);
  });
  tearDown(() => database.close());

  test(
      'adds 20 usable demo tokens in 8/7/5 categories without changing existing records',
      () async {
    final existing =
        OtpToken.init(issuer: 'Existing account', secret: 'JBSWY3DPEHPK3PXP')
          ..uid = 'existing-user-token'
          ..seq = 12;
    await database.insert('otp_token', existing.toMap()..remove('id'));
    final before = await database
        .query('otp_token', where: 'uid = ?', whereArgs: [existing.uid]);
    final result = await DemoData.seed(database);
    expect(result, (tokens: 20, categories: 3));
    expect(
        await database
            .query('otp_token', where: 'uid = ?', whereArgs: [existing.uid]),
        before);
    final rows = await database.query('otp_token',
        where: 'uid LIKE ?',
        whereArgs: ['cloudotp-${DemoData.dataset}-token-%']);
    expect(rows, hasLength(20));
    for (final row in rows) {
      final token = OtpToken.fromMap(row);
      expect(token.issuer, contains('示例'));
      expect(token.account, endsWith('@example.com'));
      final code = CodeGenerator.getCurrentCode(token);
      expect(code, matches(RegExp(r'^\d+$')));
      expect(code.length, token.digits.digit);
    }
    final counts = await database.rawQuery(
        'SELECT category_uid, COUNT(*) AS count FROM token_category_binding GROUP BY category_uid ORDER BY category_uid');
    expect(counts.map((r) => r['count']), [8, 7, 5]);
  });
  test('rerunning fixture does not duplicate or overwrite edited demo tokens',
      () async {
    await DemoData.seed(database);
    await database.update('otp_token', {'account': 'edited-demo@example.com'},
        where: 'uid = ?', whereArgs: [DemoData.tokenUid(0)]);
    expect(await DemoData.seed(database), (tokens: 0, categories: 0));
    expect(await database.query('otp_token'), hasLength(20));
    expect(await database.query('token_category'), hasLength(3));
    expect(await database.query('token_category_binding'), hasLength(20));
    expect(
        (await database.query('otp_token',
                where: 'uid = ?', whereArgs: [DemoData.tokenUid(0)]))
            .single['account'],
        'edited-demo@example.com');
  });
  test(
      'identifier collision rolls back the entire import rather than overwriting data',
      () async {
    final existing =
        OtpToken.init(issuer: 'Preserve me', secret: 'JBSWY3DPEHPK3PXP')
          ..uid = DemoData.tokenUid(0);
    await database.insert('otp_token', existing.toMap()..remove('id'));
    await expectLater(DemoData.seed(database), throwsStateError);
    expect(await database.query('token_category'), isEmpty);
    expect(await database.query('token_category_binding'), isEmpty);
    expect((await database.query('otp_token')).single['issuer'], 'Preserve me');
  });
}
