import 'package:flutter/services.dart';

const kRootChannel = 'com.ivehement.plugins/saf';

/// Method Channels of this plugin
///
/// Flutter uses this to communicate with native Android
/// Target [Environment] Android API (Legacy and you should avoid it)
const kEnvironmentChannel = MethodChannel('$kRootChannel/environment');

/// Target [DocumentFile] from `SAF` Android API (New Android API's use it)
const kDocumentFileChannel = MethodChannel('$kRootChannel/documentfile');

/// Target [DocumentsContract] from `SAF` Android API (New Android API's use it)
const kDocumentsContractChannel =
    MethodChannel('$kRootChannel/documentscontract');

/// Event Channels of this plugin
const kDocumentFileEventChannel =
    EventChannel('$kRootChannel/event/documentfile');
