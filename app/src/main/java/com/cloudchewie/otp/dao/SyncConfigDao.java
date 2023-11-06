package com.cloudchewie.otp.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.Update;

import com.cloudchewie.otp.entity.SyncConfig;

@Dao
public interface SyncConfigDao {

    @Query("select * from sync_config where name = :name")
    SyncConfig get(String name);

    @Query("select lastPushed from sync_config where name = :name")
    Long getLastPushed(String name);

    @Query("select accessToken from sync_config where name = :name")
    String getAccessToken(String name);

    @Query("delete from sync_config where name = :name")
    void deleteByName(String name);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insert(SyncConfig syncConfig);

    @Update
    void update(SyncConfig syncConfig);
}
