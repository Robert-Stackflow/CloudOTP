package com.cloudchewie.otp.external.dropbox

import android.content.Context
import com.blankj.utilcode.util.ThreadUtils

import com.dropbox.core.DbxException
import com.dropbox.core.NetworkIOException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.files.FileMetadata
import com.dropbox.core.v2.files.WriteMode

import java.io.File
import java.io.FileInputStream
import java.io.IOException

class DropboxUploadTask(
    private val context: Context,
    private val clientV2: DbxClientV2,
    private val callback: Callback,
    private val file: File
) : ThreadUtils.SimpleTask<FileMetadata>() {
    private var error: Exception? = null

    override fun doInBackground(): FileMetadata? {
        val localFile = file
        val remotePathName = ""
        val remoteFileName = localFile.name
        error = try {
            val inputStream = FileInputStream(localFile)
            return clientV2.files().uploadBuilder("$remotePathName/$remoteFileName")
                .withMode(WriteMode.OVERWRITE).uploadAndFinish(inputStream)
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

    override fun onSuccess(result: FileMetadata?) {
        when (val err = error) {
            null -> {
                result?.let { callback.onUploadcomplete(it) }
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
        fun onUploadcomplete(result: FileMetadata)
        fun onNetworkError(error: NetworkIOException?)
        fun onError(ex: Exception?)
    }
}
