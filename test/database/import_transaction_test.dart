import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
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

  test('backup import commits tokens, categories, and bindings together',
      () async {
    final token = _token('token-success', 'success@example.com');
    final category = TokenCategory.title(title: 'Work')
      ..uid = 'category-success'
      ..bindings = [token.uid];

    await ImportTokenUtil.confirmImport(
      [token],
      [category],
      overrideDb: database,
      notifyChanges: false,
    );

    expect(await _rowCount(database, 'otp_token'), 1);
    expect(await _rowCount(database, 'token_category'), 1);
    expect(await _rowCount(database, 'token_category_binding'), 1);
  });

  test('late binding failure rolls back the entire backup import', () async {
    await database.execute('''
      CREATE TRIGGER reject_imported_binding
      BEFORE INSERT ON token_category_binding
      BEGIN
        SELECT RAISE(ABORT, 'simulated binding failure');
      END
    ''');
    final token = _token('token-rollback', 'rollback@example.com');
    final category = TokenCategory.title(title: 'Rollback')
      ..uid = 'category-rollback'
      ..bindings = [token.uid];

    await expectLater(
      ImportTokenUtil.confirmImport(
        [token],
        [category],
        overrideDb: database,
        notifyChanges: false,
      ),
      throwsA(anything),
    );

    expect(await _rowCount(database, 'otp_token'), 0);
    expect(await _rowCount(database, 'token_category'), 0);
    expect(await _rowCount(database, 'token_category_binding'), 0);
  });
}

OtpToken _token(String uid, String account) {
  return OtpToken.init()
    ..uid = uid
    ..issuer = 'Issuer'
    ..account = account
    ..secret = 'JBSWY3DPEHPK3PXP';
}

Future<int> _rowCount(Database database, String table) async {
  final result =
      await database.rawQuery('SELECT COUNT(*) AS count FROM $table');
  return result.single['count'] as int;
}
