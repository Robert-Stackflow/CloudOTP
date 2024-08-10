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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'otp_migration.pbenum.dart';

export 'otp_migration.pbenum.dart';

class MigrationPayload extends $pb.GeneratedMessage {
  factory MigrationPayload({
    $core.Iterable<OtpParameters>? otpParameters,
    $core.int? version,
    $core.int? batchSize,
    $core.int? batchIndex,
    $core.int? batchId,
  }) {
    final $result = create();
    if (otpParameters != null) {
      $result.otpParameters.addAll(otpParameters);
    }
    if (version != null) {
      $result.version = version;
    }
    if (batchSize != null) {
      $result.batchSize = batchSize;
    }
    if (batchIndex != null) {
      $result.batchIndex = batchIndex;
    }
    if (batchId != null) {
      $result.batchId = batchId;
    }
    return $result;
  }
  MigrationPayload._() : super();
  factory MigrationPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MigrationPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MigrationPayload', createEmptyInstance: create)
    ..pc<OtpParameters>(1, _omitFieldNames ? '' : 'otpParameters', $pb.PbFieldType.PM, subBuilder: OtpParameters.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'batchSize', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'batchIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'batchId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MigrationPayload clone() => MigrationPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MigrationPayload copyWith(void Function(MigrationPayload) updates) => super.copyWith((message) => updates(message as MigrationPayload)) as MigrationPayload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationPayload create() => MigrationPayload._();
  MigrationPayload createEmptyInstance() => create();
  static $pb.PbList<MigrationPayload> createRepeated() => $pb.PbList<MigrationPayload>();
  @$core.pragma('dart2js:noInline')
  static MigrationPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MigrationPayload>(create);
  static MigrationPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<OtpParameters> get otpParameters => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get batchSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set batchSize($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBatchSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatchSize() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get batchIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set batchIndex($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBatchIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearBatchIndex() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get batchId => $_getIZ(4);
  @$pb.TagNumber(5)
  set batchId($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBatchId() => $_has(4);
  @$pb.TagNumber(5)
  void clearBatchId() => clearField(5);
}

class OtpParameters extends $pb.GeneratedMessage {
  factory OtpParameters({
    $core.List<$core.int>? secret,
    $core.String? name,
    $core.String? issuer,
    OtpMigrationAlgorithm? algorithm,
    OtpMigrationDigitCount? digits,
    OtpMigrationType? type,
    $fixnum.Int64? counter,
  }) {
    final $result = create();
    if (secret != null) {
      $result.secret = secret;
    }
    if (name != null) {
      $result.name = name;
    }
    if (issuer != null) {
      $result.issuer = issuer;
    }
    if (algorithm != null) {
      $result.algorithm = algorithm;
    }
    if (digits != null) {
      $result.digits = digits;
    }
    if (type != null) {
      $result.type = type;
    }
    if (counter != null) {
      $result.counter = counter;
    }
    return $result;
  }
  OtpParameters._() : super();
  factory OtpParameters.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OtpParameters.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OtpParameters', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'issuer')
    ..e<OtpMigrationAlgorithm>(4, _omitFieldNames ? '' : 'algorithm', $pb.PbFieldType.OE, defaultOrMaker: OtpMigrationAlgorithm.ALGORITHM_TYPE_UNSPECIFIED, valueOf: OtpMigrationAlgorithm.valueOf, enumValues: OtpMigrationAlgorithm.values)
    ..e<OtpMigrationDigitCount>(5, _omitFieldNames ? '' : 'digits', $pb.PbFieldType.OE, defaultOrMaker: OtpMigrationDigitCount.DIGIT_COUNT_UNSPECIFIED, valueOf: OtpMigrationDigitCount.valueOf, enumValues: OtpMigrationDigitCount.values)
    ..e<OtpMigrationType>(6, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: OtpMigrationType.OTP_TYPE_UNSPECIFIED, valueOf: OtpMigrationType.valueOf, enumValues: OtpMigrationType.values)
    ..aInt64(7, _omitFieldNames ? '' : 'counter')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OtpParameters clone() => OtpParameters()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OtpParameters copyWith(void Function(OtpParameters) updates) => super.copyWith((message) => updates(message as OtpParameters)) as OtpParameters;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtpParameters create() => OtpParameters._();
  OtpParameters createEmptyInstance() => create();
  static $pb.PbList<OtpParameters> createRepeated() => $pb.PbList<OtpParameters>();
  @$core.pragma('dart2js:noInline')
  static OtpParameters getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtpParameters>(create);
  static OtpParameters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get issuer => $_getSZ(2);
  @$pb.TagNumber(3)
  set issuer($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIssuer() => $_has(2);
  @$pb.TagNumber(3)
  void clearIssuer() => clearField(3);

  @$pb.TagNumber(4)
  OtpMigrationAlgorithm get algorithm => $_getN(3);
  @$pb.TagNumber(4)
  set algorithm(OtpMigrationAlgorithm v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasAlgorithm() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlgorithm() => clearField(4);

  @$pb.TagNumber(5)
  OtpMigrationDigitCount get digits => $_getN(4);
  @$pb.TagNumber(5)
  set digits(OtpMigrationDigitCount v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDigits() => $_has(4);
  @$pb.TagNumber(5)
  void clearDigits() => clearField(5);

  @$pb.TagNumber(6)
  OtpMigrationType get type => $_getN(5);
  @$pb.TagNumber(6)
  set type(OtpMigrationType v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get counter => $_getI64(6);
  @$pb.TagNumber(7)
  set counter($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasCounter() => $_has(6);
  @$pb.TagNumber(7)
  void clearCounter() => clearField(7);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
