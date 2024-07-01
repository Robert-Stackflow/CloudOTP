package com.cloudchewie.otp.util;

import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;

public class GithubUtil {
    private static final OkHttpClient client = new OkHttpClient();

    public static void getReleases(String user, String repo, Callback callback) {
        Request request = new Request.Builder()
                .url("https://api.github.com/repos/" + user + "/" + repo + "/releases")
                .build();
        client.newCall(request).enqueue(callback
        );
    }
}
