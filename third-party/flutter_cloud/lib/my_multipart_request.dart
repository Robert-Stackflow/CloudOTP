import 'dart:convert';

import 'package:http/http.dart';

final _newlineRegExp = RegExp(r'\r\n|\r|\n');

final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

class MyMultipartRequest extends BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body.
  ///
  /// According to http://tools.ietf.org/html/rfc1341.html, this can't be longer
  /// than 70.
  int get _boundaryLength => boundary.length;

  /// The form fields to send for this request.
  final fields = <String, String>{};

  /// The list of files to upload for this request.
  final files = <MultipartFile>[];

  final String boundary;

  MyMultipartRequest(super.method, super.url, this.boundary);

  /// The total length of the request body, in bytes.
  ///
  /// This is calculated from [fields] and [files] and cannot be set manually.
  @override
  int get contentLength {
    var length = 0;

    fields.forEach((name, value) {
      length += '--'.length +
          _boundaryLength +
          '\r\n'.length +
          utf8.encode(_headerForField(name, value)).length +
          utf8.encode(value).length +
          '\r\n'.length;
    });

    for (var file in files) {
      length += '--'.length +
          _boundaryLength +
          '\r\n'.length +
          utf8.encode(_headerForFile(file)).length +
          file.length +
          '\r\n'.length;
    }

    return length + '--'.length + _boundaryLength + '--\r\n'.length;
  }

  @override
  set contentLength(int? value) {
    throw UnsupportedError('Cannot set the contentLength property of '
        'multipart requests.');
  }

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  @override
  ByteStream finalize() {
    headers['content-type'] = 'multipart/related; boundary=$boundary';
    super.finalize();
    return ByteStream(_finalize(boundary));
  }

  Stream<List<int>> _finalize(String boundary) async* {
    const line = [13, 10]; // \r\n
    final separator = utf8.encode('--$boundary\r\n');
    final close = utf8.encode('--$boundary--\r\n');

    for (var field in fields.entries) {
      yield separator;
      yield utf8.encode(_headerForField(field.key, field.value));
      yield utf8.encode(field.value);
      yield line;
    }

    for (final file in files) {
      yield separator;
      yield utf8.encode(_headerForFile(file));
      yield* file.finalize();
      yield line;
    }
    yield close;
  }

  /// Returns the header string for a field.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForField(String name, String value) {
    var header =
        'content-disposition: form-data; name="${_browserEncode(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
          'content-type: text/plain; charset=utf-8\r\n'
          'content-transfer-encoding: binary';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForFile(MultipartFile file) {
    var header = 'content-type: ${file.contentType}\r\n'
        'content-disposition: form-data; name="${_browserEncode(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename!)}"';
    }
    return '$header\r\n\r\n';
  }

  /// Encode [value] in the same way browsers do.
  String _browserEncode(String value) =>
      // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
      // field names and file names, but in practice user agents seem not to
      // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
      // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
      // characters). We follow their behavior.
      value.replaceAll(_newlineRegExp, '%0D%0A').replaceAll('"', '%22');
}

const List<int> boundaryCharacters = <int>[
  43,
  95,
  45,
  46,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122
];
