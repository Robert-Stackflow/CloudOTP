package com.cloudchewie.otp.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.Update;

import com.cloudchewie.otp.entity.Privacy;

@Dao
public interface PrivacyDao {
    @Query("select * from privacy")
    Privacy get();

    @Query("select secret from privacy")
    String getSecret();

    @Query("select passcode from privacy")
    String getPasscode();

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insert(Privacy privacy);

    @Update
    void update(Privacy privacy);
}
