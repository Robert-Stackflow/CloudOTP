package com.cloudchewie.otp.external

import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.users.FullAccount

class DropboxAccountTask(
    private val dbxClientV2: DbxClientV2, private val delegate: TaskDelegate
) : ThreadUtils.SimpleTask<FullAccount>() {
    private var error: Exception? = null

    override fun doInBackground(): FullAccount? {
        try {
            return dbxClientV2.users().currentAccount
        } catch (ex: DbxException) {
            ex.printStackTrace()
            error = ex
        }
        return null
    }

    override fun onSuccess(account: FullAccount?) {
        val err = error
        if (err == null) {
            account?.let { delegate.onAccountReceived(it) }
        } else {
            delegate.onError(err)
        }
    }

    interface TaskDelegate {
        fun onAccountReceived(account: FullAccount)
        fun onError(error: Exception?)
    }
}
