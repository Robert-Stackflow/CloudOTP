/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

//
//  Generated code. Do not modify.
//  source: cloudotp_token_payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use cloudOtpTokenAlgorithmDescriptor instead')
const CloudOtpTokenAlgorithm$json = {
  '1': 'CloudOtpTokenAlgorithm',
  '2': [
    {'1': 'ALGORITHM_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SHA1', '2': 1},
    {'1': 'SHA256', '2': 2},
    {'1': 'SHA512', '2': 3},
  ],
};

/// Descriptor for `CloudOtpTokenAlgorithm`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cloudOtpTokenAlgorithmDescriptor =
    $convert.base64Decode(
        'ChZDbG91ZE90cFRva2VuQWxnb3JpdGhtEh4KGkFMR09SSVRITV9UWVBFX1VOU1BFQ0lGSUVEEA'
        'ASCAoEU0hBMRABEgoKBlNIQTI1NhACEgoKBlNIQTUxMhAD');

@$core.Deprecated('Use cloudOtpTokenDigitCountDescriptor instead')
const CloudOtpTokenDigitCount$json = {
  '1': 'CloudOtpTokenDigitCount',
  '2': [
    {'1': 'DIGIT_COUNT_UNSPECIFIED', '2': 0},
    {'1': 'FIVE', '2': 1},
    {'1': 'SIX', '2': 2},
    {'1': 'SEVEN', '2': 3},
    {'1': 'EIGHT', '2': 4},
  ],
};

/// Descriptor for `CloudOtpTokenDigitCount`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cloudOtpTokenDigitCountDescriptor =
    $convert.base64Decode(
        'ChdDbG91ZE90cFRva2VuRGlnaXRDb3VudBIbChdESUdJVF9DT1VOVF9VTlNQRUNJRklFRBAAEg'
        'gKBEZJVkUQARIHCgNTSVgQAhIJCgVTRVZFThADEgkKBUVJR0hUEAQ=');

@$core.Deprecated('Use cloudOtpTokenTypeDescriptor instead')
const CloudOtpTokenType$json = {
  '1': 'CloudOtpTokenType',
  '2': [
    {'1': 'OTP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TOTP', '2': 1},
    {'1': 'HOTP', '2': 2},
    {'1': 'MOTP', '2': 3},
    {'1': 'STEAM', '2': 4},
    {'1': 'YANDEX', '2': 5},
  ],
};

/// Descriptor for `CloudOtpTokenType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cloudOtpTokenTypeDescriptor = $convert.base64Decode(
    'ChFDbG91ZE90cFRva2VuVHlwZRIYChRPVFBfVFlQRV9VTlNQRUNJRklFRBAAEggKBFRPVFAQAR'
    'IICgRIT1RQEAISCAoETU9UUBADEgkKBVNURUFNEAQSCgoGWUFOREVYEAU=');

@$core.Deprecated('Use cloudOtpTokenPayloadDescriptor instead')
const CloudOtpTokenPayload$json = {
  '1': 'CloudOtpTokenPayload',
  '2': [
    {
      '1': 'token_parameters',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.CloudOtpTokenParameters',
      '10': 'tokenParameters'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'batch_index', '3': 4, '4': 1, '5': 5, '10': 'batchIndex'},
    {'1': 'batch_id', '3': 5, '4': 1, '5': 5, '10': 'batchId'},
  ],
};

/// Descriptor for `CloudOtpTokenPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cloudOtpTokenPayloadDescriptor = $convert.base64Decode(
    'ChRDbG91ZE90cFRva2VuUGF5bG9hZBJDChB0b2tlbl9wYXJhbWV0ZXJzGAEgAygLMhguQ2xvdW'
    'RPdHBUb2tlblBhcmFtZXRlcnNSD3Rva2VuUGFyYW1ldGVycxIYCgd2ZXJzaW9uGAIgASgFUgd2'
    'ZXJzaW9uEh0KCmJhdGNoX3NpemUYAyABKAVSCWJhdGNoU2l6ZRIfCgtiYXRjaF9pbmRleBgEIA'
    'EoBVIKYmF0Y2hJbmRleBIZCghiYXRjaF9pZBgFIAEoBVIHYmF0Y2hJZA==');

@$core.Deprecated('Use cloudOtpTokenParametersDescriptor instead')
const CloudOtpTokenParameters$json = {
  '1': 'CloudOtpTokenParameters',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'issuer', '3': 2, '4': 1, '5': 9, '10': 'issuer'},
    {'1': 'account', '3': 3, '4': 1, '5': 9, '10': 'account'},
    {'1': 'pin', '3': 4, '4': 1, '5': 9, '10': 'pin'},
    {
      '1': 'algorithm',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.CloudOtpTokenAlgorithm',
      '10': 'algorithm'
    },
    {
      '1': 'digits',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.CloudOtpTokenDigitCount',
      '10': 'digits'
    },
    {
      '1': 'type',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.CloudOtpTokenType',
      '10': 'type'
    },
    {'1': 'period', '3': 8, '4': 1, '5': 3, '10': 'period'},
    {'1': 'counter', '3': 9, '4': 1, '5': 3, '10': 'counter'},
    {'1': 'pinned', '3': 10, '4': 1, '5': 3, '10': 'pinned'},
    {'1': 'copyTimes', '3': 11, '4': 1, '5': 3, '10': 'copyTimes'},
    {
      '1': 'lastCopyTimeStamp',
      '3': 12,
      '4': 1,
      '5': 3,
      '10': 'lastCopyTimeStamp'
    },
    {'1': 'imagePath', '3': 13, '4': 1, '5': 9, '10': 'imagePath'},
    {'1': 'description', '3': 14, '4': 1, '5': 9, '10': 'description'},
    {'1': 'remark', '3': 15, '4': 1, '5': 9, '10': 'remark'},
    {'1': 'uid', '3': 16, '4': 1, '5': 9, '10': 'uid'},
  ],
};

/// Descriptor for `CloudOtpTokenParameters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cloudOtpTokenParametersDescriptor = $convert.base64Decode(
    'ChdDbG91ZE90cFRva2VuUGFyYW1ldGVycxIWCgZzZWNyZXQYASABKAxSBnNlY3JldBIWCgZpc3'
    'N1ZXIYAiABKAlSBmlzc3VlchIYCgdhY2NvdW50GAMgASgJUgdhY2NvdW50EhAKA3BpbhgEIAEo'
    'CVIDcGluEjUKCWFsZ29yaXRobRgFIAEoDjIXLkNsb3VkT3RwVG9rZW5BbGdvcml0aG1SCWFsZ2'
    '9yaXRobRIwCgZkaWdpdHMYBiABKA4yGC5DbG91ZE90cFRva2VuRGlnaXRDb3VudFIGZGlnaXRz'
    'EiYKBHR5cGUYByABKA4yEi5DbG91ZE90cFRva2VuVHlwZVIEdHlwZRIWCgZwZXJpb2QYCCABKA'
    'NSBnBlcmlvZBIYCgdjb3VudGVyGAkgASgDUgdjb3VudGVyEhYKBnBpbm5lZBgKIAEoA1IGcGlu'
    'bmVkEhwKCWNvcHlUaW1lcxgLIAEoA1IJY29weVRpbWVzEiwKEWxhc3RDb3B5VGltZVN0YW1wGA'
    'wgASgDUhFsYXN0Q29weVRpbWVTdGFtcBIcCglpbWFnZVBhdGgYDSABKAlSCWltYWdlUGF0aBIg'
    'CgtkZXNjcmlwdGlvbhgOIAEoCVILZGVzY3JpcHRpb24SFgoGcmVtYXJrGA8gASgJUgZyZW1hcm'
    'sSEAoDdWlkGBAgASgJUgN1aWQ=');
