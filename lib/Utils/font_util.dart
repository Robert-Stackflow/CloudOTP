import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import './ilogger.dart';

enum _FontSource { asset, file, url }

class FontUtil {
  final String fontFamily;
  final String uri;
  final _FontSource _source;

  /// Use the font from AssetBundle, [key] is the same as in [rootBundle.load]
  FontUtil.asset({required this.fontFamily, required String key})
      : _source = _FontSource.asset,
        uri = key;

  /// Use the font from [filepath]
  FontUtil.file({required this.fontFamily, required String filepath})
      : _source = _FontSource.file,
        uri = filepath;

  bool? overwrite;

  /// Download the font, save to the device, then use it when needed
  FontUtil.url({
    required this.fontFamily,
    required String url,
    this.overwrite,
  })  : _source = _FontSource.url,
        uri = url;

  Future<bool> load({Function(double)? onReceiveProgress}) async {
    switch (_source) {
      case _FontSource.asset:
        try {
          final loader = FontLoader(fontFamily);
          final fontData = rootBundle.load(uri);
          loader.addFont(fontData);
          await loader.load();
          return true;
        } catch (e, t) {
          ILogger.error("Failed to load font asset", e, t);
          return false;
        }
      case _FontSource.file:
        if (!await File(uri).exists()) return false;
        try {
          await loadFontFromList(
            await File(uri).readAsBytes(),
            fontFamily: fontFamily,
          );
          return true;
        } catch (e, t) {
          ILogger.error("Failed to load font file", e, t);
          return false;
        }
      case _FontSource.url:
        try {
          await loadFontFromList(
            await downloadFont(
              uri,
              overwrite: overwrite ?? false,
              onReceiveProgress: onReceiveProgress,
            ),
            fontFamily: fontFamily,
          );
          return true;
        } catch (e, t) {
          ILogger.error("Failed to download font", e, t);
          return false;
        }
    }
  }
}

Future<Uint8List> downloadFont(
  String url, {
  bool overwrite = false,
  Function(double)? onReceiveProgress,
}) async {
  final uri = Uri.parse(url);
  final filename = uri.pathSegments.last;
  final dir = (await getApplicationSupportDirectory()).path;
  final file = File('$dir/$filename');

  if (await file.exists() && !overwrite) {
    return await file.readAsBytes();
  }

  final bytes = await downloadBytes(uri, onReceiveProgress: onReceiveProgress);
  file.writeAsBytes(bytes);
  return bytes;
}

Future<void> downloadFontTo(String url,
    {required String filepath, bool overwrite = false}) async {
  final uri = Uri.parse(url);
  final file = File(filepath);

  if (await file.exists() && !overwrite) return;
  await file.writeAsBytes(await downloadBytes(uri));
}

Future<Uint8List> downloadBytes(
  Uri uri, {
  Function(double)? onReceiveProgress,
}) async {
  final client = http.Client();
  final request = http.Request('GET', uri);
  final response =
      await client.send(request).timeout(const Duration(seconds: 5));

  if (response.statusCode != 200) {
    throw HttpException("status code ${response.statusCode}");
  }

  List<int> bytes = [];
  double prevPercent = 0;
  await response.stream.listen((List<int> chunk) {
    bytes.addAll(chunk);

    if (response.contentLength == null) {
      ILogger.info('Download font: ${bytes.length} bytes');
    } else {
      final percent = (bytes.length / response.contentLength!);
      onReceiveProgress?.call(percent);
      if (percent - prevPercent > 15 || percent > 99) {
        ILogger.info('Downloading font: ${(percent * 100).toStringAsFixed(1)}%');
        prevPercent = percent;
      }
    }
  }).asFuture();

  return Uint8List.fromList(bytes);
}
