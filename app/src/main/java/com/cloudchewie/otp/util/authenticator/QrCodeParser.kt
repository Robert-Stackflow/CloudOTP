package com.cloudchewie.otp.util.authenticator

import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.zxing.BinaryBitmap
import com.google.zxing.ChecksumException
import com.google.zxing.FormatException
import com.google.zxing.NotFoundException
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class QrCodeParser @Inject constructor(private val qrCodeReader: QRCodeReader) {

    private val tag: String = QrCodeParser::class.java.simpleName

    private lateinit var imageData: ByteArray

    fun parseQRCode(image: ImageProxy): String? {
        val rowStride = image.planes[0].rowStride

        if (!::imageData.isInitialized) {
            imageData = ByteArray(rowStride * image.height)
        }

        synchronized(imageData) {
            val y = image.planes[0]
            val ySize = y.buffer.remaining()

            if (ySize > imageData.size) {
                imageData = ByteArray(ySize)
            }

            y.buffer.get(imageData, 0, ySize)

            val ls = PlanarYUVLuminanceSource(
                imageData, rowStride, image.height,
                0, 0, rowStride, image.height, false
            )

            return try {
                qrCodeReader.decode(BinaryBitmap(HybridBinarizer(ls))).text
            } catch (e: NotFoundException) {
                Log.d(tag, "QR code Not found", e)
                null
            } catch (e: ChecksumException) {
                e.printStackTrace()
                Log.e(tag, "error parsing qr code", e)
                null
            } catch (e: FormatException) {
                Log.e(tag, "error parsing qr code", e)
                null
            } finally {
                qrCodeReader.reset()
            }
        }
    }
}
