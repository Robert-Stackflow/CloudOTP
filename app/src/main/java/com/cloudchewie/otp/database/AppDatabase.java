/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:14:24
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.database;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;
import androidx.room.TypeConverters;
import androidx.room.migration.Migration;
import androidx.sqlite.db.SupportSQLiteDatabase;

import com.cloudchewie.otp.dao.OtpTokenDao;
import com.cloudchewie.otp.dao.PrivacyDao;
import com.cloudchewie.otp.dao.SyncConfigDao;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.entity.Privacy;
import com.cloudchewie.otp.entity.SyncConfig;

@Database(entities = {OtpToken.class, SyncConfig.class, Privacy.class}, version = 4)
@TypeConverters(Converters.class)
public abstract class AppDatabase extends RoomDatabase {
    private static final String DB_NAME = "cloudchewie.db";
    private static volatile AppDatabase instance;

    private static Migration migration_1_2 = new Migration(1, 2) {
        @Override
        public void migrate(@NonNull SupportSQLiteDatabase database) {
            database.execSQL("CREATE TABLE IF NOT EXISTS sync_config (`name` TEXT NOT NULL, `accessToken` TEXT, `lastPushed` INTEGER, PRIMARY KEY(`name`))");
            database.execSQL("CREATE TABLE IF NOT EXISTS privacy (`id` INTEGER, `passcode` TEXT, `secret` TEXT, PRIMARY KEY(`id`))");
        }
    };
    private static Migration migration_2_3 = new Migration(2, 3) {
        @Override
        public void migrate(@NonNull SupportSQLiteDatabase database) {
            database.execSQL("ALTER TABLE privacy ADD COLUMN `verified` INTEGER");
        }
    };
    private static Migration migration_3_4 = new Migration(3, 4) {
        @Override
        public void migrate(@NonNull SupportSQLiteDatabase database) {
            database.execSQL("ALTER TABLE otp_tokens ADD COLUMN `pinned` INTEGER NOT NULL DEFAULT 0");
        }
    };

    public static synchronized AppDatabase getInstance(Context context) {
        if (instance == null) {
            instance = create(context);
        }
        return instance;
    }

    @NonNull
    private static AppDatabase create(final Context context) {
        return Room.databaseBuilder(context, AppDatabase.class, DB_NAME).addMigrations(migration_1_2, migration_2_3, migration_3_4).allowMainThreadQueries().build();
    }

    public abstract OtpTokenDao otpTokenDao();

    public abstract SyncConfigDao syncConfigDao();

    public abstract PrivacyDao privacyDao();
}