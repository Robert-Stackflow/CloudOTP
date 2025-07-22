import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 's3.dart';
import 's3_client.dart';
import 's3_errors.dart';
import 's3_helpers.dart';
import 'utils.dart';

const signV4Algorithm = 'AWS4-HMAC-SHA256';

String signV4(
  S3Storage s3storage,
  StorageRequest request,
  DateTime requestDate,
  String region,
) {
  final signedHeaders = getSignedHeaders(request.headers.keys);
  final hashedPayload = request.headers['x-amz-content-sha256'];
  final canonicalRequest =
      getCanonicalRequest(request, signedHeaders, hashedPayload!);
  final stringToSign = getStringToSign(canonicalRequest, requestDate, region);
  final signingKey = getSigningKey(requestDate, region, s3storage.secretKey);
  final credential = getCredential(s3storage.accessKey, region, requestDate);
  final signature = hex.encode(
    Hmac(sha256, signingKey).convert(stringToSign.codeUnits).bytes,
  );
  return '$signV4Algorithm Credential=$credential, SignedHeaders=${signedHeaders.join(';').toLowerCase()}, Signature=$signature';
}

String signV2(
  S3Storage s3storage,
  StorageRequest request,
  DateTime requestDate,
  String requestPath, {
  String? md5,
  String? contentType,
}) {
  final date = toRfc7231Time(DateTime.now().toUtc());
  final awsHeaders = getAWSHeader(request.headers);
  final header =
      '${request.method}\n${md5 ?? ''}\n${contentType ?? ''}\n$date\n${awsHeaders.isNotEmpty ? '${awsHeaders.entries.map((e) => '${e.key}:${e.value}').join('\n')}\n' : ''}$requestPath';

  final sign = Hmac(sha1, utf8.encode(s3storage.secretKey))
      .convert(utf8.encode(header))
      .bytes;
  final secret = base64Encode(sign);

  return 'AWS ${s3storage.accessKey}:$secret';
}

List<String> getSignedHeaders(Iterable<String> headers) {
  const ignored = {
    'authorization',
    'content-length',
    'content-type',
    'user-agent'
  };
  final result = headers
      .where((header) => !ignored.contains(header.toLowerCase()))
      .toList();
  result.sort();
  return result;
}

Map<String, String> getAWSHeader(Map<String, String> headers) {
  final result = headers.entries
      .where((header) => header.key.toLowerCase().startsWith('x-amz'))
      .toList();
  result.sort((a, b) => a.key.compareTo(b.key));
  return Map<String, String>.fromEntries(result);
}

String getCanonicalRequest(
  StorageRequest request,
  List<String> signedHeaders,
  String hashedPayload,
) {
  final requestResource = encodePath(request.url);
  final headers = signedHeaders.map(
    (header) => '${header.toLowerCase()}:${request.headers[header]}',
  );

  final queryKeys = request.url.queryParameters.keys.toList();
  queryKeys.sort();
  final requestQuery = queryKeys.map((key) {
    final value = request.url.queryParameters[key];
    final hasValue = value != null;
    final valuePart = hasValue ? encodeCanonicalQuery(value!) : '';
    return encodeCanonicalQuery(key) + '=' + valuePart;
  }).join('&');

  final canonical = [];
  canonical.add(request.method.toUpperCase());
  canonical.add(requestResource);
  canonical.add(requestQuery);
  canonical.add(headers.join('\n') + '\n');
  canonical.add(signedHeaders.join(';').toLowerCase());
  canonical.add(hashedPayload);
  return canonical.join('\n');
}

String getStringToSign(
  String canonicalRequest,
  DateTime requestDate,
  String region,
) {
  final hash = sha256Hex(canonicalRequest);
  final scope = getScope(region, requestDate);
  final stringToSign = [];
  stringToSign.add(signV4Algorithm);
  stringToSign.add(makeDateLong(requestDate));
  stringToSign.add(scope);
  stringToSign.add(hash);
  return stringToSign.join('\n');
}

String getScope(String region, DateTime date) {
  return '${makeDateShort(date)}/$region/s3/aws4_request';
}

List<int> getSigningKey(DateTime date, String region, String secretKey) {
  final dateLine = makeDateShort(date);
  final key1 = ('AWS4' + secretKey).codeUnits;
  final hmac1 = Hmac(sha256, key1).convert(dateLine.codeUnits).bytes;
  final hmac2 = Hmac(sha256, hmac1).convert(region.codeUnits).bytes;
  final hmac3 = Hmac(sha256, hmac2).convert('s3'.codeUnits).bytes;
  return Hmac(sha256, hmac3).convert('aws4_request'.codeUnits).bytes;
}

String getCredential(String accessKey, String region, DateTime requestDate) {
  return '$accessKey/${getScope(region, requestDate)}';
}

// returns a presigned URL string
String presignSignatureV4(
  S3Storage s3storage,
  StorageRequest request,
  String region,
  DateTime requestDate,
  int expires,
) {
  if (expires < 1) {
    throw StorageExpiresParamError(
        'expires param cannot be less than 1 seconds');
  }
  if (expires > 604800) {
    throw StorageExpiresParamError(
        'expires param cannot be greater than 7 days');
  }

  final iso8601Date = makeDateLong(requestDate);
  final signedHeaders = getSignedHeaders(request.headers.keys);
  final credential = getCredential(s3storage.accessKey, region, requestDate);

  final requestQuery = <String, String?>{};
  requestQuery['X-Amz-Algorithm'] = signV4Algorithm;
  requestQuery['X-Amz-Credential'] = credential;
  requestQuery['X-Amz-Date'] = iso8601Date;
  requestQuery['X-Amz-Expires'] = expires.toString();
  requestQuery['X-Amz-SignedHeaders'] = signedHeaders.join(';').toLowerCase();
  if (s3storage.sessionToken != null) {
    requestQuery['X-Amz-Security-Token'] = s3storage.sessionToken;
  }

  request = request.replace(
    url: request.url.replace(queryParameters: {
      ...request.url.queryParameters,
      ...requestQuery,
    }),
  );

  final canonicalRequest =
      getCanonicalRequest(request, signedHeaders, 'UNSIGNED-PAYLOAD');

  final stringToSign = getStringToSign(canonicalRequest, requestDate, region);
  final signingKey = getSigningKey(requestDate, region, s3storage.secretKey);
  final signature = sha256HmacHex(stringToSign, signingKey);
  final presignedUrl = request.url.toString() + '&X-Amz-Signature=$signature';

  return presignedUrl;
}

// calculate the signature of the POST policy
String postPresignSignatureV4(
  String region,
  DateTime date,
  String secretKey,
  String policyBase64,
) {
  final signingKey = getSigningKey(date, region, secretKey);
  return sha256HmacHex(policyBase64, signingKey);
}
