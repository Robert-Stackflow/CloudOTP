enum Sql {
  createTokenTable(
    '''
      CREATE TABLE otp_token (
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
        create_timestamp INTEGER NOT NULL,
        edit_timestamp INTEGER NOT NULL,
        remark TEXT NOT NULL,
        copy_times INTEGER NOT NULL,
        last_copy_timestamp INTEGER NOT NULL,
        pin TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      );
    ''',
  ),
  createCategoryTable('''
      CREATE TABLE token_category (
        id INTEGER PRIMARY KEY,
        seq INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        create_timestamp INTEGER NOT NULL,
        edit_timestamp INTEGER NOT NULL,
        pinned INTEGER NOT NULL,
        token_ids TEXT NOT NULL,
        remark TEXT NOT NULL
      );
    '''),
  createConfigTable('''
      CREATE TABLE cloudotp_config (
        id INTEGER PRIMARY KEY,
        backup_password TEXT NOT NULL,
        remark TEXT NOT NULL
      );
    '''),
  createCloudServiceConfigTable('''
      CREATE TABLE cloud_service_config (
        id INTEGER PRIMARY KEY,
        type INTEGER NOT NULL,
        endpoint TEXT,
        account TEXT,
        secret TEXT,
        token TEXT,
        create_timestamp INTEGER NOT NULL,
        edit_timestamp INTEGER NOT NULL,
        last_fetch_timestamp INTEGER NOT NULL,
        last_backup_timestamp INTEGER NOT NULL,
        remark TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      );
    '''),
  createAutoBackupLogTable('''
      CREATE TABLE auto_update_log (
        id INTEGER PRIMARY KEY,
        start_timestamp INTEGER NOT NULL,
        end_timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        type INTEGER NOT NULL,
        trigger_type INTEGER NOT NULL,
        cloud_service_type INTEGER,
        backup_path TEXT NOT NULL
      );
    ''');

  const Sql(this.sql);

  final String sql;
}
