package com.cloudchewie.ui.bottombar

import android.graphics.drawable.Drawable
import androidx.annotation.ColorInt
import com.cloudchewie.ui.bottombar.ReadableBottomBar.ItemType

data class BottomBarItem(
        val index: Int,
        val text: String,
        val textSize: Float,
        @ColorInt val textColor: Int,
        @ColorInt val iconColor: Int,
        val drawable: Drawable,
        val type: ItemType
)