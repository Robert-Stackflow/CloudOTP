package com.cloudchewie.otp.external.dropbox

import android.content.Context
import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.NetworkIOException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.files.FileMetadata
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class DropboxDownloadTask(
    private val clientV2: DbxClientV2,
    private val callback: Callback,
    private val context: Context,
    private val fileMetadata: FileMetadata
) : ThreadUtils.SimpleTask<File>() {
    private var error: Exception? = null

    override fun doInBackground(): File? {
        val metadata = fileMetadata
        error = try {
            val fileName = metadata.name
            val file = File(context.cacheDir, fileName)
            val os = FileOutputStream(file)
            clientV2.files().download(metadata.pathLower, metadata.rev).download(os)
            return file
        } catch (ex: DbxException) {
            ex
        } catch (ex: IOException) {
            ex
        } catch (ex: NetworkIOException) {
            ex.printStackTrace()
            ex
        }
        return null
    }

    override fun onSuccess(result: File?) {
        when (val err = error) {
            null -> {
                result?.let { callback.onDownloadComplete(it) }
            }

            is NetworkIOException -> {
                callback.onNetworkError(err)
            }

            else -> {
                callback.onError(err)
            }
        }
    }

    interface Callback {
        fun onDownloadComplete(result: File)
        fun onNetworkError(error: NetworkIOException?)
        fun onError(e: Exception?)
    }
}
