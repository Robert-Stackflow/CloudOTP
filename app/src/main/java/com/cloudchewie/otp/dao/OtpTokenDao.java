package com.cloudchewie.otp.dao;

import android.util.Pair;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.RawQuery;
import androidx.room.Transaction;
import androidx.room.Update;
import androidx.sqlite.db.SimpleSQLiteQuery;
import androidx.sqlite.db.SupportSQLiteQuery;

import com.cloudchewie.otp.entity.OtpToken;

import java.util.List;

@Dao
public interface OtpTokenDao {

    @Query("select * from otp_tokens order by ordinal")
    List<OtpToken> getAll();

    @Query("select count(*) from otp_tokens")
    int count();

    @Query("select * from otp_tokens where id = :id")
    OtpToken get(Long id);

    @Query("select * from otp_tokens where issuer=:issuer and account=:account")
    OtpToken get(String issuer, String account);

    @Query("select ordinal from otp_tokens order by ordinal desc limit 1")
    Long getLastOrdinal();

    @Query("delete from otp_tokens where id = :id")
    void deleteById(Long id);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertAll(List<OtpToken> otpTokenList);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insert(OtpToken otpToken);

    @Update
    void update(OtpToken otpToken);

    @Query("update otp_tokens set ordinal = :ordinal where id = :id")
    void updateOrdinal(Long id, Long ordinal);

    default void incrementCounter(Long id) {
        incrementCounterRaw(new SimpleSQLiteQuery("update otp_tokens set counter = counter + 1 where id = ?", new Long[]{id}));
    }

    @RawQuery
    Integer incrementCounterRaw(SupportSQLiteQuery query);

    @Transaction
    default void movePairs(List<Pair<Long, Long>> pairs) {
        for (Pair<Long, Long> pair : pairs) {
            OtpToken token1 = get(pair.first);
            OtpToken token2 = get(pair.second);
            if (token1 == null || token2 == null) {
                return;
            }
            updateOrdinal(pair.first, token2.getOrdinal());
            updateOrdinal(pair.second, token1.getOrdinal());
        }
    }
}