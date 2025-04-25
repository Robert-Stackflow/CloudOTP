package com.ivehement.saf.api.utils

import android.database.Cursor
import android.os.Build
import android.provider.DocumentsContract
import android.provider.DocumentsProvider
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import com.ivehement.saf.plugin.API_19

private const val PREFIX = "DocumentFileColumn"

enum class DocumentFileColumn {
  ID,
  DISPLAY_NAME,
  MIME_TYPE,
  SUMMARY,
  LAST_MODIFIED,
  SIZE
}

enum class DocumentFileColumnType {
  LONG,
  STRING
}

fun parseDocumentFileColumn(column: String): DocumentFileColumn? {
  val values = mapOf(
    "$PREFIX.COLUMN_DOCUMENT_ID" to DocumentFileColumn.ID,
    "$PREFIX.COLUMN_DISPLAY_NAME" to DocumentFileColumn.DISPLAY_NAME,
    "$PREFIX.COLUMN_MIME_TYPE" to DocumentFileColumn.MIME_TYPE,
    "$PREFIX.COLUMN_SIZE" to DocumentFileColumn.SIZE,
    "$PREFIX.COLUMN_SUMMARY" to DocumentFileColumn.SUMMARY,
    "$PREFIX.COLUMN_LAST_MODIFIED" to DocumentFileColumn.LAST_MODIFIED
  )

  return values[column]
}

fun documentFileColumnToRawString(column: DocumentFileColumn): String? {
  val values = mapOf(
    DocumentFileColumn.ID to "$PREFIX.COLUMN_DOCUMENT_ID",
    DocumentFileColumn.DISPLAY_NAME to "$PREFIX.COLUMN_DISPLAY_NAME",
    DocumentFileColumn.MIME_TYPE to "$PREFIX.COLUMN_MIME_TYPE",
    DocumentFileColumn.SIZE to "$PREFIX.COLUMN_SIZE",
    DocumentFileColumn.SUMMARY to "$PREFIX.COLUMN_SUMMARY",
    DocumentFileColumn.LAST_MODIFIED to "$PREFIX.COLUMN_LAST_MODIFIED"
  )

  return values[column]
}

fun parseDocumentFileColumn(column: DocumentFileColumn): String? {
  val values = mapOf(
    DocumentFileColumn.ID to DocumentsContract.Document.COLUMN_DOCUMENT_ID,
    DocumentFileColumn.DISPLAY_NAME to DocumentsContract.Document.COLUMN_DISPLAY_NAME,
    DocumentFileColumn.MIME_TYPE to DocumentsContract.Document.COLUMN_MIME_TYPE,
    DocumentFileColumn.SIZE to DocumentsContract.Document.COLUMN_SIZE,
    DocumentFileColumn.SUMMARY to DocumentsContract.Document.COLUMN_SUMMARY,
    DocumentFileColumn.LAST_MODIFIED to DocumentsContract.Document.COLUMN_LAST_MODIFIED
  )

  return values[column]
}

/// `column` must be a constant String from `DocumentsContract.Document.COLUMN*`
fun typeOfColumn(column: String): DocumentFileColumnType? {
  val values = mapOf(
    DocumentsContract.Document.COLUMN_DOCUMENT_ID to DocumentFileColumnType.STRING,
    DocumentsContract.Document.COLUMN_DISPLAY_NAME to DocumentFileColumnType.STRING,
    DocumentsContract.Document.COLUMN_MIME_TYPE to DocumentFileColumnType.STRING,
    DocumentsContract.Document.COLUMN_SIZE to DocumentFileColumnType.LONG,
    DocumentsContract.Document.COLUMN_SUMMARY to DocumentFileColumnType.STRING,
    DocumentsContract.Document.COLUMN_LAST_MODIFIED to DocumentFileColumnType.LONG
  )

  return values[column]
}

fun cursorHandlerOf(type: DocumentFileColumnType): (Cursor, Int) -> Any {
  when(type) {
    DocumentFileColumnType.LONG -> { return { cursor, index -> cursor.getLong(index) } }
    DocumentFileColumnType.STRING -> { return { cursor, index -> cursor.getString(index) } }
  }
}
