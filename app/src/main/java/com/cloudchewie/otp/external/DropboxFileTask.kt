package com.cloudchewie.otp.external

import com.blankj.utilcode.util.ThreadUtils
import com.dropbox.core.DbxException
import com.dropbox.core.v2.DbxClientV2
import com.dropbox.core.v2.files.SearchV2Result

class DropboxFileTask(
    private val dbxClientV2: DbxClientV2,
    private val delegate: Callback,
    private val filename: String,
) : ThreadUtils.SimpleTask<SearchV2Result>() {
    private var error: Exception? = null

    override fun doInBackground(): SearchV2Result? {
        try {
            return dbxClientV2.files().searchV2(filename)
        } catch (ex: DbxException) {
            ex.printStackTrace()
            error = ex
        }
        return null
    }

    override fun onSuccess(list: SearchV2Result?) {
        val e = error
        if (e == null) {
            list?.let { delegate.onGetListResults(it) }
        } else {
            delegate.onError(e)
        }
    }

    /*@Override
    protected File doInBackground(FileMetadata... fileMetadatas) {
        FileMetadata metadata = fileMetadatas[0];

        try {
            File path = Environment.getDataDirectory();
            File file = new File(path, metadata.getName());
            if (!path.exists()) {
                if (!path.mkdirs()) {
                    error = new RuntimeException("Cant create dir: " + path);
                }
            } else if (!path.isDirectory()) {
                error = new IllegalStateException("Downloadpath is not directory: " + path );
                return null;
            }
            OutputStream os = new FileOutputStream(file);
            dbxClientV2.files().download(metadata.getPathLower(), metadata.getRev())
                    .download(os);

            return file;
        } catch (DbxException | IOException ex) {
            error = ex;
        }
        return null;
    }

    @Override
    protected void onPostExecute(File result) {
        super.onPostExecute(result);
        if (error == null ) {
            delegate.onFileDownloaded(result);
        } else {
            delegate.onError(error);
        }
    }*/

    interface Callback {
        fun onGetListResults(list: SearchV2Result)
        fun onError(error: Exception?)
    }

}
