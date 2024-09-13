/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

enum Sql {
  createTokenTable(
    '''
      CREATE TABLE otp_token (
        id INTEGER PRIMARY KEY,
        uid TEXT NOT NULL DEFAULT '',
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
        uid TEXT NOT NULL DEFAULT '',
        seq INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        create_timestamp INTEGER NOT NULL,
        edit_timestamp INTEGER NOT NULL,
        pinned INTEGER NOT NULL,
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
        enabled INTEGER NOT NULL DEFAULT 1,
        total_size INTEGER NOT NULL DEFAULT -1,
        remaining_size INTEGER NOT NULL DEFAULT -1,
        used_size INTEGER NOT NULL DEFAULT -1,
        configured INTEGER NOT NULL DEFAULT 0,
        email TEXT NOT NULL DEFAULT ''
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
    '''),
  createTokenCategoryBindingTable('''
      CREATE TABLE token_category_binding (
        token_uid INTEGER NOT NULL,
        category_uid INTEGER NOT NULL
      );
    ''');

  const Sql(this.sql);

  final String sql;
}
