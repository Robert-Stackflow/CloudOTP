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

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'otp_migration.pbenum.dart';

export 'otp_migration.pbenum.dart';

class OtpMigrationPayload extends $pb.GeneratedMessage {
  factory OtpMigrationPayload({
    $core.Iterable<OtpMigrationParameters>? otpParameters,
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

  OtpMigrationPayload._() : super();

  factory OtpMigrationPayload.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory OtpMigrationPayload.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtpMigrationPayload',
      createEmptyInstance: create)
    ..pc<OtpMigrationParameters>(
        1, _omitFieldNames ? '' : 'otpParameters', $pb.PbFieldType.PM,
        subBuilder: OtpMigrationParameters.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'batchSize', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'batchIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'batchId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OtpMigrationPayload clone() => OtpMigrationPayload()..mergeFromMessage(this);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OtpMigrationPayload copyWith(void Function(OtpMigrationPayload) updates) =>
      super.copyWith((message) => updates(message as OtpMigrationPayload))
          as OtpMigrationPayload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtpMigrationPayload create() => OtpMigrationPayload._();

  OtpMigrationPayload createEmptyInstance() => create();

  static $pb.PbList<OtpMigrationPayload> createRepeated() =>
      $pb.PbList<OtpMigrationPayload>();

  @$core.pragma('dart2js:noInline')
  static OtpMigrationPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OtpMigrationPayload>(create);
  static OtpMigrationPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<OtpMigrationParameters> get otpParameters => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);

  @$pb.TagNumber(2)
  set version($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);

  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get batchSize => $_getIZ(2);

  @$pb.TagNumber(3)
  set batchSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBatchSize() => $_has(2);

  @$pb.TagNumber(3)
  void clearBatchSize() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get batchIndex => $_getIZ(3);

  @$pb.TagNumber(4)
  set batchIndex($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasBatchIndex() => $_has(3);

  @$pb.TagNumber(4)
  void clearBatchIndex() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get batchId => $_getIZ(4);

  @$pb.TagNumber(5)
  set batchId($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasBatchId() => $_has(4);

  @$pb.TagNumber(5)
  void clearBatchId() => clearField(5);
}

class OtpMigrationParameters extends $pb.GeneratedMessage {
  factory OtpMigrationParameters({
    $core.List<$core.int>? secret,
    $core.String? account,
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
    if (account != null) {
      $result.account = account;
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

  OtpMigrationParameters._() : super();

  factory OtpMigrationParameters.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory OtpMigrationParameters.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtpMigrationParameters',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'account')
    ..aOS(3, _omitFieldNames ? '' : 'issuer')
    ..e<OtpMigrationAlgorithm>(
        4, _omitFieldNames ? '' : 'algorithm', $pb.PbFieldType.OE,
        defaultOrMaker: OtpMigrationAlgorithm.ALGORITHM_TYPE_UNSPECIFIED,
        valueOf: OtpMigrationAlgorithm.valueOf,
        enumValues: OtpMigrationAlgorithm.values)
    ..e<OtpMigrationDigitCount>(
        5, _omitFieldNames ? '' : 'digits', $pb.PbFieldType.OE,
        defaultOrMaker: OtpMigrationDigitCount.DIGIT_COUNT_UNSPECIFIED,
        valueOf: OtpMigrationDigitCount.valueOf,
        enumValues: OtpMigrationDigitCount.values)
    ..e<OtpMigrationType>(6, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: OtpMigrationType.OTP_TYPE_UNSPECIFIED,
        valueOf: OtpMigrationType.valueOf,
        enumValues: OtpMigrationType.values)
    ..aInt64(7, _omitFieldNames ? '' : 'counter')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OtpMigrationParameters clone() =>
      OtpMigrationParameters()..mergeFromMessage(this);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OtpMigrationParameters copyWith(
          void Function(OtpMigrationParameters) updates) =>
      super.copyWith((message) => updates(message as OtpMigrationParameters))
          as OtpMigrationParameters;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtpMigrationParameters create() => OtpMigrationParameters._();

  OtpMigrationParameters createEmptyInstance() => create();

  static $pb.PbList<OtpMigrationParameters> createRepeated() =>
      $pb.PbList<OtpMigrationParameters>();

  @$core.pragma('dart2js:noInline')
  static OtpMigrationParameters getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OtpMigrationParameters>(create);
  static OtpMigrationParameters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);

  @$pb.TagNumber(1)
  set secret($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);

  @$pb.TagNumber(1)
  void clearSecret() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get account => $_getSZ(1);

  @$pb.TagNumber(2)
  set account($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);

  @$pb.TagNumber(2)
  void clearAccount() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get issuer => $_getSZ(2);

  @$pb.TagNumber(3)
  set issuer($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasIssuer() => $_has(2);

  @$pb.TagNumber(3)
  void clearIssuer() => clearField(3);

  @$pb.TagNumber(4)
  OtpMigrationAlgorithm get algorithm => $_getN(3);

  @$pb.TagNumber(4)
  set algorithm(OtpMigrationAlgorithm v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAlgorithm() => $_has(3);

  @$pb.TagNumber(4)
  void clearAlgorithm() => clearField(4);

  @$pb.TagNumber(5)
  OtpMigrationDigitCount get digits => $_getN(4);

  @$pb.TagNumber(5)
  set digits(OtpMigrationDigitCount v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDigits() => $_has(4);

  @$pb.TagNumber(5)
  void clearDigits() => clearField(5);

  @$pb.TagNumber(6)
  OtpMigrationType get type => $_getN(5);

  @$pb.TagNumber(6)
  set type(OtpMigrationType v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);

  @$pb.TagNumber(6)
  void clearType() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get counter => $_getI64(6);

  @$pb.TagNumber(7)
  set counter($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasCounter() => $_has(6);

  @$pb.TagNumber(7)
  void clearCounter() => clearField(7);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
