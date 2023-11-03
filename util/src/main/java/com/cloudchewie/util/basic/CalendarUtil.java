/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/19 14:53:18
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.util.basic;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Calendar;
import java.util.TimeZone;

/**
 * 日期工具类
 */
public class CalendarUtil {
    private static final TimeZone timeZone = TimeZone.getTimeZone("GMT+8");

    @NonNull
    public static com.haibin.calendarview.Calendar getNowCalendar() {
        Calendar javaCalendar = Calendar.getInstance();
        return getJavaCalendar(javaCalendar.get(Calendar.YEAR), javaCalendar.get(Calendar.MONTH), javaCalendar.get(Calendar.DATE));
    }

    @NonNull
    public static com.haibin.calendarview.Calendar getJavaCalendar(int year, int month, int day) {
        com.haibin.calendarview.Calendar calendar = new com.haibin.calendarview.Calendar();
        calendar.setDay(day);
        calendar.setMonth(month);
        calendar.setYear(year);
        return calendar;
    }

    @NonNull
    public static Calendar parseToJavaCalendar(@NonNull com.haibin.calendarview.Calendar calendar) {
        Calendar javaCalendar = Calendar.getInstance();
        javaCalendar.setTimeZone(timeZone);
        javaCalendar.set(calendar.getYear(), calendar.getMonth() - 1, calendar.getDay());
        return javaCalendar;
    }

    @NonNull
    public static Calendar parseToJavaCalendar(int year, int month, int day) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        calendar.set(year, month, day);
        return calendar;
    }

    @Nullable
    public static Calendar parseToJavaCalendar(@NonNull String value) {
        String[] strings = value.split("-");
        return value == null ? null : parseToJavaCalendar(strings[0], strings[1], strings[2]);
    }

    @NonNull
    public static Calendar parseToJavaCalendar(String year, String month, String day) {
        return parseToJavaCalendar(Integer.parseInt(year), Integer.parseInt(month), Integer.parseInt(day));
    }

    @NonNull
    public static String calendarToString(@NonNull Calendar calendar) {
        return String.valueOf(calendar.get(Calendar.YEAR)) + '-' + (calendar.get(Calendar.MONTH)) + '-' + calendar.get(Calendar.DATE);
    }

    @NonNull
    public static com.haibin.calendarview.Calendar getSchemeCalendar(int year, int month, int day, int color, String text) {
        com.haibin.calendarview.Calendar calendar = new com.haibin.calendarview.Calendar();
        calendar.setYear(year);
        calendar.setMonth(month);
        calendar.setDay(day);
        calendar.setSchemeColor(color);
        calendar.setScheme(text);
        return calendar;
    }

    @NonNull
    public static com.haibin.calendarview.Calendar getSchemeCalendar(@NonNull Calendar javaCalendar, int color, String text) {
        return getSchemeCalendar(javaCalendar.get(Calendar.YEAR), javaCalendar.get(Calendar.MONTH), javaCalendar.get(Calendar.DATE), color, text);
    }

    @NonNull
    public static Calendar getJavaCalendar() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.set(Calendar.MONTH, cd.get(Calendar.MONTH) + 1);
        return cd;
    }
}
