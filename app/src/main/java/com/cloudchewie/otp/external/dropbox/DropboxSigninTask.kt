package com.cloudchewie.otp.external.dropbox

import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.NetworkIOException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.users.FullAccount

class DropboxSigninTask(
    private val dbxClientV2: DbxClientV2, private val callback: Callback
) : ThreadUtils.SimpleTask<FullAccount>() {
    private var error: Exception? = null

    override fun doInBackground(): FullAccount? {
        error = try {
            return dbxClientV2.users().currentAccount
        } catch (ex: DbxException) {
            ex.printStackTrace()
            ex
        } catch (ex: NetworkIOException) {
            ex.printStackTrace()
            ex
        }
        return null
    }

    override fun onSuccess(account: FullAccount?) {
        when (val err = error) {
            null -> {
                account?.let { callback.onSignin(it) }
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
        fun onSignin(account: FullAccount)
        fun onNetworkError(error: NetworkIOException?)
        fun onError(error: Exception?)
    }
}
