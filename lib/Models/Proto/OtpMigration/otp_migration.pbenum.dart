//
//  Generated code. Do not modify.
//  source: otp_migration.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class OtpMigrationAlgorithm extends $pb.ProtobufEnum {
  static const OtpMigrationAlgorithm ALGORITHM_TYPE_UNSPECIFIED = OtpMigrationAlgorithm._(0, _omitEnumNames ? '' : 'ALGORITHM_TYPE_UNSPECIFIED');
  static const OtpMigrationAlgorithm SHA1 = OtpMigrationAlgorithm._(1, _omitEnumNames ? '' : 'SHA1');
  static const OtpMigrationAlgorithm SHA256 = OtpMigrationAlgorithm._(2, _omitEnumNames ? '' : 'SHA256');
  static const OtpMigrationAlgorithm SHA512 = OtpMigrationAlgorithm._(3, _omitEnumNames ? '' : 'SHA512');
  static const OtpMigrationAlgorithm MD5 = OtpMigrationAlgorithm._(4, _omitEnumNames ? '' : 'MD5');

  static const $core.List<OtpMigrationAlgorithm> values = <OtpMigrationAlgorithm> [
    ALGORITHM_TYPE_UNSPECIFIED,
    SHA1,
    SHA256,
    SHA512,
    MD5,
  ];

  static final $core.Map<$core.int, OtpMigrationAlgorithm> _byValue = $pb.ProtobufEnum.initByValue(values);
  static OtpMigrationAlgorithm? valueOf($core.int value) => _byValue[value];

  const OtpMigrationAlgorithm._($core.int v, $core.String n) : super(v, n);
}

class OtpMigrationDigitCount extends $pb.ProtobufEnum {
  static const OtpMigrationDigitCount DIGIT_COUNT_UNSPECIFIED = OtpMigrationDigitCount._(0, _omitEnumNames ? '' : 'DIGIT_COUNT_UNSPECIFIED');
  static const OtpMigrationDigitCount SIX = OtpMigrationDigitCount._(1, _omitEnumNames ? '' : 'SIX');
  static const OtpMigrationDigitCount EIGHT = OtpMigrationDigitCount._(2, _omitEnumNames ? '' : 'EIGHT');

  static const $core.List<OtpMigrationDigitCount> values = <OtpMigrationDigitCount> [
    DIGIT_COUNT_UNSPECIFIED,
    SIX,
    EIGHT,
  ];

  static final $core.Map<$core.int, OtpMigrationDigitCount> _byValue = $pb.ProtobufEnum.initByValue(values);
  static OtpMigrationDigitCount? valueOf($core.int value) => _byValue[value];

  const OtpMigrationDigitCount._($core.int v, $core.String n) : super(v, n);
}

class OtpMigrationType extends $pb.ProtobufEnum {
  static const OtpMigrationType OTP_TYPE_UNSPECIFIED = OtpMigrationType._(0, _omitEnumNames ? '' : 'OTP_TYPE_UNSPECIFIED');
  static const OtpMigrationType HOTP = OtpMigrationType._(1, _omitEnumNames ? '' : 'HOTP');
  static const OtpMigrationType TOTP = OtpMigrationType._(2, _omitEnumNames ? '' : 'TOTP');

  static const $core.List<OtpMigrationType> values = <OtpMigrationType> [
    OTP_TYPE_UNSPECIFIED,
    HOTP,
    TOTP,
  ];

  static final $core.Map<$core.int, OtpMigrationType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static OtpMigrationType? valueOf($core.int value) => _byValue[value];

  const OtpMigrationType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
