/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:46:02
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.search

interface OnTextSearchListener {
    fun textChanged(content: String)
    fun clickSearch(content: String)
}