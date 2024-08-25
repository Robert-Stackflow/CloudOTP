//
//  Generated code. Do not modify.
//  source: token_category_payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use tokenCategoryPayloadDescriptor instead')
const TokenCategoryPayload$json = {
  '1': 'TokenCategoryPayload',
  '2': [
    {'1': 'category_parameters', '3': 1, '4': 3, '5': 11, '6': '.TokenCategoryParameters', '10': 'categoryParameters'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'batch_index', '3': 4, '4': 1, '5': 5, '10': 'batchIndex'},
    {'1': 'batch_id', '3': 5, '4': 1, '5': 5, '10': 'batchId'},
  ],
};

/// Descriptor for `TokenCategoryPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenCategoryPayloadDescriptor = $convert.base64Decode(
    'ChRUb2tlbkNhdGVnb3J5UGF5bG9hZBJJChNjYXRlZ29yeV9wYXJhbWV0ZXJzGAEgAygLMhguVG'
    '9rZW5DYXRlZ29yeVBhcmFtZXRlcnNSEmNhdGVnb3J5UGFyYW1ldGVycxIYCgd2ZXJzaW9uGAIg'
    'ASgFUgd2ZXJzaW9uEh0KCmJhdGNoX3NpemUYAyABKAVSCWJhdGNoU2l6ZRIfCgtiYXRjaF9pbm'
    'RleBgEIAEoBVIKYmF0Y2hJbmRleBIZCghiYXRjaF9pZBgFIAEoBVIHYmF0Y2hJZA==');

@$core.Deprecated('Use tokenCategoryParametersDescriptor instead')
const TokenCategoryParameters$json = {
  '1': 'TokenCategoryParameters',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'tokenIds', '3': 4, '4': 1, '5': 9, '10': 'tokenIds'},
    {'1': 'remark', '3': 5, '4': 1, '5': 9, '10': 'remark'},
    {'1': 'uid', '3': 6, '4': 1, '5': 9, '10': 'uid'},
    {'1': 'bindings', '3': 7, '4': 1, '5': 9, '10': 'bindings'},
  ],
};

/// Descriptor for `TokenCategoryParameters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenCategoryParametersDescriptor = $convert.base64Decode(
    'ChdUb2tlbkNhdGVnb3J5UGFyYW1ldGVycxIWCgZzZWNyZXQYASABKAxSBnNlY3JldBIUCgV0aX'
    'RsZRgCIAEoCVIFdGl0bGUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEhoKCHRv'
    'a2VuSWRzGAQgASgJUgh0b2tlbklkcxIWCgZyZW1hcmsYBSABKAlSBnJlbWFyaxIQCgN1aWQYBi'
    'ABKAlSA3VpZBIaCghiaW5kaW5ncxgHIAEoCVIIYmluZGluZ3M=');

