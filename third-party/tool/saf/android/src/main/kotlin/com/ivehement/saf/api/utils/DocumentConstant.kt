package com.ivehement.saf.api.utils

/**
 * Storage Access Framework Exceptions
 */
const val EXCEPTION_PARENT_DOCUMENT_MUST_BE_DIRECTORY =
  "EXCEPTION_PARENT_DOCUMENT_MUST_BE_DIRECTORY"
const val EXCEPTION_MISSING_PERMISSIONS = "EXCEPTION_MISSING_PERMISSIONS"

/**
 * Available Method Channel APIs
 */
const val OPEN_DOCUMENT_TREE = "openDocumentTree"
const val SYNC_WITH_EXTERNAL_FILES_DIRECTORY = "syncWithExternalFilesDirectory"
const val DYNAMIC_SYNC_WITH_EXTERNAL_FILES_DIRECTORY = "dynamicSyncWithExternalFilesDirectory"
const val CACHE_TO_EXTERNAL_FILES_DIRECTORY = "cacheToExternalFilesDirectory"
const val SINGLE_CACHE_TO_EXTERNAL_FILES_DIRECTORY = "singleCacheToExternalFilesDirectory"
const val CLEAR_CACHED_FILES = "clearCachedFiles"
const val GET_EXTERNAL_FILES_DIR_PATH = "getExternalFilesDirPath"
const val GET_CACHED_FILES_PATH = "getCachedFilesPath"
const val PERSISTED_URI_PERMISSIONS = "persistedUriPermissions"
const val RELEASE_PERSISTABLE_URI_PERMISSION =
  "releasePersistableUriPermission"
const val CREATE_FILE = "createFile"
const val FROM_TREE_URI = "fromTreeUri"
const val CAN_WRITE = "canWrite"
const val CAN_READ = "canRead"
const val RENAME_TO = "renameTo"
const val LENGTH = "length"
const val EXISTS = "exists"
const val PARENT_FILE = "parentFile"
const val CREATE_DIRECTORY = "createDirectory"
const val DELETE = "delete"
const val FIND_FILE = "findFile"
const val COPY = "copy"
const val LAST_MODIFIED = "lastModified"
const val GET_DOCUMENT_THUMBNAIL = "getDocumentThumbnail"
const val BUILD_DOCUMENT_URI_USING_TREE = "buildDocumentUriUsingTree"
const val BUILD_DOCUMENT_URI = "buildDocumentUri"
const val BUILD_TREE_DOCUMENT_URI = "buildTreeDocumentUri"
const val BUID_CHILD_DOCUMENTS_URI_USING_TREE = "buildChildDocumentsUriUsingTree"
const val BUID_CHILD_DOCUMENTS_PATH_USING_TREE = "buildChildDocumentsPathUsingTree"

/**
 * Available Event Channels APIs
 */
const val LIST_FILES = "listFiles"
const val GET_DOCUMENT_CONTENT = "getDocumentContent"

/**
 * Intent Request Codes
 */
const val OPEN_DOCUMENT_TREE_CODE = 10

/**
 * List of available FileTypes
 */
const val FILETYPES =  "media image audio video any"

