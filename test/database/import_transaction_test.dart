import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
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

  test('overwrite restores backup fields and replaces category bindings',
      () async {
    final existingToken = _token('local-token', 'duplicate@example.com')
      ..seq = 7
      ..description = 'local description'
      ..counterString = '1'
      ..tags = ['local'];
    existingToken.id = await database.insert(
      'otp_token',
      existingToken.toMap()..remove('id'),
    );
    final existingCategory = TokenCategory.title(title: 'Work')
      ..uid = 'local-category'
      ..seq = 4
      ..description = 'local category';
    existingCategory.id = await database.insert(
      'token_category',
      existingCategory.toMap()..remove('id'),
    );
    await database.insert('token_category_binding', {
      'token_uid': 'stale-token',
      'category_uid': existingCategory.uid,
    });

    final backupToken = _token('backup-token', 'duplicate@example.com')
      ..id = 999
      ..seq = 999
      ..tokenType = OtpTokenType.HOTP
      ..algorithm = OtpAlgorithm.SHA256
      ..digits = OtpDigits.D8
      ..counterString = '42'
      ..periodString = '60'
      ..pinned = true
      ..imagePath = 'backup.png'
      ..description = 'backup description'
      ..remark = {'source': 'backup'}
      ..copyTimes = 8
      ..lastCopyTimeStamp = 1234
      ..pin = '1234'
      ..tags = ['backup'];
    final backupCategory = TokenCategory.title(title: 'Work')
      ..id = 999
      ..uid = 'backup-category'
      ..seq = 999
      ..description = 'backup category'
      ..pinned = true
      ..remark = {'source': 'backup'}
      ..bindings = [backupToken.uid];

    await ImportTokenUtil.confirmImport(
      [backupToken],
      [backupCategory],
      overwriteExisting: true,
      tokenItems: [
        ImportTokenItem(
          token: backupToken,
          existingToken: existingToken,
          status: ImportTokenStatus.duplicate,
          selected: true,
        ),
      ],
      categoryItems: [
        ImportCategoryItem(
          category: backupCategory,
          existingCategory: existingCategory,
          isNew: false,
          selected: true,
        ),
      ],
      overrideDb: database,
      notifyChanges: false,
    );

    final restoredToken =
        (await TokenDao.listTokens(overrideDb: database)).single;
    expect(restoredToken.id, existingToken.id);
    expect(restoredToken.uid, 'local-token');
    expect(restoredToken.seq, 7);
    expect(restoredToken.tokenType, OtpTokenType.HOTP);
    expect(restoredToken.algorithm, OtpAlgorithm.SHA256);
    expect(restoredToken.digits, OtpDigits.D8);
    expect(restoredToken.counterString, '42');
    expect(restoredToken.periodString, '60');
    expect(restoredToken.description, 'backup description');
    expect(restoredToken.remark, {'source': 'backup'});
    expect(restoredToken.tags, ['backup']);

    final restoredCategory =
        (await CategoryDao.listCategories(overrideDb: database)).single;
    expect(restoredCategory.id, existingCategory.id);
    expect(restoredCategory.uid, 'local-category');
    expect(restoredCategory.seq, 4);
    expect(restoredCategory.description, 'backup category');
    expect(restoredCategory.remark, {'source': 'backup'});
    final bindings = await database.query('token_category_binding');
    expect(bindings, [
      {
        'token_uid': 'local-token',
        'category_uid': 'local-category',
      }
    ]);
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
