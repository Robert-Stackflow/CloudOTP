package com.cloudchewie.otp.util.authenticator

import com.cloudchewie.otp.entity.OtpToken
import com.cloudchewie.otp.entity.TokenCode
import com.cloudchewie.otp.util.enumeration.OtpTokenType
import java.nio.ByteBuffer
import java.security.InvalidKeyException
import java.security.NoSuchAlgorithmException
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import javax.inject.Inject

class TokenCodeUtil @Inject constructor() {
    fun generateTokenCode(otpToken: OtpToken): TokenCode {
        val cur = System.currentTimeMillis()
        when (otpToken.tokenType) {
            OtpTokenType.HOTP ->
                return TokenCode(getHOTP(otpToken, otpToken.counter), cur, cur + otpToken.period * 1000)
            OtpTokenType.TOTP -> {
                val counter: Long = cur / 1000 / otpToken.period
                return TokenCode(
                    getHOTP(otpToken, counter + 0),
                    (counter + 0) * otpToken.period * 1000,
                    (counter + 1) * otpToken.period * 1000,
                    TokenCode(
                        getHOTP(otpToken, counter + 1),
                        (counter + 1) * otpToken.period * 1000,
                        (counter + 2) * otpToken.period * 1000
                    )
                )
            }
            null->{
                return TokenCode(getHOTP(otpToken, otpToken.counter), cur, cur + otpToken.period * 1000)
            }
        }
    }

    private fun getHOTP(otpToken: OtpToken, counter: Long): String {
        val bb = ByteBuffer.allocate(8)
        bb.putLong(counter)
        var div = 1
        for (i in otpToken.digits downTo 1) div *= 10
        try {
            val mac = Mac.getInstance("Hmac${otpToken.algorithm}")
            mac.init(SecretKeySpec(Base32String.decode(otpToken.secret), "Hmac${otpToken.algorithm}"))
            val digest = mac.doFinal(bb.array())
            var binary: Int
            val off = digest[digest.size - 1].toInt() and 0xf
            binary = digest[off].toInt() and 0x7f shl 0x18
            binary = binary or (digest[off + 1].toInt() and 0xff shl 0x10)
            binary = binary or (digest[off + 2].toInt() and 0xff shl 0x08)
            binary = binary or (digest[off + 3].toInt() and 0xff)
            var hotp = ""
            if (otpToken.issuer == "Steam") {
                for (i in 0 until otpToken.digits) {
                    hotp += STEAMCHARS[binary % STEAMCHARS.size]
                    binary /= STEAMCHARS.size
                }
            } else {
                binary %= div
                hotp = binary.toString()
                while (hotp.length != otpToken.digits) hotp = "0$hotp"
            }
            return hotp
        } catch (e: InvalidKeyException) {
            e.printStackTrace()
        } catch (e: NoSuchAlgorithmException) {
            e.printStackTrace()
        }
        return ""
    }

    companion object {

        private val STEAMCHARS = charArrayOf(
            '2', '3', '4', '5', '6', '7', '8', '9', 'B', 'C',
            'D', 'F', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q',
            'R', 'T', 'V', 'W', 'X', 'Y'
        )

    }

}