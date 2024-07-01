package com.cloudchewie.otp.widget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.view.animation.AnimationUtils
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.core.content.ContextCompat.startActivity
import com.cloudchewie.otp.R
import com.cloudchewie.otp.activity.TokenDetailActivity
import com.cloudchewie.otp.database.AppSharedPreferenceUtil
import com.cloudchewie.otp.entity.OtpToken
import com.cloudchewie.otp.entity.TokenCode
import com.cloudchewie.otp.util.authenticator.OtpTokenParser
import com.cloudchewie.otp.util.authenticator.TokenImageUtil
import com.cloudchewie.otp.util.enumeration.OtpTokenType
import com.cloudchewie.ui.custom.ImageDialog
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter

class TokenLayout : RelativeLayout, View.OnClickListener, Runnable {
    private val tag = TokenLayout::class.java.simpleName
    private lateinit var mProgressInner: ProgressCircle
    private lateinit var mProgressOuter: ProgressCircle

    private lateinit var mImage: ImageView
    private lateinit var mCode: TextView
    private lateinit var mNextCode: TextView
    private lateinit var mIssuer: TextView
    private lateinit var mAccount: TextView
    private lateinit var mDetail: ImageView
    private lateinit var mQrcode: ImageView
    private lateinit var mHandle: ImageView
    private lateinit var mSelect: ImageView

    private lateinit var mToken: OtpToken
    private var mCodes: TokenCode? = null
    private var mType: OtpTokenType? = null
    private var mPlaceholder: String? = null
    private var mStartTime: Long = 0

    private var inSelectionMode: Boolean = false
    var onSelectStateChangeListener: OnSelectStateChangeListener? = null

    interface OnSelectStateChangeListener {
        fun onSelectedChanged(token: OtpToken)
    }

    constructor(context: Context) : super(context)

    constructor(context: Context, attrs: AttributeSet) : super(context, attrs)

    constructor(context: Context, attrs: AttributeSet, defStyle: Int) : super(
        context, attrs, defStyle
    )

    override fun onFinishInflate() {
        super.onFinishInflate()
        mProgressInner = findViewById<View>(R.id.item_token_progress_inner) as ProgressCircle
        mProgressOuter = findViewById<View>(R.id.item_token_progress_outer) as ProgressCircle
        mImage = findViewById<View>(R.id.item_token_image) as ImageView
        mCode = findViewById<View>(R.id.item_token_code) as TextView
        mNextCode = findViewById<View>(R.id.item_next_token_code) as TextView
        mIssuer = findViewById<View>(R.id.item_token_issuer) as TextView
        mAccount = findViewById<View>(R.id.item_token_account) as TextView
        mDetail = findViewById<View>(R.id.item_token_detail) as ImageView
        mQrcode = findViewById<View>(R.id.item_token_qrcode) as ImageView
        mSelect = findViewById<View>(R.id.item_token_select) as ImageView
        mHandle = findViewById<View>(R.id.item_token_handle) as ImageView
        if (AppSharedPreferenceUtil.isShowNext(context)) {
            mNextCode.visibility = VISIBLE
        } else {
            mNextCode.visibility = GONE
        }
        setSelectionMode(false)
    }

    fun setSelectionMode(inSelectionMode: Boolean) {
        this.inSelectionMode = inSelectionMode
        if (inSelectionMode) {
//            mHandle.visibility = VISIBLE
            mSelect.visibility = VISIBLE
            mQrcode.visibility = GONE
            mDetail.visibility = GONE
        } else {
            mHandle.visibility = GONE
            mSelect.visibility = GONE
            mQrcode.visibility = VISIBLE
            mDetail.visibility = VISIBLE
        }
    }

    fun toggleSelected() {
        if (inSelectionMode) {
            this.mToken.isSelected = !this.mToken.isSelected
            if (this.mToken.isSelected) mSelect.setImageResource(R.drawable.ic_material_checkbox_checked)
            else mSelect.setImageResource(R.drawable.ic_material_checkbox_unchecked)
            if (onSelectStateChangeListener != null) onSelectStateChangeListener!!.onSelectedChanged(
                this.mToken
            )
        }
    }

    fun bind(token: OtpToken) {
        this.mToken = token
        mCodes = null

        // Cancel all active animations.
        isEnabled = true
        removeCallbacks(this)
        mImage.clearAnimation()
        mProgressInner.clearAnimation()
        mProgressOuter.clearAnimation()
        mProgressInner.visibility = View.GONE
        mProgressOuter.visibility = View.GONE

        // Get the code placeholder.
        val placeholder = CharArray(token.digits)
        for (i in placeholder.indices) placeholder[i] = '*'
        mPlaceholder = String(placeholder)

        // Show the image.
        TokenImageUtil.setTokenImage(mImage, token)

        mAccount.text = token.account
        mIssuer.text = token.issuer
        mCode.text = mPlaceholder
        mNextCode.text = mPlaceholder
        if (mIssuer.text.isEmpty()) {
            mIssuer.text = token.account
            mAccount.visibility = View.GONE
        } else {
            mAccount.visibility = View.VISIBLE
        }

        mDetail.setOnClickListener {
            val intent = Intent(
                context, TokenDetailActivity::class.java
            ).setAction(Intent.ACTION_DEFAULT)
            intent.putExtra(TokenDetailActivity.EXTRA_TOKEN_ID, token.id)
            startActivity(context, intent, null)
        }
        mQrcode.setOnClickListener {
            val dialog = ImageDialog(context)
            dialog.setTitle(token.issuer)
            dialog.setButtonText("完成")
            dialog.show()
            dialog.tipTv.visibility = GONE
            dialog.imageView.setImageBitmap(generateQrCode(token))
        }
        if (this.mToken.isSelected) mSelect.setImageResource(R.drawable.ic_material_checkbox_checked)
        else mSelect.setImageResource(R.drawable.ic_material_checkbox_unchecked)
    }

    private fun generateQrCode(token: OtpToken): Bitmap? {
        val qrcodeWriter = QRCodeWriter()
        val qrCodeSize = resources.getDimensionPixelSize(R.dimen.dp250)
        val encoded = qrcodeWriter.encode(
            OtpTokenParser.toUri(token).toString(), BarcodeFormat.QR_CODE, qrCodeSize, qrCodeSize
        )
        val pixels = IntArray(qrCodeSize * qrCodeSize)
        for (x in 0 until qrCodeSize) {
            for (y in 0 until qrCodeSize) {
                if (encoded.get(x, y)) {
                    pixels[x * qrCodeSize + y] = Color.BLACK
                } else {
                    pixels[x * qrCodeSize + y] = Color.WHITE
                }
            }
        }
        return Bitmap.createBitmap(pixels, qrCodeSize, qrCodeSize, Bitmap.Config.RGB_565)
    }

    private fun animate(view: View, anim: Int, animate: Boolean) {
        val a = AnimationUtils.loadAnimation(view.context, anim)
        if (!animate) a.duration = 0
        view.startAnimation(a)
    }

    fun start(type: OtpTokenType, codes: TokenCode, animate: Boolean) {
        mCodes = codes
        mType = type

        // Start animations.
        mProgressInner.visibility = View.VISIBLE
        animate(mProgressInner, R.anim.anim_fade_in, animate)

        when (type) {
            OtpTokenType.HOTP -> isEnabled = false
            OtpTokenType.TOTP -> {
                mProgressOuter.visibility = View.VISIBLE
                animate(mProgressOuter, R.anim.anim_fade_in, animate)
            }
        }

        mStartTime = System.currentTimeMillis()
        post(this)
    }

    override fun onClick(v: View) {
    }

    override fun run() {
        val code = mCodes?.currentCode ?: run {
            mCode.text = mPlaceholder
            mNextCode.text = mPlaceholder
            mProgressInner.visibility = View.GONE
            mProgressOuter.visibility = View.GONE
            return
        }

        val currentProgress = mCodes?.currentProgress ?: run {
            Log.w(tag, "Token current progress is null")
            return
        }

        val totalProgress = mCodes?.totalProgress ?: run {
            Log.w(tag, "Token total progress is null")
            return
        }

        if (!isEnabled) isEnabled = System.currentTimeMillis() - mStartTime > 5000

        mCode.text = code
        mNextCode.text = mCodes?.nextCode ?: mPlaceholder
        mProgressInner.setProgress(currentProgress)
        if (mType != OtpTokenType.HOTP) mProgressOuter.setProgress(totalProgress)

        postDelayed(this, 100)
    }
}
