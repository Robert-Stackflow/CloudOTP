package com.cloudchewie.otp.activity

import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import com.blankj.utilcode.util.ThreadUtils
import com.blankj.utilcode.util.ThreadUtils.SimpleTask
import com.blankj.utilcode.util.TimeUtils
import com.cloudchewie.otp.R
import com.cloudchewie.otp.databinding.ActivityDropboxBinding
import com.cloudchewie.otp.entity.SyncConfig
import com.cloudchewie.otp.external.AESStringCypher
import com.cloudchewie.otp.external.SyncManager
import com.cloudchewie.otp.external.SyncService
import com.cloudchewie.otp.external.dropbox.DropboxAccountTask
import com.cloudchewie.otp.external.dropbox.DropboxClient
import com.cloudchewie.otp.external.dropbox.DropboxClient.getClient
import com.cloudchewie.otp.external.dropbox.DropboxDownloadTask
import com.cloudchewie.otp.external.dropbox.DropboxFileTask
import com.cloudchewie.otp.external.dropbox.DropboxUploadTask
import com.cloudchewie.otp.util.authenticator.ExportTokenUtil
import com.cloudchewie.otp.util.authenticator.ImportTokenUtil
import com.cloudchewie.otp.util.database.LocalStorage
import com.cloudchewie.otp.util.database.PrivacyManager
import com.cloudchewie.otp.widget.SecretBottomSheet
import com.cloudchewie.ui.custom.IDialog
import com.cloudchewie.ui.custom.IDialog.OnClickBottomListener
import com.cloudchewie.ui.custom.IToast
import com.cloudchewie.util.basic.DateFormatUtil.FULL_FORMAT
import com.cloudchewie.util.ui.StatusBarUtil
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
    private var firstLogin: Boolean = false

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
            if (haveBackup && !PrivacyManager.haveSecret()) {
                val bottomSheet =
                    SecretBottomSheet(
                        this,
                        SecretBottomSheet.MODE.PULL
                    )
                bottomSheet.setOnConfirmListener(this)
                bottomSheet.show()
            } else {
                onPullConfirmed(PrivacyManager.getSecret())
            }
        }

        binding.activityDropboxSigninButton.setOnClickListener {
            firstLogin = true
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
                    ThreadUtils.executeBySingle(
                        object : SimpleTask<String?>() {
                            @Throws(Throwable::class)
                            override fun doInBackground(): String? {
                                getClient(dropboxSyncConfig.accessToken).auth().tokenRevoke()
                                return null
                            }

                            override fun onSuccess(result: String?) {
                                dropboxSyncConfig = SyncConfig()
                                syncManager!!.delete(SyncService.DROPBOX)
                                IToast.showBottom(
                                    applicationContext,
                                    getString(R.string.logout_success)
                                )
                                dialog.dismiss()
                                recreate()
                            }
                        }
                    )
                }

                override fun onNegtiveClick() {
                    dialog.dismiss()
                }
            })
            dialog.show()
        }

        loadConfig()
    }

    private fun loadConfig() {
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
        } else {
            binding.activityDropboxSigninButton.visibility = View.GONE
        }
        refreshState()
    }

    private fun refreshState() {
        if (dropboxSyncConfig.lastPushed != null) {
            val simpleDateFormat = SimpleDateFormat(FULL_FORMAT, Locale.getDefault())
            binding.activityDropboxLastPushed.editText.setText(
                simpleDateFormat.format(Date(dropboxSyncConfig.lastPushed))
            )
        } else {
            binding.activityDropboxLastPushed.editText.setText(getString(R.string.have_not_pushed))
        }
        if (haveBackup)
            binding.activityDropboxPullButton.text = getString(R.string.pull)
        else
            binding.activityDropboxPullButton.text = getString(R.string.do_not_have_backup)
    }

    override fun onResume() {
        super.onResume()
        getAccessToken()
    }

    private fun getAccessToken() {
        if (dropboxSyncConfig.accessToken == null) {
            val accessToken = Auth.getOAuth2Token()
            if (accessToken != null) {
                dropboxSyncConfig.accessToken = accessToken
                syncManager!!.update(dropboxSyncConfig)
                getAccount()
            }
        } else {
            getAccount()
        }
    }

    private fun getAccount() {
        if (dropboxSyncConfig.accessToken == null) return
        ThreadUtils.executeBySingle(
            DropboxAccountTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxAccountTask.TaskDelegate {
                    override fun onAccountReceived(account: FullAccount) {
                        if (firstLogin)
                            IToast.showBottom(
                                applicationContext,
                                getString(R.string.signin_success)
                            )
                        binding.activityDropboxEmail.editText.setText(account.email)
                        binding.activityDropboxNickname.editText.setText(account.name.displayName)
                        binding.activityDropboxSigninButton.visibility = View.GONE
                        binding.activityDropboxPushPullLayout.visibility = View.VISIBLE
                        binding.activityDropboxInfoLayout.visibility = View.VISIBLE
                        binding.activityDropboxLogoutButton.visibility = View.VISIBLE
                        getFile()
                    }

                    override fun onError(error: Exception?) {
                        IToast.showBottom(applicationContext, getString(R.string.outdated_login))
                        dropboxSyncConfig = SyncConfig()
                        syncManager!!.delete(SyncService.DROPBOX)
                        recreate()
                    }
                },
            )
        )
    }

    private fun getFile() {
        ThreadUtils.executeBySingle(
            DropboxFileTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxFileTask.Callback {
                    override fun onGetListResults(list: SearchV2Result) {
                        if (list.matches.size > 0) {
                            val fileMetadata =
                                list.matches[0].metadata.metadataValue as FileMetadata
                            haveBackup = true
                            refreshState()
                            downloadFile(fileMetadata)
                        } else {
                            haveBackup = false
                            refreshState()
                        }
                    }

                    override fun onError(error: Exception?) {
                        error?.printStackTrace()
                    }
                },
                FILENAME
            )
        )
    }

    private fun downloadFile(fileMetadata: FileMetadata) {
        ThreadUtils.executeBySingle(
            DropboxDownloadTask(
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxDownloadTask.Callback {
                    override fun onDownloadComplete(result: File) {
                        mEncryptedFile = result
                    }

                    override fun onError(e: Exception?) {
                        IToast.showBottom(
                            applicationContext,
                            getString(R.string.download_backup_fail)
                        )
                    }
                },
                this.applicationContext,
                fileMetadata
            )
        )
    }

    private fun uploadFile() {
        if (mEncryptedFile == null) return
        ThreadUtils.executeBySingle(
            DropboxUploadTask(
                this.applicationContext,
                getClient(dropboxSyncConfig.accessToken),
                object : DropboxUploadTask.Callback {
                    override fun onUploadcomplete(result: FileMetadata) {
                        dropboxSyncConfig.lastPushed = TimeUtils.getNowMills()
                        syncManager!!.update(dropboxSyncConfig)
                        IToast.showBottom(applicationContext, getString(R.string.push_success))
                        haveBackup = true
                        refreshState()
                    }

                    override fun onError(ex: Exception?) {
                        IToast.showBottom(applicationContext, getString(R.string.push_fail))
                    }
                }, mEncryptedFile!!
            )
        )
    }

    override fun onPullConfirmed(secret: String) {
        if (mEncryptedFile == null) return
        val bytes = ByteArray(mEncryptedFile!!.length().toInt())
        try {
            FileInputStream(mEncryptedFile).read(bytes)
            ImportTokenUtil.mergeTokens(
                ImportTokenUtil.jsonToTokenList(
                    AESStringCypher.decryptString(
                        AESStringCypher.CipherTextIvMac(String(bytes)),
                        AESStringCypher.generateKeyFromPassword(secret, secret)
                    )
                )
            )
            IToast.showBottom(this, getString(R.string.pull_success))
            askToSaveSecret(secret)
        } catch (ex: GeneralSecurityException) {
            ex.printStackTrace()
            askToRetry()
        } catch (ex: Exception) {
            ex.printStackTrace()
            IToast.showBottom(this, getString(R.string.unknow_wrong))
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
        refreshState()
    }

    private fun askToRetry() {
        val dialog = IDialog(this)
        dialog.setTitle("密钥错误")
        dialog.setMessage("密钥错误，是否重新输入密钥？")
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
            dialog.setTitle("保存统一密钥")
            dialog.setMessage("是否保存为统一密钥？如果选择保存，你的密钥将被加密保存到本地数据库中。同时，下次进行导入或导出操作时，无需再次输入密钥。")
            dialog.setOnClickBottomListener(object : OnClickBottomListener {
                override fun onPositiveClick() {
                    PrivacyManager.setSecret(secret)
                    refreshState()
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
