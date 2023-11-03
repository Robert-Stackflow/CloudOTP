package com.cloudchewie.otp.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.view.animation.AnimationUtils
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import com.cloudchewie.otp.R
import com.cloudchewie.otp.entity.OtpToken
import com.cloudchewie.otp.entity.TokenCode
import com.cloudchewie.otp.util.authenticator.OtpTokenParser
import com.cloudchewie.otp.util.authenticator.TokenImageUtil
import com.cloudchewie.otp.util.enumeration.OtpTokenType
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter


class SmallTokenLayout : RelativeLayout, View.OnClickListener, Runnable {
    private val tag = SmallTokenLayout::class.java.simpleName
    private lateinit var mImage: ImageView
    private lateinit var mCode: TextView
    private lateinit var mIssuer: TextView

    private var mCodes: TokenCode? = null
    private var mType: OtpTokenType? = null
    private var mPlaceholder: String? = null
    private var mStartTime: Long = 0

    constructor(context: Context) : super(context)

    constructor(context: Context, attrs: AttributeSet) : super(context, attrs)

    constructor(context: Context, attrs: AttributeSet, defStyle: Int) : super(
        context, attrs, defStyle
    )

    override fun onFinishInflate() {
        super.onFinishInflate()
        mImage = findViewById<View>(R.id.item_token_small_image) as ImageView
        mCode = findViewById<View>(R.id.item_token_small_code) as TextView
        mIssuer = findViewById<View>(R.id.item_token_small_issuer) as TextView
    }

    fun bind(token: OtpToken) {
        mCodes = null

        // Cancel all active animations.
        isEnabled = true
        removeCallbacks(this)
        mImage.clearAnimation()

        // Get the code placeholder.
        val placeholder = CharArray(token.digits)
        for (i in placeholder.indices) placeholder[i] = '*'
        mPlaceholder = String(placeholder)

        // Show the image.
        TokenImageUtil.setTokenImage(mImage, token)

        mIssuer.text = token.issuer
        mCode.text = mPlaceholder
        if (mIssuer.text.isEmpty()) {
            mIssuer.text = token.account
        }
    }

    private fun generateQrCode(token: OtpToken): Bitmap? {
        val qrcodeWriter = QRCodeWriter()
        val qrCodeSize = resources.getDimensionPixelSize(R.dimen.dp250)
        val encoded = qrcodeWriter.encode(
            OtpTokenParser.toUri(token).toString(),
            BarcodeFormat.QR_CODE,
            qrCodeSize,
            qrCodeSize
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

    fun start(type: OtpTokenType, codes: TokenCode) {
        mCodes = codes
        mType = type

        // Start animations.

        when (type) {
            OtpTokenType.HOTP -> isEnabled = false
            OtpTokenType.TOTP -> {
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
            return
        }

        mCodes?.currentProgress ?: run {
            Log.w(tag, "Token current progress is null")
            return
        }

        mCodes?.totalProgress ?: run {
            Log.w(tag, "Token total progress is null")
            return
        }

        if (!isEnabled) isEnabled = System.currentTimeMillis() - mStartTime > 5000

        mCode.text = code

        postDelayed(this, 100)
    }
}
