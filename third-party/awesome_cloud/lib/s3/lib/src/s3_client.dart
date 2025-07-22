import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../s3_storage.dart';
import 's3_sign.dart';
import 'aws_endpoints.dart';

import 's3.dart';
import 'utils.dart';
import 's3_helpers.dart';

class StorageRequest extends BaseRequest {
  StorageRequest(super.method, super.url, {this.onProgress});

  dynamic body;

  final void Function(int)? onProgress;

  @override
  ByteStream finalize() {
    super.finalize();

    if (body == null) {
      return const ByteStream(Stream.empty());
    }

    late Stream<Uint8List> stream;

    if (body is Stream<Uint8List>) {
      stream = body;
    } else if (body is String) {
      final data = const Utf8Encoder().convert(body);
      headers['content-length'] = data.length.toString();
      stream = Stream<Uint8List>.value(data);
    } else if (body is Uint8List) {
      stream = Stream<Uint8List>.value(body);
      headers['content-length'] = body.length.toString();
    } else {
      throw UnsupportedError('Unsupported body type: ${body.runtimeType}');
    }

    if (onProgress == null) {
      return ByteStream(stream);
    }

    var bytesRead = 0;

    stream = stream.transform(MaxChunkSize(1 << 16));

    return ByteStream(
      stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(data);
            bytesRead += data.length;
            onProgress!(bytesRead);
          },
        ),
      ),
    );
  }

  StorageRequest replace({
    String? method,
    Uri? url,
    Map<String, String>? headers,
    body,
  }) {
    final result = StorageRequest(method ?? this.method, url ?? this.url);
    result.body = body ?? this.body;
    result.headers.addAll(headers ?? this.headers);
    return result;
  }
}

/// An HTTP response where the entire response body is known in advance.
class StorageResponse extends BaseResponse {
  /// The bytes comprising the body of this response.
  final Uint8List bodyBytes;

  /// Body of s3 response is always encoded as UTF-8.
  String get body => utf8.decode(bodyBytes);

  /// Create a new HTTP response with a byte array body.
  StorageResponse.bytes(
    this.bodyBytes,
    int statusCode, {
    BaseRequest? request,
    Map<String, String> headers = const {},
    bool isRedirect = false,
    bool persistentConnection = true,
    String? reasonPhrase,
  }) : super(statusCode,
            contentLength: bodyBytes.length,
            request: request,
            headers: headers,
            isRedirect: isRedirect,
            persistentConnection: persistentConnection,
            reasonPhrase: reasonPhrase);

  static Future<StorageResponse> fromStream(StreamedResponse response) async {
    final body = await response.stream.toBytes();
    return StorageResponse.bytes(body, response.statusCode,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase);
  }
}

class StorageClient {
  StorageClient(this.s3storage, this.signingType) {
    anonymous = s3storage.accessKey.isEmpty && s3storage.secretKey.isEmpty;
    enableSHA256 = !anonymous && !s3storage.useSSL;
    port = s3storage.port;
  }

  final S3Storage s3storage;
  late SigningType signingType;

  late bool enableSHA256;
  late bool anonymous;
  late final int port;

  Future<StreamedResponse> _request({
    required String method,
    String? bucket,
    String? object,
    String? region,
    String? resource,
    SigningType signingType = SigningType.V4,
    dynamic payload = '',
    Map<String, dynamic>? queries,
    Map<String, String>? headers,
    void Function(int)? onProgress,
  }) async {
    if (bucket != null) {
      region ??= await s3storage.getBucketRegion(bucket);
    }

    region ??= 'us-east-1';

    final request = getBaseRequest(
        method, bucket, object, region, resource, queries, headers, onProgress);
    request.body = payload;

    final date = DateTime.now().toUtc();
    if (signingType == SigningType.V4) {
      final sha256sum = enableSHA256 ? sha256Hex(payload) : 'UNSIGNED-PAYLOAD';
      request.headers.addAll({
        'user-agent': s3storage.userAgent,
        'x-amz-date': makeDateLong(date),
        'x-amz-content-sha256': sha256sum,
      });

      final authorization = signV4(s3storage, request, date, region);

      request.headers['authorization'] = authorization;
    } else {
      request.headers.addAll({
        'user-agent': s3storage.userAgent,
        'date': toRfc7231Time(date),
      });
      final authorization = signV2(s3storage, request, date,
          request.url.toString().replaceAll(request.url.origin, ''),
          md5: request.headers['Content-MD5'],
          contentType: request.headers['Content-Type']);

      request.headers['authorization'] = authorization;
    }

    logRequest(request);
    final response = await request.send();
    return response;
  }

  Future<StorageResponse> request({
    required String method,
    String? bucket,
    String? object,
    String? region,
    String? resource,
    dynamic payload = '',
    Map<String, dynamic>? queries,
    Map<String, String>? headers,
    void Function(int)? onProgress,
  }) async {
    final stream = await _request(
      method: method,
      bucket: bucket,
      signingType: signingType,
      object: object,
      region: region,
      payload: payload,
      resource: resource,
      queries: queries,
      headers: headers,
      onProgress: onProgress,
    );

    final response = await StorageResponse.fromStream(stream);
    logResponse(response);

    return response;
  }

  Future<StreamedResponse> requestStream({
    required String method,
    String? bucket,
    String? object,
    String? region,
    String? resource,
    dynamic payload = '',
    Map<String, dynamic>? queries,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: method,
      bucket: bucket,
      object: object,
      region: region,
      payload: payload,
      resource: resource,
      queries: queries,
      headers: headers,
    );

    logResponse(response);
    return response;
  }

  StorageRequest getBaseRequest(
    String method,
    String? bucket,
    String? object,
    String region,
    String? resource,
    Map<String, dynamic>? queries,
    Map<String, String>? headers,
    void Function(int)? onProgress,
  ) {
    final url = getRequestUrl(bucket, object, resource, queries);
    final request = StorageRequest(method, url, onProgress: onProgress);
    request.headers['host'] = url.authority;

    if (headers != null) {
      request.headers.addAll(headers);
    }

    return request;
  }

  Uri getRequestUrl(
    String? bucket,
    String? object,
    String? resource,
    Map<String, dynamic>? queries,
  ) {
    var host = s3storage.endPoint.toLowerCase();
    var path = '/';

    if (isAmazonEndpoint(host)) {
      host = getS3Endpoint(s3storage.region!);
    }

    if (isVirtualHostStyle(host, s3storage.useSSL, bucket)) {
      if (bucket != null) host = '$bucket.$host';
      if (object != null) path = '/$object';
    } else {
      if (bucket != null) path = '/$bucket';
      if (object != null) path = '/$bucket/$object';
    }

    final query = StringBuffer();
    if (resource != null) {
      query.write(resource);
    }
    if (queries != null) {
      if (query.isNotEmpty) query.write('&');
      query.write(encodeQueries(queries));
    }

    return Uri(
      scheme: s3storage.useSSL ? 'https' : 'http',
      host: host,
      port: s3storage.port,
      pathSegments: path.split('/'),
      query: query.toString(),
    );
  }

  void logRequest(StorageRequest request) {
    if (!s3storage.enableTrace) return;

    final buffer = StringBuffer();
    buffer.writeln('REQUEST: ${request.method} ${request.url}');
    for (var header in request.headers.entries) {
      buffer.writeln('${header.key}: ${header.value}');
    }

    if (request.body is List<int>) {
      buffer.writeln('List<int> of size ${request.body.length}');
    } else {
      buffer.writeln(request.body);
    }

    debugPrint(buffer.toString());
  }

  void logResponse(BaseResponse response) {
    if (!s3storage.enableTrace) return;

    final buffer = StringBuffer();
    buffer.writeln('RESPONSE: ${response.statusCode} ${response.reasonPhrase}');
    for (var header in response.headers.entries) {
      buffer.writeln('${header.key}: ${header.value}');
    }

    if (response is Response) {
      buffer.writeln(response.body);
    } else if (response is StreamedResponse) {
      buffer.writeln('STREAMED BODY');
    }

    debugPrint(buffer.toString());
  }
}
