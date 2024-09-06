package com.ivehement.saf.api.utils

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import android.os.Build
import android.provider.DocumentsContract
import android.util.Base64
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import com.ivehement.saf.plugin.API_19
import com.ivehement.saf.plugin.API_21
import com.ivehement.saf.plugin.API_24
import java.io.ByteArrayOutputStream
import java.io.Closeable

/**
 * Helper class to make more easy to handle callbacks using Kotlin syntax
 */
data class CallbackHandler<T>(
  var onSuccess: (T.() -> Unit)? = null,
  var onEnd: (() -> Unit)? = null
)

/**
 * Generate the `DocumentFile` reference from string `uri` (Single `DocumentFile`)
 */
@RequiresApi(API_21)
fun documentFromSingleUri(context: Context, uri: String): DocumentFile? =
  documentFromSingleUri(context, Uri.parse(uri))

/**
 * Generate the `DocumentFile` reference from string `uri` (Single `DocumentFile`)
 */
@RequiresApi(API_21)
fun documentFromSingleUri(context: Context, uri: Uri): DocumentFile? {
  val documentUri = DocumentsContract.buildDocumentUri(
    uri.authority,
    DocumentsContract.getDocumentId(uri)
  )

  return DocumentFile.fromSingleUri(context, documentUri)
}

/**
 * Generate the `DocumentFile` reference from string `uri`
 */
@RequiresApi(API_21)
fun documentFromUri(context: Context, uri: String): DocumentFile? =
  documentFromUri(context, Uri.parse(uri))

/**
 * Generate the `DocumentFile` reference from URI `uri`
 */
@RequiresApi(API_21)
fun documentFromUri(context: Context, uri: Uri): DocumentFile? {
  return if (isTreeUri(uri)) {
    DocumentFile.fromTreeUri(context, uri)
  } else {
    DocumentFile.fromSingleUri(
      context,
      DocumentsContract.buildDocumentUriUsingTree(
        uri,
        DocumentsContract.getDocumentId(uri)
      )
    )
  }
}

/**
 * Standard map encoding of a `DocumentFile` and must be used before returning any `DocumentFile`
 * from plugin results, like:
 * ```dart
 * result.success(createDocumentFileMap(documentFile))
 * ```
 */
fun createDocumentFileMap(documentFile: DocumentFile?): Map<String, Any?>? {
  if (documentFile == null) return null

  return mapOf(
    "isDirectory" to documentFile.isDirectory,
    "isFile" to documentFile.isFile,
    "isVirtual" to documentFile.isVirtual,
    "name" to (documentFile.name ?: ""),
    "type" to (documentFile.type ?: ""),
    "uri" to "${documentFile.uri}",
    "exists" to "${documentFile.exists()}"
  )
}


/**
 * Standard map encoding of a row result of a `DocumentFile`
 * ```dart
 * result.success(createDocumentFileMap(documentFile))
 * ```
 * Example:
 * ```py
 * input = {
 *   "last_modified": 2939496, /// Key from DocumentsContract.Document.COLUMN_LAST_MODIFIED
 *   "_display_name": "MyFile" /// Key from DocumentsContract.Document.COLUMN_DISPLAY_NAME
 * }
 *
 * output = createCursorRowMap(input)
 *
 * print(output)
 * {
 *   "lastModified": 2939496,
 *   "displayName": "MyFile"
 * }
 * ```
 */
fun createCursorRowMap(
  rootUri: Uri,
  parentUri: Uri,
  uri: Uri,
  data: Map<String, Any>,
  isDirectory: Boolean?
): Map<String, Any> {
  val values = DocumentFileColumn.values()

  val formattedData = mutableMapOf<String, Any>()

  for (value in values) {
    val key = parseDocumentFileColumn(value)!!

    if (data[key] != null) {
      formattedData[documentFileColumnToRawString(value)!!] = data[key]!!
    }
  }

  return mapOf(
    "data" to formattedData,
    "metadata" to mapOf(
      "parentUri" to "$parentUri",
      "rootUri" to "$rootUri",
      "isDirectory" to isDirectory,
      "uri" to "$uri"
    )
  )
}

/**
 * Util method to close a closeable
 */
fun closeQuietly(closeable: Closeable?) {
  if (closeable != null) {
    try {
      closeable.close()
    } catch (e: RuntimeException) {
      throw e
    } catch (ignore: Exception) {
    }
  }
}

@RequiresApi(API_21)
fun traverseDirectoryEntries(
  contentResolver: ContentResolver,
  rootUri: Uri,
  columns: Array<String>,
  rootOnly: Boolean,
  block: (data: Map<String, Any>) -> Unit
) {
  val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
    rootUri,
    DocumentsContract.getTreeDocumentId(rootUri)
  )

  /// Keep track of our directory hierarchy
  val dirNodes = mutableListOf<Pair<Uri, Uri>>(Pair(rootUri, childrenUri))

  while (dirNodes.isNotEmpty()) {
    val (parent, children) = dirNodes.removeAt(0)

    val requiredColumns = if (rootOnly) emptyArray() else arrayOf(
      DocumentsContract.Document.COLUMN_MIME_TYPE,
      DocumentsContract.Document.COLUMN_DOCUMENT_ID
    )

    val projection = arrayOf(*columns, *requiredColumns).toSet().toTypedArray()

    val cursor = contentResolver.query(
      children,
      projection,
      /// TODO: Add support for `selection`, `selectionArgs` and `sortOrder`
      null,
      null,
      null
    ) ?: return

    try {
      while (cursor.moveToNext()) {
        val data = mutableMapOf<String, Any>()

        for (column in columns) {
          data[column] = cursorHandlerOf(typeOfColumn(column)!!)(
            cursor,
            cursor.getColumnIndexOrThrow(column)
          )
        }

        val mimeType = data[DocumentsContract.Document.COLUMN_MIME_TYPE] as String?
        val id = data[DocumentsContract.Document.COLUMN_DOCUMENT_ID] as String as String?

        val isDirectory = if (mimeType != null) isDirectory(mimeType) else null

        val uri = DocumentsContract.buildDocumentUriUsingTree(
          parent,
          DocumentsContract.getDocumentId(
            DocumentsContract.buildDocumentUri(parent.authority, id)
          )
        )

        block(createCursorRowMap(rootUri, parent, uri, data, isDirectory = isDirectory))

        if (isDirectory != null && isDirectory) {
          val nextChildren = DocumentsContract.buildChildDocumentsUriUsingTree(rootUri, id)
          val nextNode = Pair(uri, nextChildren)

          dirNodes.add(nextNode)
        }
      }
    } finally {
      closeQuietly(cursor)
    }
  }
}

@RequiresApi(API_19)
private fun isDirectory(mimeType: String): Boolean {
  return DocumentsContract.Document.MIME_TYPE_DIR == mimeType
}

fun bitmapToBase64(bitmap: Bitmap): String {
  val outputStream = ByteArrayOutputStream()

  val fullQuality = 100

  bitmap.compress(Bitmap.CompressFormat.PNG, fullQuality, outputStream)

  return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
}

/**
 * Trick to verify if is a tree URi even not in API 26+
 */
fun isTreeUri(uri: Uri): Boolean {
  if (Build.VERSION.SDK_INT >= API_24) {
    return DocumentsContract.isTreeUri(uri)
  }

  val paths = uri.pathSegments

  return paths.size >= 2 && "tree" == paths[0]
}

/**
 * extract the file ID i.e name from URI
 */
fun nameFromFileUri(uri: Uri): String? {
  if(!isTreeUri(uri)) return null
  try {
    val pathSegments = uri.getPath().toString().split("/")
    val fileName = pathSegments[pathSegments.size - 1]
    return fileName
  }
  catch(e: Exception) {
    Log.e("NAME_FROM_FILE_PATH_EXCEPTION", e.message.toString())
  }
  return null
}

/**
 * Get the list of Uri implementing `DocumentsContract.buildChildDocumentsUriUsingTree`
 */
fun buildChildDocumentsUriUsingTree(treeUri: Uri, contentResolver: ContentResolver): List<Uri>? {
  if(Build.VERSION.SDK_INT >= 21 && isTreeUri(treeUri)) {
    val parentUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))
    var childrenUris = listOf<Uri>()
    val cursor = contentResolver.query(
      parentUri, arrayOf(
        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
        DocumentsContract.Document.COLUMN_MIME_TYPE,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED
        ),
        null, null, null
        )
    try {
      while (cursor!!.moveToNext()) {
        val docId = cursor.getString(0)
        val eachUri = DocumentsContract.buildChildDocumentsUriUsingTree(parentUri, docId).toString().replace("/children", "")
        childrenUris += Uri.parse(eachUri)
      }
      return childrenUris
    }
    catch(e: Exception) {
      Log.e("CONTENT_RESOLVER_EXCEPTION: ", e.message!!)
    }
    finally {
      if (cursor != null) {
          try {
              cursor.close()
          } catch (re: RuntimeException) {
              
          }
      } 
    }
  }
  return null
}