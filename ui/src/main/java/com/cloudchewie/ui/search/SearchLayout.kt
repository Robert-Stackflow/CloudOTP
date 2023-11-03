/*
 * Project Name: Worthy
 * Author: Ruida
 * Last Modified: 2022/12/17 21:46:02
 * Copyright(c) 2022 Ruida https://cloudchewie.com
 */

package com.cloudchewie.ui.search

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.drawable.Drawable
import android.os.Build
import android.text.Editable
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.TypedValue
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.*
import androidx.core.content.ContextCompat
import com.cloudchewie.ui.R

class SearchLayout : LinearLayout {
    private var mLayoutSearch: RelativeLayout? = null
    private var mSearchBg: Drawable? = null
    private var mSearchBgtint: Int? = null
    private var mSearchIconDeleteRight: Float = 0f
    private var mSearchIconLeft: Float = 0f
    private var mIvSearch: ImageView? = null
    private var mSearchColor: Int = 0
    private var mIvDelete: ImageView? = null
    private var mEtContent: EditText? = null
    private var mSearchIcon: Drawable? = null
    private var mSearchIconWidth: Float = 0f
    private var mSearchIconHeight: Float = 0f
    private var mSearchIconDelete: Drawable? = null
    private var mSearchIconDeleteWidth: Float = 0f
    private var mSearchIconDeleteHeight: Float = 0f
    private var mSearchHint: String? = null
    private var mSearchSize: Float = 0f
    private var mSearchHintColor: Int = 0
    private var mSearchTextCursorDrawable: Drawable? = null

    constructor(
        context: Context
    ) : super(context) {
        init(context)
    }

    constructor(
        context: Context,
        attrs: AttributeSet?
    ) : super(context, attrs) {
        val os = context.obtainStyledAttributes(attrs, R.styleable.SearchLayout)
        //搜索图标
        mSearchIcon = os.getDrawable(R.styleable.SearchLayout_search_icon)
        //搜索背景
        mSearchBg = os.getDrawable(R.styleable.SearchLayout_search_bg)
        mSearchBgtint = os.getColor(
            R.styleable.SearchLayout_search_bg_tint,
            ContextCompat.getColor(context, R.color.tag_background)
        )
        //搜索框光标
        mSearchTextCursorDrawable = os.getDrawable(R.styleable.SearchLayout_search_text_cursor)
        //搜索图标宽
        mSearchIconWidth = os.getDimension(R.styleable.SearchLayout_search_icon_width, 0f)
        //搜索图标高
        mSearchIconHeight = os.getDimension(R.styleable.SearchLayout_search_icon_height, 0f)
        //搜索删除图标
        mSearchIconDelete = os.getDrawable(R.styleable.SearchLayout_search_icon_delete)
        //搜索删除图标宽
        mSearchIconDeleteWidth =
            os.getDimension(R.styleable.SearchLayout_search_icon_delete_width, 0f)
        //搜索删除图标高
        mSearchIconDeleteHeight =
            os.getDimension(R.styleable.SearchLayout_search_icon_delete_height, 0f)
        //搜索图标距离左边的距离
        mSearchIconLeft =
            os.getDimension(R.styleable.SearchLayout_search_icon_left, 0f)
        //搜索删除图标距离右边的距离
        mSearchIconDeleteRight =
            os.getDimension(R.styleable.SearchLayout_search_icon_delete_right, 0f)
        //搜索框占位字符
        mSearchHint = os.getString(R.styleable.SearchLayout_search_hint)
        //搜索框文字颜色
        mSearchColor =
            os.getColor(R.styleable.SearchLayout_search_color, 0)
        //搜索框占位字符颜色
        mSearchHintColor =
            os.getColor(R.styleable.SearchLayout_search_hint_color, 0)
        //搜索框文字大小
        mSearchSize =
            os.getDimensionPixelSize(R.styleable.SearchLayout_search_size, 0).toFloat()
        init(context)
        os.recycle()
    }

    private fun init(context: Context) {
        //搜索框 xml
        val view = View.inflate(context, R.layout.search_layout, null)
        mLayoutSearch = view.findViewById(R.id.layout_search)
        mIvSearch = view.findViewById(R.id.view_iv_search)
        mEtContent = view.findViewById(R.id.view_et_content)
        mIvDelete = view.findViewById(R.id.view_iv_delete)
        mIvDelete!!.setOnClickListener {
            mEtContent!!.setText("")
        }
        create()
        addView(view)
    }


    /**
     * AUTHOR:AbnerMing
     * INTRODUCE:初始化
     */
    private fun create() {
        try {

            mEtContent?.apply {
                //设置占位字符
                mSearchHint?.let {
                    hint = mSearchHint
                }
                //设置文字大小
                if (mSearchSize != 0f) {
                    mEtContent!!.setTextSize(TypedValue.COMPLEX_UNIT_PX, mSearchSize)
                }
                //设置文字颜色
                if (mSearchColor != 0) {
                    setTextColor(mSearchColor)
                }
                //设置占位字符颜色
                if (mSearchHintColor != 0) {
                    setHintTextColor(mSearchHintColor)
                }
                //设置搜索框光标
                mSearchTextCursorDrawable?.let {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        textCursorDrawable = mSearchTextCursorDrawable
                    }

                }
            }

            mIvSearch?.apply {
                //设置搜索图标
                mSearchIcon?.let {
                    setImageDrawable(it)
                }
                val params = mIvSearch!!.layoutParams as RelativeLayout.LayoutParams
                //设置搜索图标的宽
                if (mSearchIconWidth != 0f) {
                    params.width = mSearchIconWidth.toInt()
                }
                //设置搜索图标的高
                if (mSearchIconHeight != 0f) {
                    params.height = mSearchIconWidth.toInt()
                }
                //设置搜索图标距离左边的距离
                if (mSearchIconLeft != 0f) {
                    params.leftMargin = mSearchIconLeft.toInt()
                }
                layoutParams = params
            }

            mIvDelete?.apply {
                //设置删除图标
                mSearchIconDelete?.let {
                    setImageDrawable(it)
                }
                val params = mIvDelete!!.layoutParams as RelativeLayout.LayoutParams
                //设置删除图标的宽
                if (mSearchIconDeleteWidth != 0f) {
                    params.width = mSearchIconDeleteWidth.toInt()
                }
                //设置删除的高
                if (mSearchIconDeleteHeight != 0f) {
                    params.height = mSearchIconDeleteHeight.toInt()
                }
                //设置删除图标距离右边的距离
                if (mSearchIconDeleteRight != 0f) {
                    params.rightMargin = mSearchIconDeleteRight.toInt()
                }
                layoutParams = params
            }

            //监听输入框
            mEtContent!!.addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(p0: CharSequence?, p1: Int, p2: Int, p3: Int) {

                }

                override fun onTextChanged(p0: CharSequence?, p1: Int, p2: Int, p3: Int) {
                    //有内容就展示删除图标
                    if (p0.isNullOrEmpty()) {
                        mIvDelete!!.visibility = GONE
                    } else {
                        mIvDelete!!.visibility = VISIBLE
                    }
                    //监听输入框改变的内容
                    mOnTextSearchListener?.let {
                        mOnTextSearchListener!!.textChanged(p0.toString())
                    }
                }

                override fun afterTextChanged(p0: Editable?) {

                }

            })

            //软键盘点击搜索
            mEtContent!!.setOnEditorActionListener(object : TextView.OnEditorActionListener {
                override fun onEditorAction(p0: TextView?, p1: Int, p2: KeyEvent?): Boolean {
                    if (p1 == EditorInfo.IME_ACTION_SEARCH) {
                        mOnTextSearchListener?.let {
                            mOnTextSearchListener!!.clickSearch(p0!!.text.toString())
                        }
                        return true
                    }
                    return false
                }

            })

            //设置搜索框的背景
            if (mSearchBg != null) {
                mLayoutSearch?.background = mSearchBg
                mLayoutSearch?.backgroundTintList =
                    mSearchBgtint?.let { ColorStateList.valueOf(it) }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * AUTHOR:AbnerMing
     * INTRODUCE:获取EditText自己去做处理
     */
    fun getSearchEdit(): EditText {
        return mEtContent!!
    }

    /**
     * AUTHOR:AbnerMing
     * INTRODUCE:搜索框监听文字改变和软键盘点击搜索
     */
    private var mOnTextSearchListener: OnTextSearchListener? = null
    fun setOnTextSearchListener(change: (String) -> Unit, search: (String) -> Unit) {
        mOnTextSearchListener = object : OnTextSearchListener {
            override fun textChanged(content: String) {
                change(content)
            }

            override fun clickSearch(content: String) {
                search(content)
            }

        }
    }
}