package com.ivehement.saf.api

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.content.ContentResolver
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.content.Context
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.*
import io.flutter.plugin.common.EventChannel.StreamHandler
import com.ivehement.saf.ROOT_CHANNEL
import com.ivehement.saf.SafPlugin
import com.ivehement.saf.plugin.*
import com.ivehement.saf.api.utils.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.BufferedReader
import java.io.InputStreamReader

import java.io.File
import com.ivehement.saf.api.utils.SafUtil

internal class DocumentFileApi(private val plugin: SafPlugin) :
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    Listenable,
    ActivityListener,
    StreamHandler {
  private val pendingResults: MutableMap<Int, Pair<MethodCall, MethodChannel.Result>> =
      mutableMapOf()
  private var channel: MethodChannel? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private var util: SafUtil? = null

  companion object {
    private const val CHANNEL = "documentfile"
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      OPEN_DOCUMENT_TREE ->
          if (Build.VERSION.SDK_INT >= API_21) {
            openDocumentTree(call, result)
          }
      GET_CACHED_FILES_PATH -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          getCachedFilesPath(call, result)
        }
      }
      CACHE_TO_EXTERNAL_FILES_DIRECTORY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          Thread(cacheToExternalFilesDir(call, result, plugin.context, util!!)).start()
        }
      }
      SINGLE_CACHE_TO_EXTERNAL_FILES_DIRECTORY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          singleCacheToExternalFilesDir(call, result, util!!)
        }
      }
      CLEAR_CACHED_FILES -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          result.success(util?.clearCachedFiles(call.argument<String>("cacheDirectoryName") as String))
        }
      }
      SYNC_WITH_EXTERNAL_FILES_DIRECTORY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          Thread(syncWithExternalFilesDirectory(call, result, plugin.context, util!!)).start()
        }
      }
      DYNAMIC_SYNC_WITH_EXTERNAL_FILES_DIRECTORY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          Thread(dynamicSyncWithExternalFilesDirectory(call, result, plugin.context, util!!)).start()
        }
      }
      GET_EXTERNAL_FILES_DIR_PATH -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          result.success(util?.getExternalFilesDirPath())
        }
      }
      CREATE_FILE ->
          if (Build.VERSION.SDK_INT >= API_21) {
            createFile(
                result,
                call.argument<String>("mimeType")!!,
                call.argument<String>("displayName")!!,
                call.argument<String>("directoryUri")!!,
                call.argument<ByteArray>("content")!!
            )
          }
      PERSISTED_URI_PERMISSIONS ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            persistedUriPermissions(result)
          }
      RELEASE_PERSISTABLE_URI_PERMISSION ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            releasePersistableUriPermission(result, call.argument<String?>("uri") as String)
          }
      FROM_TREE_URI ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                createDocumentFileMap(
                    documentFromUri(plugin.context, call.argument<String?>("uri") as String)
                )
            )
          }
      CAN_WRITE ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)?.canWrite()
            )
          }
      CAN_READ ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)?.canRead()
            )
          }
      LENGTH ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)?.length()
            )
          }
      EXISTS ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)?.exists()
            )
          }
      DELETE ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)?.delete()
            )
          }
      LAST_MODIFIED ->
          if (Build.VERSION.SDK_INT >= API_21) {
            result.success(
                documentFromUri(plugin.context, call.argument<String?>("uri") as String)
                    ?.lastModified()
            )
          }
      CREATE_DIRECTORY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val uri = call.argument<String?>("uri") as String
          val displayName = call.argument<String?>("displayName") as String

          val createdDirectory =
              documentFromUri(plugin.context, uri)?.createDirectory(displayName) ?: return

          result.success(createDocumentFileMap(createdDirectory))
        }
      }
      FIND_FILE -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val uri = call.argument<String?>("uri") as String
          val displayName = call.argument<String?>("displayName") as String

          result.success(
              createDocumentFileMap(documentFromUri(plugin.context, uri)?.findFile(displayName))
          )
        }
      }
      COPY -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val destination = Uri.parse(call.argument<String>("destination")!!)
          val uri = Uri.parse(call.argument<String>("uri")!!)

          if (Build.VERSION.SDK_INT >= API_24) {
            DocumentsContract.copyDocument(plugin.context.contentResolver, uri, destination)
          } else {
            val content = StringBuilder()

            readDocumentContent(uri) {
              onEnd =
                  {
                    val uriDocument = documentFromUri(plugin.context, uri)!!

                    createFile(
                        destination,
                        uriDocument.type!!,
                        uriDocument.name!!,
                        content.toString().toByteArray()
                    ) { result.success(createDocumentFileMap(this)) }
                  }
              onSuccess = { content.append(this) }
            }
          }
        }
      }
      RENAME_TO -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val uri = call.argument<String?>("uri") as String
          val displayName = call.argument<String?>("displayName") as String

          documentFromUri(plugin.context, uri)?.apply {
            val success = renameTo(displayName)

            result.success(
                if (success) createDocumentFileMap(documentFromUri(plugin.context, this.uri)!!)
                else null
            )
          }
        }
      }
      PARENT_FILE -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val uri = call.argument<String>("uri")!!
          val parent = documentFromUri(plugin.context, uri)?.parentFile

          result.success(if (parent != null) createDocumentFileMap(parent) else null)
        }
      }
      else -> result.notImplemented()
    }
  }

  @RequiresApi(API_21)
  private fun openDocumentTree(call: MethodCall, result: MethodChannel.Result) {
    val grantWritePermission = call.argument<Boolean>("grantWritePermission")!!
    val initialUri = call.argument<String>("initialUri")

    val intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
          addFlags(
              if (grantWritePermission) Intent.FLAG_GRANT_WRITE_URI_PERMISSION
              else Intent.FLAG_GRANT_READ_URI_PERMISSION
          )

          if (initialUri != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
              putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(initialUri))
            }
          }
        }

    if (pendingResults[OPEN_DOCUMENT_TREE_CODE] != null) return

    pendingResults[OPEN_DOCUMENT_TREE_CODE] = Pair(call, result)

    plugin.binding?.activity?.startActivityForResult(intent, OPEN_DOCUMENT_TREE_CODE)
  }

  @RequiresApi(API_21)
  private fun createFile(
      result: MethodChannel.Result,
      mimeType: String,
      displayName: String,
      directory: String,
      content: ByteArray
  ) {
    createFile(Uri.parse(directory), mimeType, displayName, content) {
      result.success(createDocumentFileMap(this))
    }
  }

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
  private fun createFile(
      treeUri: Uri,
      mimeType: String,
      displayName: String,
      content: ByteArray,
      block: DocumentFile?.() -> Unit
  ) {

    val createdFile = documentFromUri(plugin.context, treeUri)!!.createFile(mimeType, displayName)

    createdFile?.uri?.apply {
      plugin.context.contentResolver.openOutputStream(this)?.apply {
        write(content)
        flush()

        val createdFileDocument = documentFromUri(plugin.context, createdFile.uri)

        block(createdFileDocument)
      }
    }
  }

  @RequiresApi(API_19)
  private fun persistedUriPermissions(result: MethodChannel.Result) {
    val persistedUriPermissions = plugin.context.contentResolver.persistedUriPermissions

    result.success(
        persistedUriPermissions
            .map {
              mapOf(
                  "isReadPermission" to it.isReadPermission,
                  "isWritePermission" to it.isWritePermission,
                  "persistedTime" to it.persistedTime,
                  "uri" to "${it.uri}"
              )
            }
            .toList()
    )
  }

  @RequiresApi(API_19)
  private fun releasePersistableUriPermission(result: MethodChannel.Result, directoryUri: String) {
    try {
      plugin.context.contentResolver.releasePersistableUriPermission(
          Uri.parse(directoryUri),
          Intent.FLAG_GRANT_WRITE_URI_PERMISSION
      )
      result.success(null)
    }
    catch(e: Exception) {
      Log.e("RELEASE_PERMISSION_EXCEPTION", e.message!!)
      result.success(null)
    }
  }

  @RequiresApi(API_19)
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    when (requestCode) {
      OPEN_DOCUMENT_TREE_CODE -> {
        val pendingResult = pendingResults[OPEN_DOCUMENT_TREE_CODE] ?: return false

        try {
          val uri = data?.data

          if (uri != null) {
            plugin.context.contentResolver.takePersistableUriPermission(
                uri,
                if (pendingResult.first.argument<Boolean>("grantWritePermission")!!)
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                else Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            pendingResult.second.success("$uri")
            return true
          }
          pendingResult.second.success(null)
        } finally {
          pendingResults.remove(OPEN_DOCUMENT_TREE_CODE)
        }
      }
    }

    return false
  }

  override fun startListening(binaryMessenger: BinaryMessenger) {
    if (channel != null) stopListening()

    channel = MethodChannel(binaryMessenger, "$ROOT_CHANNEL/$CHANNEL")
    util = SafUtil(plugin.context)
    channel?.setMethodCallHandler(this)

    eventChannel = EventChannel(binaryMessenger, "$ROOT_CHANNEL/event/$CHANNEL")
    eventChannel?.setStreamHandler(this)
  }

  override fun stopListening() {
    if (channel == null) return

    channel?.setMethodCallHandler(null)
    channel = null

    eventChannel?.setStreamHandler(null)
    eventChannel = null
  }

  override fun startListeningToActivity() {
    plugin.binding?.addActivityResultListener(this)
  }

  override fun stopListeningToActivity() {
    plugin.binding?.removeActivityResultListener(this)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    val args = arguments as Map<*, *>

    eventSink = events

    when (args["event"]) {
      LIST_FILES -> {
        if (eventSink == null) return

        val document =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
              documentFromUri(plugin.context, args["uri"] as String) ?: return
            } else {
              null
            }

        if (document == null) {
          eventSink?.error(
              EXCEPTION_NOT_SUPPORTED,
              "Android SDK must be greater or equal than [Build.VERSION_CODES.N]",
              "Got (Build.VERSION.SDK_INT): ${Build.VERSION.SDK_INT}"
          )
        } else {
          val columns = args["columns"] as List<*>

          if (!document.canRead()) {
            val error = "You cannot read a URI that you don't have read permissions"

            Log.d("NO PERMISSION!!!", error)

            eventSink?.error(EXCEPTION_MISSING_PERMISSIONS, error, mapOf("uri" to args["uri"]))
          } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
              CoroutineScope(Dispatchers.Default).launch {
                traverseDirectoryEntries(
                    plugin.context.contentResolver,
                    rootOnly = true,
                    rootUri = document.uri,
                    columns =
                        columns
                            .map {
                              parseDocumentFileColumn(parseDocumentFileColumn(it as String)!!)!!
                            }
                            .toTypedArray()
                ) { data -> launch(Dispatchers.Main) { eventSink?.success(data) } }
              }
            }
          }
        }
      }
      GET_DOCUMENT_CONTENT -> {
        if (Build.VERSION.SDK_INT >= API_21) {
          val uri = Uri.parse(args["uri"] as String)

          readDocumentContent(uri) {
            onSuccess = { eventSink?.success(this) }
            onEnd = { eventSink?.endOfStream() }
          }
        } else {
          eventSink?.endOfStream()
        }
      }
    }
  }

  @RequiresApi(API_21)
  private fun readDocumentContent(uri: Uri, handler: CallbackHandler<String>.() -> Unit) {
    val callbacks = CallbackHandler<String>().apply { handler(this) }

    plugin.context.contentResolver.openInputStream(uri)?.use { inputStream ->
      BufferedReader(InputStreamReader(inputStream)).use { reader ->
        var line = reader.readLine()

        while (line != null) {
          callbacks.onSuccess?.invoke(line)

          line = reader.readLine()
        }

        callbacks.onEnd?.invoke()
      }
    }
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun getCachedFilesPath(call: MethodCall, result: MethodChannel.Result) {
    try {
      val cacheDirectoryName = call.argument<String>("cacheDirectoryName")

      val externalFilesDir: File = plugin.context.getExternalFilesDir(null)!!
      val appCacheDirectory: File = File(externalFilesDir.path + "/" + cacheDirectoryName)

      var paths = listOf<String>()
      appCacheDirectory.walk().forEach {
        var path = it.path.toString()
        paths += path
      }

      result.success(paths)
    }
    catch(e: Exception) {
      Log.e("GET_CACHED_FILES_PATH_EXCEPTION", e.message!!)
      result.success(null)
    }
  }

  internal class cacheToExternalFilesDir(private val call: MethodCall, private val result: MethodChannel.Result, private val context: Context, private val util: SafUtil): Runnable {
    override fun run() {
      try {
        val sourceTreeUriString = call.argument<String>("sourceTreeUriString")
        val cacheDirectoryName = call.argument<String>("cacheDirectoryName")
        val fileType = call.argument<String>("fileType")
  
        var cachedFilesPath = listOf<String>()
        
        val sourceTreeUri: Uri = Uri.parse(sourceTreeUriString)
        val sourceChildDocumentsUri = buildChildDocumentsUriUsingTree(sourceTreeUri, context.contentResolver)
        for (uri in sourceChildDocumentsUri!!) {
          val fileName = nameFromFileUri(uri).toString()
          if(fileName.contains(fileType.toString()) || fileType == "any") {
            val copiedPath: String? = util.syncCopyFileToExternalStorage(uri, cacheDirectoryName!!, fileName)
            if(copiedPath != null) cachedFilesPath += copiedPath.toString()
          }
        }
        result.success(cachedFilesPath)
      } catch (e: Exception) {
        Log.e("CACHING_EXCEPTION", e.message!!)
        result.success(null)
      }
    }
  }

  internal class singleCacheToExternalFilesDir(private val call: MethodCall, private val result: MethodChannel.Result, private val util: SafUtil): Runnable {
    override fun run() {
      try {
        val sourceUriString = call.argument<String>("sourceUriString")
        val cacheDirectoryName = call.argument<String>("cacheDirectoryName")
  
        var cachedFilePath: String? = null
        val sourceUri: Uri = Uri.parse(sourceUriString)
        val copiedPath: String? = util.syncCopyFileToExternalStorage(sourceUri, cacheDirectoryName!!, nameFromFileUri(sourceUri).toString())
        if(copiedPath != null) cachedFilePath = copiedPath.toString()
  
        result.success(cachedFilePath)
      } catch (e: Exception) {
        Log.e("SINGLE_CACHING_EXCEPTION", e.message!!)
        result.success(null)
      }
    }
  }

  internal class syncWithExternalFilesDirectory(private val call: MethodCall, private val result: MethodChannel.Result, private val context: Context, private val util: SafUtil): Runnable {
    override fun run() {
      try {
        val sourceTreeUriString = call.argument<String>("sourceTreeUriString")
        val cacheDirectoryName = call.argument<String>("cacheDirectoryName")
        
        val sourceTreeUri: Uri = Uri.parse(sourceTreeUriString)
        var sourceChildDocumentsUri = buildChildDocumentsUriUsingTree(sourceTreeUri, context.contentResolver)
  
        val externalFilesDir: File = context.getExternalFilesDir(null)!!
        val appCacheDirectory: File = File(externalFilesDir.path + "/" + cacheDirectoryName)
        val cachedFilesNameToPathMap: HashMap<String, String> = HashMap<String, String>()
        appCacheDirectory.walk().forEach {
          if(it.isFile()) {
            cachedFilesNameToPathMap[it.getName()] = it.path.toString()
          }
        }
        val sourceFilesNameToBooleanMap: HashMap<String, Boolean> = HashMap<String, Boolean>()
        for (uri in sourceChildDocumentsUri!!) {
          sourceFilesNameToBooleanMap[nameFromFileUri(uri).toString()] = true
        }
  
        for (name in cachedFilesNameToPathMap.keys) {
          if (sourceFilesNameToBooleanMap.containsKey(name) == false) {
            File(cachedFilesNameToPathMap[name]!!).delete()
          }
        }
  
        for (uri in sourceChildDocumentsUri) {
          util.syncCopyFileToExternalStorage(uri, cacheDirectoryName!!, nameFromFileUri(uri).toString())
        }
        Handler(Looper.getMainLooper()).post {
          result.success(true)
        }
      } catch (e: Exception) {
        Log.e("SYNCING_EXCEPTION", e.message!!)
        result.success(null)
      }
    }
  }

  internal class dynamicSyncWithExternalFilesDirectory(private val call: MethodCall, private val result: MethodChannel.Result, private val context: Context, private val util: SafUtil): Runnable {
    override fun run() {
      try {
        val sourceTreeUriString = call.argument<String>("sourceTreeUriString")
        val cacheDirectoryName = call.argument<String>("cacheDirectoryName")
        
        val sourceTreeUri: Uri = Uri.parse(sourceTreeUriString)
        var sourceChildDocumentsUri = buildChildDocumentsUriUsingTree(sourceTreeUri, context.contentResolver)
  
        val externalFilesDir: File = context.getExternalFilesDir(null)!!
        val appCacheDirectory: File = File(externalFilesDir.path + "/" + cacheDirectoryName)
        val cachedFilesNameToPathMap: HashMap<String, String> = HashMap<String, String>()
        appCacheDirectory.walk().forEach {
          if(it.isFile()) {
            cachedFilesNameToPathMap[it.getName()] = it.path.toString()
          }
        }
        val sourceFilesNameToBooleanMap: HashMap<String, Boolean> = HashMap<String, Boolean>()
        for (uri in sourceChildDocumentsUri!!) {
          sourceFilesNameToBooleanMap[nameFromFileUri(uri).toString()] = true
        }
  
        for (name in cachedFilesNameToPathMap.keys) {
          if (sourceFilesNameToBooleanMap.containsKey(name) == false) {
            File(cachedFilesNameToPathMap[name]!!).delete()
          }
        }
  
        for (uri in sourceChildDocumentsUri) {
          util.syncCopyFileToExternalStorage(uri, cacheDirectoryName!!, nameFromFileUri(uri).toString())
        }
        result.success(true)
      } catch (e: Exception) {
        Log.e("SYNCING_EXCEPTION", e.message!!)
        result.success(null)
      }
    }
  }
}