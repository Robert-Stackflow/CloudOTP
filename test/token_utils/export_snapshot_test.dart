import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
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

  test('backup snapshot loads all relationships in one transaction', () async {
    final token = OtpToken.init(
      issuer: 'Issuer',
      secret: 'JBSWY3DPEHPK3PXP',
    )..account = 'snapshot@example.com';
    final category = TokenCategory.title(title: 'Snapshot');
    await database.insert('otp_token', token.toMap()..remove('id'));
    await database.insert('token_category', category.toMap()..remove('id'));
    await database.insert('token_category_binding', {
      'token_uid': token.uid,
      'category_uid': category.uid,
    });

    final snapshot =
        await ExportTokenUtil.createBackupSnapshot(overrideDb: database);

    expect(snapshot.tokens.map((item) => item.uid), [token.uid]);
    expect(snapshot.categories.map((item) => item.uid), [category.uid]);
    expect(snapshot.categories.single.bindings, [token.uid]);
  });

  test('selected snapshot excludes unrelated categories and bindings',
      () async {
    final selected = OtpToken.init()..account = 'selected@example.com';
    final unrelated = OtpToken.init()..account = 'other@example.com';
    final selectedCategory = TokenCategory.title(title: 'Selected');
    final unrelatedCategory = TokenCategory.title(title: 'Unrelated');
    for (final category in [selectedCategory, unrelatedCategory]) {
      await database.insert(
        'token_category',
        category.toMap()..remove('id'),
      );
    }
    await database.insert('token_category_binding', {
      'token_uid': selected.uid,
      'category_uid': selectedCategory.uid,
    });
    await database.insert('token_category_binding', {
      'token_uid': unrelated.uid,
      'category_uid': unrelatedCategory.uid,
    });

    final categories = await ExportTokenUtil.createCategorySnapshotForTokens(
      {selected.uid},
      overrideDb: database,
    );

    expect(categories.map((item) => item.uid), [selectedCategory.uid]);
    expect(categories.single.bindings, [selected.uid]);
  });
}
