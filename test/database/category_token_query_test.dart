import 'dart:convert';

import 'package:cloudotp/Database/create_table_sql.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(Sql.createTokenTable.sql);
    await database.execute(Sql.createTokenCategoryBindingTable.sql);
  });

  tearDown(() => database.close());

  test('category query loads matching tokens with one joined query', () async {
    await database.insert('otp_token', _token('token-a', 2, 'first@example'));
    await database.insert('otp_token', _token('token-b', 1, 'second@example'));
    await database.insert('token_category_binding', {
      'token_uid': 'token-a',
      'category_uid': 'category-a',
    });
    await database.insert('token_category_binding', {
      'token_uid': 'token-b',
      'category_uid': 'category-b',
    });

    final tokens = await TokenDao.listTokensByCategoryUid(
      'category-a',
      searchKey: 'first',
      overrideDb: database,
    );

    expect(tokens.map((token) => token.uid), ['token-a']);
    expect(await TokenDao.getTokenCount(overrideDb: database), 2);
  });
}

Map<String, Object> _token(String uid, int seq, String account) => {
      'uid': uid,
      'seq': seq,
      'issuer': 'Issuer',
      'secret': 'JBSWY3DPEHPK3PXP',
      'account': account,
      'image_path': '',
      'token_type': 0,
      'algorithm': 'SHA1',
      'digits': 6,
      'counter': 0,
      'period': 30,
      'pinned': 0,
      'create_timestamp': 1,
      'edit_timestamp': 1,
      'remark': jsonEncode(<String, Object>{}),
      'copy_times': 0,
      'last_copy_timestamp': 0,
      'pin': '',
      'description': '',
      'tags': '',
    };
