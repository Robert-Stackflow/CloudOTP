package com.cloudchewie.otp.external.dropbox

import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.NetworkIOException
import com.dropbox.core.v2.DbxClientV2

class DropboxLogoutTask(
    private val dbxClientV2: DbxClientV2,
    private val callback: Callback,
) : ThreadUtils.SimpleTask<String?>() {
    private var error: Exception? = null

    override fun doInBackground(): String? {
        try {
            dbxClientV2.auth().tokenRevoke()
        } catch (ex: DbxException) {
            ex.printStackTrace()
            error = ex
        } catch (ex: NetworkIOException) {
            ex.printStackTrace()
            error = ex
        }
        return null
    }

    override fun onSuccess(account: String?) {
        when (val err = error) {
            null -> {
                callback.onLogout()
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
        fun onLogout()
        fun onNetworkError(error: NetworkIOException?)
        fun onError(error: Exception?)
    }
}
