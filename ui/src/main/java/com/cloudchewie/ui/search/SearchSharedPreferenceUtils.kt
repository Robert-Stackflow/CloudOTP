/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:46:02
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.search

import android.content.Context
import android.content.SharedPreferences

object SearchSharedPreferenceUtils {
    private const val PREFERENCES = "search"
    private var preferencesSharedPreferences: SharedPreferences? = null
    fun put(context: Context, key: String?, value: String?) {
        val preferences = getPreferences(context)
        preferences!!.edit().putString(key, value).apply()
    }

    private fun getPreferences(context: Context): SharedPreferences? {
        if (preferencesSharedPreferences == null) {
            preferencesSharedPreferences = context.getSharedPreferences(PREFERENCES, 0)
        }
        return preferencesSharedPreferences
    }

    fun getString(context: Context, key: String?): String? {
        return getString(context, key, "")
    }

    private fun getString(context: Context, key: String?, defaultVal: String?): String? {
        return getPreferences(context)!!.getString(key, defaultVal)
    }

}