/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/19 14:26:23
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.otp.database;

import androidx.annotation.NonNull;
import androidx.room.TypeConverter;

import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

public class Converters {
    @TypeConverter
    public static Date fromTimestamp(Long value) {
        return value == null ? null : new Date(value);
    }

    @TypeConverter
    public static Long dateToTimestamp(Date date) {
        return date == null ? null : date.getTime();
    }

    @NonNull
    @TypeConverter
    public static String stringListTo(List<String> strings) {
        return new Gson().toJson(strings.toArray());
    }

    @NonNull
    @TypeConverter
    public static List<String> toStringList(String json) {
        return new ArrayList<>(Arrays.asList(new Gson().fromJson(json, String[].class)));
    }

    @NonNull
    @TypeConverter
    public static String booleanListTo(List<Boolean> booleans) {
        return new Gson().toJson(booleans.toArray());
    }

    @NonNull
    @TypeConverter
    public static List<Boolean> toBooleanList(String json) {
        return new ArrayList<>(Arrays.asList(new Gson().fromJson(json, Boolean[].class)));
    }
}
