package com.cloudchewie.otp.activity

import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import com.blankj.utilcode.util.ThreadUtils
import com.blankj.utilcode.util.TimeUtils
import com.cloudchewie.otp.R
import com.cloudchewie.otp.databinding.ActivityDropboxBinding
import com.cloudchewie.otp.entity.ImportAnalysis
import com.cloudchewie.otp.entity.SyncConfig
import com.cloudchewie.otp.external.AESStringCypher
import com.cloudchewie.otp.external.SyncManager
import com.cloudchewie.otp.external.SyncService
import com.cloudchewie.otp.external.dropbox.DropboxClient
import com.cloudchewie.otp.external.dropbox.DropboxClient.getClient
import com.cloudchewie.otp.external.dropbox.DropboxDownloadTask
import com.cloudchewie.otp.external.dropbox.DropboxFileTask
import com.cloudchewie.otp.external.dropbox.DropboxLogoutTask
import com.cloudchewie.otp.external.dropbox.DropboxSigninTask
import com.cloudchewie.otp.external.dropbox.DropboxUploadTask
import com.cloudchewie.otp.util.authenticator.ExportTokenUtil
import com.cloudchewie.otp.util.authenticator.ImportTokenUtil
import com.cloudchewie.otp.util.database.LocalStorage
import com.cloudchewie.otp.util.database.PrivacyManager
import com.cloudchewie.otp.widget.SecretBottomSheet
import com.cloudchewie.ui.custom.IDialog
import com.cloudchewie.ui.custom.IDialog.OnClickBottomListener
import com.cloudchewie.ui.custom.IToast
import com.cloudchewie.ui.loadingdialog.view.LoadingDialog
import com.cloudchewie.util.basic.DateFormatUtil.FULL_FORMAT
import com.cloudchewie.util.ui.StatusBarUtil
import com.dropbox.core.NetworkIOException
import com.dropbox.core.android.Auth
import com.dropbox.core.v2.files.FileMetadata
import com.dropbox.core.v2.files.SearchV2Result
import com.dropbox.core.v2.users.FullAccount
import java.io.File
import java.io.FileInputStream
import java.security.GeneralSecurityException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


open class DropboxActivity : BaseActivity(), SecretBottomSheet.OnConfirmListener {
    companion object {
        private const val FILENAME = "CloudOTP.db"
        private const val APPKEY = "ljyx5bk2jq92esr"
    }

    private var syncManager: SyncManager? = null
    private var prefs: SharedPreferences? = null
    private val dropboxClient: DropboxClient? = null
    private var mEncryptedFile: File? = null
    private var haveBackup = false
    private lateinit var binding: ActivityDropboxBinding
    private var dropboxSyncConfig: SyncConfig = SyncConfig()
    private var loadingDialog: LoadingDialog? = null
    private var fileMetadata: FileMetadata? = null
    private var redirectToSignin: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDropboxBinding.inflate(layoutInflater)
        setContentView(binding.root)
        StatusBarUtil.setStatusBarMarginTop(this)

        syncManager = SyncManager(applicationContext)

        binding.activityDropboxTitlebar.setLeftButtonClickListener { finishAfterTransition() }
        binding.activityDropboxTitlebar.setRightButtonClickListener { showTip() }
        binding.activityDropboxEmail.setDisabled(true)
        binding.activityDropboxNickname.setDisabled(true)
        binding.activityDropboxLastPushed.setDisabled(true)
        binding.activityDropboxSwipeRefresh.setEnableOverScrollDrag(true)
        binding.activityDropboxSwipeRefresh.setEnableOverScrollBounce(true)
        binding.activityDropboxSwipeRefresh.setEnableLoadMore(false)
        binding.activityDropboxSwipeRefresh.setEnablePureScrollMode(true)

        binding.activityDropboxPushButton.setOnClickListener {
            if (PrivacyManager.haveSecret()) {
                onPushConfirmed(PrivacyManager.getSecret())
            } else {
                val bottomSheet =
                    SecretBottomSheet(
                        this,
                        SecretBottomSheet.MODE.PUSH
                    )
                bottomSheet.setOnConfirmListener(this)
                bottomSheet.show()
            }
        }

        binding.activityDropboxPullButton.setOnClickListener {
            getFile()
        }

        binding.activityDropboxSigninButton.setOnClickListener {
            redirectToSignin = true
            Auth.startOAuth2Authentication(this, APPKEY)
        }

        binding.activityDropboxLogoutButton.setOnClickListener {
            val dialog = IDialog(this)
            dialog.setTitle(getString(R.string.dialog_title_logout))
            dialog.setMessage(
                String.format(
                    getString(
                        R.string.dialog_content_logout,
                        getString(R.string.title_dropbox)
                    )
                )
            )
            dialog.setOnClickBottomListener(object : OnClickBottomListener {
                override fun onPositiveClick() {
                    logout()
                }

                override fun onNegtiveClick() {
                    dialog.dismiss()
                }
            })
            dialog.show()
        }

        loadingDialog = LoadingDialog(this)

        loadConfig(true)
    }

    private fun loadConfig(init: Boolean) {
        val temp = LocalStorage.getAppDatabase().syncConfigDao().get(SyncService.DROPBOX.key)
        if (temp != null && temp.name.isNotEmpty()) {
            dropboxSyncConfig = temp
        } else {
            dropboxSyncConfig = SyncConfig(SyncService.DROPBOX.key)
            LocalStorage.getAppDatabase().syncConfigDao().insert(dropboxSyncConfig)
        }
        if (dropboxSyncConfig.accessToken == null || dropboxSyncConfig.accessToken.isEmpty()) {
            binding.activityDropboxInfoLayout.visibility = View.GONE
            binding.activityDropboxPushPullLayout.visibility = View.GONE
            binding.activityDropboxLogoutButton.visibility = View.GONE
            binding.activityDropboxSigninButton.visibility = View.VISIBLE
        } else {
            binding.activityDropboxSigninButton.visibility = View.GONE
        }
        refreshState(true)
        if (init)
            getAccessToken()
    }

    private fun refreshState(init: Boolean) {
        if (dropboxSyncConfig.lastPushed != null) {
            val simpleDateFormat = SimpleDateFormat(FULL_FORMAT, Locale.getDefault())
            binding.activityDropboxLastPushed.editText.setText(
                simpleDateFormat.format(Date(dropboxSyncConfig.lastPushed))
            )
        } else {
            binding.activityDropboxLastPushed.editText.setText(getString(R.string.have_not_pushed))
        }
        if (haveBackup || init)
            binding.activityDropboxPullButton.text = getString(R.string.pull)
        else
            binding.activityDropboxPullButton.text = getString(R.string.do_not_have_backup)
    }

    override fun onResume() {
        super.onResume()
        if (redirectToSignin)
            getAccessToken()
    }

    private fun getAccessToken() {
        if (dropboxSyncConfig.accessToken == null && redirectToSignin) {
            val accessToken = Auth.getOAuth2Token()
            if (accessToken != null) {
                dropboxSyncConfig.accessToken = accessToken
                syncManager!!.update(dropboxSyncConfig)
                signin()
            }
        } else if (dropboxSyncConfig.accessToken != null) {
            signin()
        }
    }

    private fun signin() {
        if (dropboxSyncConfig.accessToken == null) return
        loadingDialog!!.setLoadingText(getString(R.string.loading_signin)).show()
        ThreadUtils.executeBySingle(
            DropboxSigninTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxSigninTask.Callback {
                    override fun onSignin(account: FullAccount) {
                        loadingDialog!!.close()
                        if (redirectToSignin)
                            IToast.showBottom(
                                this@DropboxActivity,
                                getString(R.string.signin_success)
                            )
                        redirectToSignin = false
                        binding.activityDropboxEmail.editText.setText(account.email)
                        binding.activityDropboxNickname.editText.setText(account.name.displayName)
                        binding.activityDropboxSigninButton.visibility = View.GONE
                        binding.activityDropboxPushPullLayout.visibility = View.VISIBLE
                        binding.activityDropboxInfoLayout.visibility = View.VISIBLE
                        binding.activityDropboxLogoutButton.visibility = View.VISIBLE
                    }

                    override fun onNetworkError(error: NetworkIOException?) {
                        redirectToSignin = false
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.fail_connect_dropbox)
                        )
                    }

                    override fun onError(error: Exception?) {
                        redirectToSignin = false
                        loadingDialog!!.close()
                        IToast.showBottom(this@DropboxActivity, getString(R.string.outdated_login))
                        dropboxSyncConfig = SyncConfig()
                        syncManager!!.delete(SyncService.DROPBOX)
                        loadConfig(false)
                    }
                },
            )
        )
    }

    private fun logout() {
        if (dropboxSyncConfig.accessToken == null) return
        loadingDialog!!.setLoadingText(getString(R.string.loading_logout)).show()
        ThreadUtils.executeBySingle(
            DropboxLogoutTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxLogoutTask.Callback {
                    override fun onLogout() {
                        loadingDialog!!.close()
                        dropboxSyncConfig = SyncConfig()
                        syncManager!!.delete(SyncService.DROPBOX)
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.logout_success)
                        )
                        loadConfig(false)
                    }

                    override fun onNetworkError(error: NetworkIOException?) {
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.fail_connect_dropbox)
                        )
                    }

                    override fun onError(error: Exception?) {
                        loadingDialog!!.close()
                        IToast.showBottom(this@DropboxActivity, getString(R.string.logout_fail))
                        recreate()
                    }
                },
            )
        )
    }

    private fun getFile() {
        loadingDialog!!.setLoadingText(getString(R.string.loading_searchBackup)).show()
        ThreadUtils.executeBySingle(
            DropboxFileTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxFileTask.Callback {
                    override fun onGetListResults(list: SearchV2Result) {
                        if (list.matches.size > 0) {
                            fileMetadata =
                                list.matches[0].metadata.metadataValue as FileMetadata
                            haveBackup = true
                            refreshState(false)
                            downloadFile(fileMetadata!!)
                        } else {
                            haveBackup = false
                            refreshState(false)
                            IToast.showBottom(
                                this@DropboxActivity,
                                getString(R.string.do_not_have_backup)
                            )
                        }
                    }

                    override fun onNetworkError(error: NetworkIOException?) {
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.fail_connect_dropbox)
                        )
                    }

                    override fun onError(error: Exception?) {
                        error?.printStackTrace()
                        loadingDialog!!.close()
                    }
                },
                FILENAME
            )
        )
    }

    private fun downloadFile(fileMetadata: FileMetadata) {
        loadingDialog!!.setLoadingText(getString(R.string.loading_download)).show()
        ThreadUtils.executeBySingle(
            DropboxDownloadTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxDownloadTask.Callback {
                    override fun onDownloadComplete(result: File) {
                        mEncryptedFile = result
                        loadingDialog!!.close()
                        if (haveBackup && !PrivacyManager.haveSecret()) {
                            val bottomSheet =
                                SecretBottomSheet(
                                    this@DropboxActivity,
                                    SecretBottomSheet.MODE.PULL
                                )
                            bottomSheet.setOnConfirmListener(this@DropboxActivity)
                            bottomSheet.show()
                        } else {
                            onPullConfirmed(PrivacyManager.getSecret())
                        }
                    }

                    override fun onNetworkError(error: NetworkIOException?) {
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.fail_connect_dropbox)
                        )
                    }

                    override fun onError(e: Exception?) {
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.download_backup_fail)
                        )
                    }
                },
                this@DropboxActivity,
                fileMetadata
            )
        )
    }

    private fun uploadFile() {
        if (mEncryptedFile == null) return
        loadingDialog!!.setLoadingText(getString(R.string.loading_bakup)).show()
        ThreadUtils.executeBySingle(
            DropboxUploadTask(
                this@DropboxActivity,
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxUploadTask.Callback {
                    override fun onUploadcomplete(result: FileMetadata) {
                        loadingDialog!!.close()
                        dropboxSyncConfig.lastPushed = TimeUtils.getNowMills()
                        syncManager!!.update(dropboxSyncConfig)
                        haveBackup = true
                        IToast.showBottom(this@DropboxActivity, getString(R.string.push_success))
                        refreshState(false)
                    }

                    override fun onNetworkError(error: NetworkIOException?) {
                        loadingDialog!!.close()
                        IToast.showBottom(
                            this@DropboxActivity,
                            getString(R.string.fail_connect_dropbox)
                        )
                    }

                    override fun onError(ex: Exception?) {
                        loadingDialog!!.close()
                        IToast.showBottom(this@DropboxActivity, getString(R.string.push_fail))
                    }
                }, mEncryptedFile!!
            )
        )
    }

    override fun onPullConfirmed(secret: String) {
        if (mEncryptedFile == null) return
        loadingDialog!!.setLoadingText(getString(R.string.loading_decrypt)).show()
        val bytes = ByteArray(mEncryptedFile!!.length().toInt())
        try {
            FileInputStream(mEncryptedFile).read(bytes)
            val importAnalysis = ImportAnalysis()
            val tokens = ImportTokenUtil.jsonToTokenList(
                AESStringCypher.decryptString(
                    AESStringCypher.CipherTextIvMac(String(bytes)),
                    AESStringCypher.generateKeyFromPassword(secret, secret)
                )
            )
            importAnalysis.foundTokenCount = tokens.size
            importAnalysis.realAddTokenCount = ImportTokenUtil.mergeTokens(tokens)
            loadingDialog!!.close()
            IToast.showBottom(
                this@DropboxActivity,
                importAnalysis.toPullToast(this@DropboxActivity)
            )
            askToSaveSecret(secret)
        } catch (ex: GeneralSecurityException) {
            ex.printStackTrace()
            loadingDialog!!.close()
            askToRetry()
        } catch (ex: Exception) {
            loadingDialog!!.close()
            IToast.showBottom(this@DropboxActivity, getString(R.string.pull_fail))
            ex.printStackTrace()
        }
    }

    override fun onPushConfirmed(secret: String) {
        try {
            mEncryptedFile =
                ExportTokenUtil.createCachedFileFromEncryptString(
                    ExportTokenUtil.getEncryptedData(secret),
                    FILENAME,
                    this
                )
            uploadFile()
            askToSaveSecret(secret)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onSetSecretConfirmed(secret: String?) {
        PrivacyManager.setSecret(secret)
        syncManager!!.update(dropboxSyncConfig)
        refreshState(false)
    }

    private fun askToRetry() {
        val dialog = IDialog(this)
        dialog.setTitle(getString(R.string.dialog_title_wrong_secret))
        dialog.setMessage(getString(R.string.dialog_content_wrong_secret))
        dialog.setOnClickBottomListener(object : OnClickBottomListener {
            override fun onPositiveClick() {
                val bottomSheet =
                    SecretBottomSheet(this@DropboxActivity, SecretBottomSheet.MODE.PULL)
                bottomSheet.setOnConfirmListener(this@DropboxActivity)
                bottomSheet.show()
            }

            override fun onNegtiveClick() {}
        })
        dialog.show()
    }

    private fun askToSaveSecret(secret: String) {
        if (!PrivacyManager.haveSecret() || (PrivacyManager.getSecret() != secret)) {
            val dialog = IDialog(this)
            dialog.setTitle(getString(R.string.dialog_title_save_secret))
            dialog.setMessage(getString(R.string.dialog_content_save_secret))
            dialog.setOnClickBottomListener(object : OnClickBottomListener {
                override fun onPositiveClick() {
                    PrivacyManager.setSecret(secret)
                    refreshState(false)
                    dialog.dismiss()
                }

                override fun onNegtiveClick() {
                    dialog.dismiss()
                }
            })
            dialog.show()
        }
    }

    private fun showTip() {
        val dialog = IDialog(this)
        dialog.setTitle(
            String.format(
                getString(R.string.dialog_title_sync_info),
                getString(R.string.title_dropbox)
            )
        )
        dialog.setMessage(
            String.format(
                getString(R.string.dialog_content_sync_info),
                getString(R.string.title_dropbox),
                getString(R.string.title_dropbox),
                getString(R.string.app_name)
            )
        )
        dialog.setSingle(true)
        dialog.setOnClickBottomListener(object : OnClickBottomListener {
            override fun onPositiveClick() {
                dialog.dismiss()
            }

            override fun onNegtiveClick() {
                dialog.dismiss()
            }
        })
        dialog.show()
    }
}
