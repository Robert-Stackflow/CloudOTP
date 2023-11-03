package com.cloudchewie.util.system;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkInfo;

import androidx.annotation.NonNull;

public class NetWorkUtil {
    @NonNull
    public static String checkNetWork(@NonNull Context context) {
        ConnectivityManager connMgr = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        Network[] networks = connMgr.getAllNetworks();
        StringBuilder stringBuilder = new StringBuilder();
        for (Network network : networks) {
            NetworkInfo networkInfo = connMgr.getNetworkInfo(network);
            stringBuilder.append(networkInfo.getTypeName()).append(" connect is ").append(networkInfo.isConnected());
        }
        return stringBuilder.toString();
    }
}
