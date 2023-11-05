package com.cloudchewie.otp.external

import com.dropbox.core.DbxRequestConfig
import com.dropbox.core.v2.DbxClientV2

object DropboxClient {

    fun getClient(accessToken: String): DbxClientV2 {
        val config = DbxRequestConfig("dropbox/CloudOTP")
        return DbxClientV2(config, accessToken)
    }
}
