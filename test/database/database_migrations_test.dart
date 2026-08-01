import 'package:cloudotp/Database/database_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('''
      CREATE TABLE otp_token (uid TEXT NOT NULL)
    ''');
    await database.execute('''
      CREATE TABLE token_category (uid TEXT NOT NULL)
    ''');
    await database.execute('''
      CREATE TABLE cloud_service_config (type INTEGER NOT NULL)
    ''');
    await database.execute('''
      CREATE TABLE auto_update_log (start_timestamp INTEGER NOT NULL)
    ''');
    await database.execute('''
      CREATE TABLE token_category_binding (
        token_uid INTEGER NOT NULL,
        category_uid INTEGER NOT NULL,
        UNIQUE(token_uid, category_uid)
      )
    ''');
  });

  tearDown(() => database.close());

  test('v9 migration preserves every binding and changes UID columns to TEXT',
      () async {
    const bindings = [
      {'token_uid': 'token-001', 'category_uid': 'category-a'},
      {'token_uid': '90210', 'category_uid': '17'},
      {'token_uid': '令牌-三', 'category_uid': '分类-三'},
    ];
    for (final binding in bindings) {
      await database.insert('token_category_binding', binding);
    }

    await database.transaction(DatabaseMigrations.upgradeToV9);

    final columns = await database.rawQuery(
      'PRAGMA table_info(token_category_binding)',
    );
    expect(
      columns
          .where((column) =>
              column['name'] == 'token_uid' || column['name'] == 'category_uid')
          .map((column) => column['type']),
      everyElement('TEXT'),
    );
    expect(
      await database.query(
        'token_category_binding',
        orderBy: 'token_uid',
      ),
      bindings.toList()
        ..sort(
          (a, b) => a['token_uid']!.compareTo(b['token_uid']!),
        ),
    );

    final indexes = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    final indexNames = indexes.map((row) => row['name']).toSet();
    expect(indexNames, contains('idx_binding_token_uid'));
    expect(indexNames, contains('idx_binding_category_uid'));
  });
}
