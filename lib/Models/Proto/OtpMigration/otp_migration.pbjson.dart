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
final $typed_data.Uint8List otpMigrationDigitCountDescriptor =
    $convert.base64Decode(
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

@$core.Deprecated('Use otpMigrationPayloadDescriptor instead')
const OtpMigrationPayload$json = {
  '1': 'OtpMigrationPayload',
  '2': [
    {
      '1': 'otp_parameters',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.OtpMigrationParameters',
      '10': 'otpParameters'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'batch_index', '3': 4, '4': 1, '5': 5, '10': 'batchIndex'},
    {'1': 'batch_id', '3': 5, '4': 1, '5': 5, '10': 'batchId'},
  ],
};

/// Descriptor for `OtpMigrationPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List otpMigrationPayloadDescriptor = $convert.base64Decode(
    'ChNPdHBNaWdyYXRpb25QYXlsb2FkEj4KDm90cF9wYXJhbWV0ZXJzGAEgAygLMhcuT3RwTWlncm'
    'F0aW9uUGFyYW1ldGVyc1INb3RwUGFyYW1ldGVycxIYCgd2ZXJzaW9uGAIgASgFUgd2ZXJzaW9u'
    'Eh0KCmJhdGNoX3NpemUYAyABKAVSCWJhdGNoU2l6ZRIfCgtiYXRjaF9pbmRleBgEIAEoBVIKYm'
    'F0Y2hJbmRleBIZCghiYXRjaF9pZBgFIAEoBVIHYmF0Y2hJZA==');

@$core.Deprecated('Use otpMigrationParametersDescriptor instead')
const OtpMigrationParameters$json = {
  '1': 'OtpMigrationParameters',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'account', '3': 2, '4': 1, '5': 9, '10': 'account'},
    {'1': 'issuer', '3': 3, '4': 1, '5': 9, '10': 'issuer'},
    {
      '1': 'algorithm',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.OtpMigrationAlgorithm',
      '10': 'algorithm'
    },
    {
      '1': 'digits',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.OtpMigrationDigitCount',
      '10': 'digits'
    },
    {
      '1': 'type',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.OtpMigrationType',
      '10': 'type'
    },
    {'1': 'counter', '3': 7, '4': 1, '5': 3, '10': 'counter'},
  ],
};

/// Descriptor for `OtpMigrationParameters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List otpMigrationParametersDescriptor = $convert.base64Decode(
    'ChZPdHBNaWdyYXRpb25QYXJhbWV0ZXJzEhYKBnNlY3JldBgBIAEoDFIGc2VjcmV0EhgKB2FjY2'
    '91bnQYAiABKAlSB2FjY291bnQSFgoGaXNzdWVyGAMgASgJUgZpc3N1ZXISNAoJYWxnb3JpdGht'
    'GAQgASgOMhYuT3RwTWlncmF0aW9uQWxnb3JpdGhtUglhbGdvcml0aG0SLwoGZGlnaXRzGAUgAS'
    'gOMhcuT3RwTWlncmF0aW9uRGlnaXRDb3VudFIGZGlnaXRzEiUKBHR5cGUYBiABKA4yES5PdHBN'
    'aWdyYXRpb25UeXBlUgR0eXBlEhgKB2NvdW50ZXIYByABKANSB2NvdW50ZXI=');
