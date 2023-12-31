package com.cloudchewie.otp.external.dropbox

import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.NetworkIOException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.files.SearchV2Result

class DropboxFileTask(
    private val dbxClientV2: DbxClientV2,
    private val callback: Callback,
    private val filename: String,
) : ThreadUtils.SimpleTask<SearchV2Result>() {
    private var error: Exception? = null

    override fun doInBackground(): SearchV2Result? {
        error = try {
            return dbxClientV2.files().searchV2(filename)
        } catch (ex: DbxException) {
            ex.printStackTrace()
            ex
        } catch (ex: NetworkIOException) {
            ex.printStackTrace()
            ex
        }
        return null
    }

    override fun onSuccess(list: SearchV2Result?) {
        when (val err = error) {
            null -> {
                list?.let { callback.onGetListResults(it) }
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
        fun onGetListResults(list: SearchV2Result)
        fun onNetworkError(error: NetworkIOException?)
        fun onError(error: Exception?)
    }

}
