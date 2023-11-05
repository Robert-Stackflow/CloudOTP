package com.cloudchewie.otp.external

import android.app.DialogFragment
import android.os.Bundle
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import com.cloudchewie.otp.R
import kotlinx.android.synthetic.main.fragment_dropbox_password.db_password
import kotlinx.android.synthetic.main.fragment_dropbox_password.db_password_verification
import kotlinx.android.synthetic.main.fragment_dropbox_password.dismiss_password_button
import kotlinx.android.synthetic.main.fragment_dropbox_password.verify_password_label

class DropboxPasswordFragment : DialogFragment(), TextView.OnEditorActionListener {
    private var editText: EditText? = null
    private var dismissButton: Button? = null
    private var passwordVerificationText: EditText? = null
    private var passwordVerificationLabel: TextView? = null
    private var hasRemoteFile = false


    interface DropboxFilePasswordListener {
        fun onFinishPasswordDialog(password: String)
    }

    @Deprecated("Deprecated in Java")
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_dropbox_password, container)

        hasRemoteFile = arguments.getBoolean("hasRemoteFile")

        dismiss_password_button!!.setOnClickListener(dismissClickListener)
        dialog.window!!.requestFeature(Window.FEATURE_NO_TITLE)
        if (hasRemoteFile) {
            verify_password_label!!.visibility = View.GONE
            db_password_verification!!.visibility = View.GONE
        }
        return view
    }

    override fun onEditorAction(textView: TextView, i: Int, keyEvent: KeyEvent): Boolean {
        val activity = activity as DropboxFilePasswordListener
        activity.onFinishPasswordDialog(this.db_password.text.toString())
        dialog.dismiss()
        return true
    }

    private val dismissClickListener = View.OnClickListener {
        if (!hasRemoteFile && db_password!!.text.toString() != db_password_verification!!.text.toString()) {
            Toast.makeText(
                activity.applicationContext,
                R.string.mismatch_passcode,
                Toast.LENGTH_SHORT
            ).show()
        } else {
            val activity = activity as DropboxFilePasswordListener
            activity.onFinishPasswordDialog(db_password!!.text.toString())
            dialog.dismiss()
        }
    }

}
