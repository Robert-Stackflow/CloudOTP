enum Sql {
  createTokenTable(
    '''
      CREATE TABLE token (
        id INTEGER PRIMARY KEY,
        seq INTEGER NOT NULL,
        issuer TEXT NOT NULL,
        secret TEXT NOT NULL,
        account TEXT NOT NULL,
        image_path TEXT NOT NULL,
        token_type INTEGER NOT NULL,
        algorithm TEXT NOT NULL,
        digits INTEGER NOT NULL,
        counter INTEGER NOT NULL,
        period INTEGER NOT NULL,
        pinned INTEGER NOT NULL,
        create_time_stamp INTEGER NOT NULL,
        edit_time_stamp INTEGER NOT NULL,
        remark TEXT NOT NULL,
        copy_times INTEGER NOT NULL,
        last_copy_time_stamp INTEGER NOT NULL,
        pin TEXT NOT NULL
      );
    ''',
  ),
  createCategoryTable('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY,
        seq INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        create_time_stamp INTEGER NOT NULL,
        edit_time_stamp INTEGER NOT NULL,
        pinned INTEGER NOT NULL,
        token_ids TEXT NOT NULL,
        remark TEXT NOT NULL
      );
    ''');

  const Sql(this.sql);

  final String sql;
}
