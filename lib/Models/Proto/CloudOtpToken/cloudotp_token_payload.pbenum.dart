//
//  Generated code. Do not modify.
//  source: cloudotp_token_payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CloudOtpTokenAlgorithm extends $pb.ProtobufEnum {
  static const CloudOtpTokenAlgorithm ALGORITHM_TYPE_UNSPECIFIED =
      CloudOtpTokenAlgorithm._(
          0, _omitEnumNames ? '' : 'ALGORITHM_TYPE_UNSPECIFIED');
  static const CloudOtpTokenAlgorithm SHA1 =
      CloudOtpTokenAlgorithm._(1, _omitEnumNames ? '' : 'SHA1');
  static const CloudOtpTokenAlgorithm SHA256 =
      CloudOtpTokenAlgorithm._(2, _omitEnumNames ? '' : 'SHA256');
  static const CloudOtpTokenAlgorithm SHA512 =
      CloudOtpTokenAlgorithm._(3, _omitEnumNames ? '' : 'SHA512');

  static const $core.List<CloudOtpTokenAlgorithm> values =
      <CloudOtpTokenAlgorithm>[
    ALGORITHM_TYPE_UNSPECIFIED,
    SHA1,
    SHA256,
    SHA512,
  ];

  static final $core.Map<$core.int, CloudOtpTokenAlgorithm> _byValue =
      $pb.ProtobufEnum.initByValue(values);

  static CloudOtpTokenAlgorithm? valueOf($core.int value) => _byValue[value];

  const CloudOtpTokenAlgorithm._($core.int v, $core.String n) : super(v, n);
}

class CloudOtpTokenDigitCount extends $pb.ProtobufEnum {
  static const CloudOtpTokenDigitCount DIGIT_COUNT_UNSPECIFIED =
      CloudOtpTokenDigitCount._(
          0, _omitEnumNames ? '' : 'DIGIT_COUNT_UNSPECIFIED');
  static const CloudOtpTokenDigitCount FIVE =
      CloudOtpTokenDigitCount._(1, _omitEnumNames ? '' : 'FIVE');
  static const CloudOtpTokenDigitCount SIX =
      CloudOtpTokenDigitCount._(2, _omitEnumNames ? '' : 'SIX');
  static const CloudOtpTokenDigitCount SEVEN =
      CloudOtpTokenDigitCount._(3, _omitEnumNames ? '' : 'SEVEN');
  static const CloudOtpTokenDigitCount EIGHT =
      CloudOtpTokenDigitCount._(4, _omitEnumNames ? '' : 'EIGHT');

  static const $core.List<CloudOtpTokenDigitCount> values =
      <CloudOtpTokenDigitCount>[
    DIGIT_COUNT_UNSPECIFIED,
    FIVE,
    SIX,
    SEVEN,
    EIGHT,
  ];

  static final $core.Map<$core.int, CloudOtpTokenDigitCount> _byValue =
      $pb.ProtobufEnum.initByValue(values);

  static CloudOtpTokenDigitCount? valueOf($core.int value) => _byValue[value];

  const CloudOtpTokenDigitCount._($core.int v, $core.String n) : super(v, n);
}

class CloudOtpTokenType extends $pb.ProtobufEnum {
  static const CloudOtpTokenType OTP_TYPE_UNSPECIFIED =
      CloudOtpTokenType._(0, _omitEnumNames ? '' : 'OTP_TYPE_UNSPECIFIED');
  static const CloudOtpTokenType TOTP =
      CloudOtpTokenType._(1, _omitEnumNames ? '' : 'TOTP');
  static const CloudOtpTokenType HOTP =
      CloudOtpTokenType._(2, _omitEnumNames ? '' : 'HOTP');
  static const CloudOtpTokenType MOTP =
      CloudOtpTokenType._(3, _omitEnumNames ? '' : 'MOTP');
  static const CloudOtpTokenType STEAM =
      CloudOtpTokenType._(4, _omitEnumNames ? '' : 'STEAM');
  static const CloudOtpTokenType YANDEX =
      CloudOtpTokenType._(5, _omitEnumNames ? '' : 'YANDEX');

  static const $core.List<CloudOtpTokenType> values = <CloudOtpTokenType>[
    OTP_TYPE_UNSPECIFIED,
    TOTP,
    HOTP,
    MOTP,
    STEAM,
    YANDEX,
  ];

  static final $core.Map<$core.int, CloudOtpTokenType> _byValue =
      $pb.ProtobufEnum.initByValue(values);

  static CloudOtpTokenType? valueOf($core.int value) => _byValue[value];

  const CloudOtpTokenType._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
