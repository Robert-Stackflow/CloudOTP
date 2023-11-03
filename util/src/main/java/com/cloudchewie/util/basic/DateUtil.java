/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/18 13:14:23
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.util.basic;

import android.content.Context;

import androidx.annotation.NonNull;

import com.cloudchewie.util.R;

import org.jetbrains.annotations.Contract;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

/**
 * 时间工具类
 */
public class DateUtil {
    private static final TimeZone timeZone = TimeZone.getTimeZone("GMT+8");

    @NonNull
    public static String beautifyTime(@NonNull Date date, Context context) {
        Date curDate = getNow();
        Date today = getStartOfToDay();
        Date yesterday = getYesterday();
        Date dayBeforeYesterday = getDayBeforeYesterday();
        long interval = (curDate.getTime() - date.getTime()) / 1000;
        SimpleDateFormat ymdFormat = DateFormatUtil.getSimpleDateFormat(DateFormatUtil.YMD_FORMAT_WITH_CHARACTERS);
        SimpleDateFormat mdFormat = DateFormatUtil.getSimpleDateFormat(DateFormatUtil.MD_FORMAT_WITH_CHARACTERS);
        SimpleDateFormat hmFormat = DateFormatUtil.getSimpleDateFormat(DateFormatUtil.HM_FORMAT);
        if (interval < 3) return context.getString(R.string.right_now);
        else if (interval < 60) return interval + context.getString(R.string.second_before);
        else if (date.after(today)) return hmFormat.format(date);
        else if (date.before(today) && date.after(yesterday)) return context.getString(R.string.yesterday);
        else if (date.before(today) && date.before(yesterday) && date.after(dayBeforeYesterday))
            return context.getString(R.string.day_before_yesterday);
        else if (getYear(date) != getYear(curDate)) return ymdFormat.format(date);
        else return mdFormat.format(date);
    }

    @NonNull
    public static Date getYesterday() {
        return getStartOfDay(new Date(System.currentTimeMillis() - 1000 * 60 * 60 * 24));
    }

    @NonNull
    public static Date getDayBeforeYesterday() {
        return getStartOfDay(new Date(System.currentTimeMillis() - 1000 * 60 * 60 * 24 * 2));
    }

    @NonNull
    @Contract(" -> new")
    public static Date getNow() {
        return new Date(System.currentTimeMillis());
    }

    public static int getYear() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.YEAR);
    }

    public static int getYear(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.setTime(date);
        return cd.get(Calendar.YEAR);
    }

    public static int getMonth() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.MONTH) + 1;
    }

    public static int getMonth(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.setTime(date);
        return cd.get(Calendar.MONTH) + 1;
    }

    public static int getDay() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.DATE);
    }

    public static int getDay(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.setTime(date);
        return cd.get(Calendar.DATE);
    }

    public static int getDayOfWeek(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.setTime(date);
        return (cd.get(Calendar.DAY_OF_WEEK) + 5) % 7;
    }

    public static int getDayOfWeek() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.DAY_OF_WEEK);
    }

    public static int getHour() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.HOUR);
    }

    public static int getHour(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        cd.setTime(date);
        return cd.get(Calendar.HOUR);
    }

    public static int getMinute() {
        Calendar cd = Calendar.getInstance();
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.MINUTE);
    }

    public static int getMinute(Date date) {
        Calendar cd = Calendar.getInstance();
        cd.setTime(date);
        cd.setTimeZone(timeZone);
        return cd.get(Calendar.MINUTE);
    }

    @NonNull
    public static Date getStartOfToDay() {
        return getStartOfDay(new Date(System.currentTimeMillis()));
    }

    @NonNull
    public static Date getStartOfDay(Date time) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        calendar.setTime(time);
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTime();
    }

    @NonNull
    public static Date getEndOfDay(Date time) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        calendar.setTime(time);
        calendar.set(Calendar.HOUR_OF_DAY, 23);
        calendar.set(Calendar.MINUTE, 59);
        calendar.set(Calendar.SECOND, 59);
        calendar.set(Calendar.MILLISECOND, 999);
        return calendar.getTime();
    }

    public static int getIntervalDayOfDate(Date date1, Date date2) {
        try {
            long startTime, endTime;
            if (date1.before(date2)) {
                startTime = date1.getTime();
                endTime = date2.getTime();
            } else {
                startTime = date2.getTime();
                endTime = date1.getTime();
            }
            return (int) ((endTime - startTime) / (1000 * 60 * 60 * 24));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public static int getIntervalMinuteOfDate(Date date1, Date date2) {
        try {
            long startTime, endTime;
            startTime = date1.getTime();
            endTime = date2.getTime();
            return (int) ((endTime - startTime) / (1000 * 60));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
}
