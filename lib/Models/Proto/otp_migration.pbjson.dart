//
//  Generated code. Do not modify.
//  source: otp_migration.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use otpMigrationAlgorithmDescriptor instead')
const OtpMigrationAlgorithm$json = {
  '1': 'OtpMigrationAlgorithm',
  '2': [
    {'1': 'ALGORITHM_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SHA1', '2': 1},
    {'1': 'SHA256', '2': 2},
    {'1': 'SHA512', '2': 3},
    {'1': 'MD5', '2': 4},
  ],
};

/// Descriptor for `OtpMigrationAlgorithm`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List otpMigrationAlgorithmDescriptor = $convert.base64Decode(
    'ChVPdHBNaWdyYXRpb25BbGdvcml0aG0SHgoaQUxHT1JJVEhNX1RZUEVfVU5TUEVDSUZJRUQQAB'
    'IICgRTSEExEAESCgoGU0hBMjU2EAISCgoGU0hBNTEyEAMSBwoDTUQ1EAQ=');

@$core.Deprecated('Use otpMigrationDigitCountDescriptor instead')
const OtpMigrationDigitCount$json = {
  '1': 'OtpMigrationDigitCount',
  '2': [
    {'1': 'DIGIT_COUNT_UNSPECIFIED', '2': 0},
    {'1': 'SIX', '2': 1},
    {'1': 'EIGHT', '2': 2},
  ],
};

/// Descriptor for `OtpMigrationDigitCount`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List otpMigrationDigitCountDescriptor = $convert.base64Decode(
    'ChZPdHBNaWdyYXRpb25EaWdpdENvdW50EhsKF0RJR0lUX0NPVU5UX1VOU1BFQ0lGSUVEEAASBw'
    'oDU0lYEAESCQoFRUlHSFQQAg==');

@$core.Deprecated('Use otpMigrationTypeDescriptor instead')
const OtpMigrationType$json = {
  '1': 'OtpMigrationType',
  '2': [
    {'1': 'OTP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'HOTP', '2': 1},
    {'1': 'TOTP', '2': 2},
  ],
};

/// Descriptor for `OtpMigrationType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List otpMigrationTypeDescriptor = $convert.base64Decode(
    'ChBPdHBNaWdyYXRpb25UeXBlEhgKFE9UUF9UWVBFX1VOU1BFQ0lGSUVEEAASCAoESE9UUBABEg'
    'gKBFRPVFAQAg==');

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload$json = {
  '1': 'MigrationPayload',
  '2': [
    {'1': 'otp_parameters', '3': 1, '4': 3, '5': 11, '6': '.OtpParameters', '10': 'otpParameters'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'batch_index', '3': 4, '4': 1, '5': 5, '10': 'batchIndex'},
    {'1': 'batch_id', '3': 5, '4': 1, '5': 5, '10': 'batchId'},
  ],
};

/// Descriptor for `MigrationPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationPayloadDescriptor = $convert.base64Decode(
    'ChBNaWdyYXRpb25QYXlsb2FkEjUKDm90cF9wYXJhbWV0ZXJzGAEgAygLMg4uT3RwUGFyYW1ldG'
    'Vyc1INb3RwUGFyYW1ldGVycxIYCgd2ZXJzaW9uGAIgASgFUgd2ZXJzaW9uEh0KCmJhdGNoX3Np'
    'emUYAyABKAVSCWJhdGNoU2l6ZRIfCgtiYXRjaF9pbmRleBgEIAEoBVIKYmF0Y2hJbmRleBIZCg'
    'hiYXRjaF9pZBgFIAEoBVIHYmF0Y2hJZA==');

@$core.Deprecated('Use otpParametersDescriptor instead')
const OtpParameters$json = {
  '1': 'OtpParameters',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'issuer', '3': 3, '4': 1, '5': 9, '10': 'issuer'},
    {'1': 'algorithm', '3': 4, '4': 1, '5': 14, '6': '.OtpMigrationAlgorithm', '10': 'algorithm'},
    {'1': 'digits', '3': 5, '4': 1, '5': 14, '6': '.OtpMigrationDigitCount', '10': 'digits'},
    {'1': 'type', '3': 6, '4': 1, '5': 14, '6': '.OtpMigrationType', '10': 'type'},
    {'1': 'counter', '3': 7, '4': 1, '5': 3, '10': 'counter'},
  ],
};

/// Descriptor for `OtpParameters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List otpParametersDescriptor = $convert.base64Decode(
    'Cg1PdHBQYXJhbWV0ZXJzEhYKBnNlY3JldBgBIAEoDFIGc2VjcmV0EhIKBG5hbWUYAiABKAlSBG'
    '5hbWUSFgoGaXNzdWVyGAMgASgJUgZpc3N1ZXISNAoJYWxnb3JpdGhtGAQgASgOMhYuT3RwTWln'
    'cmF0aW9uQWxnb3JpdGhtUglhbGdvcml0aG0SLwoGZGlnaXRzGAUgASgOMhcuT3RwTWlncmF0aW'
    '9uRGlnaXRDb3VudFIGZGlnaXRzEiUKBHR5cGUYBiABKA4yES5PdHBNaWdyYXRpb25UeXBlUgR0'
    'eXBlEhgKB2NvdW50ZXIYByABKANSB2NvdW50ZXI=');

