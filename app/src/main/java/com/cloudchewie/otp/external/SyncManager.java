package com.cloudchewie.otp.external;

import android.content.Context;

import com.cloudchewie.otp.entity.SyncConfig;
import com.cloudchewie.otp.database.LocalStorage;

public class SyncManager {
    private Context mContext;

    public SyncManager(Context aContext) {
        this.mContext = aContext;
    }

    public boolean haveToken(SyncService syncService) {
        return getToken(syncService) != null;
    }

    public String getToken(SyncService syncService) {
        return LocalStorage.getAppDatabase().syncConfigDao().getAccessToken(syncService.getKey());
    }

    public Long getLastPushed(SyncService syncService) {
        return LocalStorage.getAppDatabase().syncConfigDao().getLastPushed(syncService.getKey());
    }

    public void update(SyncConfig syncConfig) {
        LocalStorage.getAppDatabase().syncConfigDao().update(syncConfig);
    }

    public void delete(SyncService syncService) {
        LocalStorage.getAppDatabase().syncConfigDao().deleteByName(syncService.getKey());
    }
}
