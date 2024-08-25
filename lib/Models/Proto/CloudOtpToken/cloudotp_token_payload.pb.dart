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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cloudotp_token_payload.pbenum.dart';

export 'cloudotp_token_payload.pbenum.dart';

class CloudOtpTokenPayload extends $pb.GeneratedMessage {
  factory CloudOtpTokenPayload({
    $core.Iterable<CloudOtpTokenParameters>? tokenParameters,
    $core.int? version,
    $core.int? batchSize,
    $core.int? batchIndex,
    $core.int? batchId,
  }) {
    final $result = create();
    if (tokenParameters != null) {
      $result.tokenParameters.addAll(tokenParameters);
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

  CloudOtpTokenPayload._() : super();

  factory CloudOtpTokenPayload.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory CloudOtpTokenPayload.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudOtpTokenPayload',
      createEmptyInstance: create)
    ..pc<CloudOtpTokenParameters>(
        1, _omitFieldNames ? '' : 'tokenParameters', $pb.PbFieldType.PM,
        subBuilder: CloudOtpTokenParameters.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'batchSize', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'batchIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'batchId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CloudOtpTokenPayload clone() =>
      CloudOtpTokenPayload()..mergeFromMessage(this);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CloudOtpTokenPayload copyWith(void Function(CloudOtpTokenPayload) updates) =>
      super.copyWith((message) => updates(message as CloudOtpTokenPayload))
          as CloudOtpTokenPayload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudOtpTokenPayload create() => CloudOtpTokenPayload._();

  CloudOtpTokenPayload createEmptyInstance() => create();

  static $pb.PbList<CloudOtpTokenPayload> createRepeated() =>
      $pb.PbList<CloudOtpTokenPayload>();

  @$core.pragma('dart2js:noInline')
  static CloudOtpTokenPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudOtpTokenPayload>(create);
  static CloudOtpTokenPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<CloudOtpTokenParameters> get tokenParameters => $_getList(0);

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

class CloudOtpTokenParameters extends $pb.GeneratedMessage {
  factory CloudOtpTokenParameters({
    $core.List<$core.int>? secret,
    $core.String? issuer,
    $core.String? account,
    $core.String? pin,
    CloudOtpTokenAlgorithm? algorithm,
    CloudOtpTokenDigitCount? digits,
    CloudOtpTokenType? type,
    $fixnum.Int64? period,
    $fixnum.Int64? counter,
    $fixnum.Int64? pinned,
    $fixnum.Int64? copyTimes,
    $fixnum.Int64? lastCopyTimeStamp,
    $core.String? imagePath,
    $core.String? description,
    $core.String? uid,
    $core.String? remark,
  }) {
    final $result = create();
    if (secret != null) {
      $result.secret = secret;
    }
    if (issuer != null) {
      $result.issuer = issuer;
    }
    if (account != null) {
      $result.account = account;
    }
    if (pin != null) {
      $result.pin = pin;
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
    if (period != null) {
      $result.period = period;
    }
    if (counter != null) {
      $result.counter = counter;
    }
    if (pinned != null) {
      $result.pinned = pinned;
    }
    if (copyTimes != null) {
      $result.copyTimes = copyTimes;
    }
    if (lastCopyTimeStamp != null) {
      $result.lastCopyTimeStamp = lastCopyTimeStamp;
    }
    if (imagePath != null) {
      $result.imagePath = imagePath;
    }
    if (description != null) {
      $result.description = description;
    }
    if (uid != null) {
      $result.uid = uid;
    }
    if (remark != null) {
      $result.remark = remark;
    }
    return $result;
  }

  CloudOtpTokenParameters._() : super();

  factory CloudOtpTokenParameters.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory CloudOtpTokenParameters.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudOtpTokenParameters',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'issuer')
    ..aOS(3, _omitFieldNames ? '' : 'account')
    ..aOS(4, _omitFieldNames ? '' : 'pin')
    ..e<CloudOtpTokenAlgorithm>(
        5, _omitFieldNames ? '' : 'algorithm', $pb.PbFieldType.OE,
        defaultOrMaker: CloudOtpTokenAlgorithm.ALGORITHM_TYPE_UNSPECIFIED,
        valueOf: CloudOtpTokenAlgorithm.valueOf,
        enumValues: CloudOtpTokenAlgorithm.values)
    ..e<CloudOtpTokenDigitCount>(
        6, _omitFieldNames ? '' : 'digits', $pb.PbFieldType.OE,
        defaultOrMaker: CloudOtpTokenDigitCount.DIGIT_COUNT_UNSPECIFIED,
        valueOf: CloudOtpTokenDigitCount.valueOf,
        enumValues: CloudOtpTokenDigitCount.values)
    ..e<CloudOtpTokenType>(7, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: CloudOtpTokenType.OTP_TYPE_UNSPECIFIED,
        valueOf: CloudOtpTokenType.valueOf,
        enumValues: CloudOtpTokenType.values)
    ..aInt64(8, _omitFieldNames ? '' : 'period')
    ..aInt64(9, _omitFieldNames ? '' : 'counter')
    ..aInt64(10, _omitFieldNames ? '' : 'pinned')
    ..aInt64(11, _omitFieldNames ? '' : 'copyTimes', protoName: 'copyTimes')
    ..aInt64(12, _omitFieldNames ? '' : 'lastCopyTimeStamp',
        protoName: 'lastCopyTimeStamp')
    ..aOS(13, _omitFieldNames ? '' : 'imagePath', protoName: 'imagePath')
    ..aOS(14, _omitFieldNames ? '' : 'description')
    ..aOS(15, _omitFieldNames ? '' : 'uid')
    ..aOS(16, _omitFieldNames ? '' : 'remark')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CloudOtpTokenParameters clone() =>
      CloudOtpTokenParameters()..mergeFromMessage(this);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CloudOtpTokenParameters copyWith(
          void Function(CloudOtpTokenParameters) updates) =>
      super.copyWith((message) => updates(message as CloudOtpTokenParameters))
          as CloudOtpTokenParameters;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudOtpTokenParameters create() => CloudOtpTokenParameters._();

  CloudOtpTokenParameters createEmptyInstance() => create();

  static $pb.PbList<CloudOtpTokenParameters> createRepeated() =>
      $pb.PbList<CloudOtpTokenParameters>();

  @$core.pragma('dart2js:noInline')
  static CloudOtpTokenParameters getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudOtpTokenParameters>(create);
  static CloudOtpTokenParameters? _defaultInstance;

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
  $core.String get issuer => $_getSZ(1);

  @$pb.TagNumber(2)
  set issuer($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIssuer() => $_has(1);

  @$pb.TagNumber(2)
  void clearIssuer() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get account => $_getSZ(2);

  @$pb.TagNumber(3)
  set account($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAccount() => $_has(2);

  @$pb.TagNumber(3)
  void clearAccount() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get pin => $_getSZ(3);

  @$pb.TagNumber(4)
  set pin($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPin() => $_has(3);

  @$pb.TagNumber(4)
  void clearPin() => clearField(4);

  @$pb.TagNumber(5)
  CloudOtpTokenAlgorithm get algorithm => $_getN(4);

  @$pb.TagNumber(5)
  set algorithm(CloudOtpTokenAlgorithm v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAlgorithm() => $_has(4);

  @$pb.TagNumber(5)
  void clearAlgorithm() => clearField(5);

  @$pb.TagNumber(6)
  CloudOtpTokenDigitCount get digits => $_getN(5);

  @$pb.TagNumber(6)
  set digits(CloudOtpTokenDigitCount v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDigits() => $_has(5);

  @$pb.TagNumber(6)
  void clearDigits() => clearField(6);

  @$pb.TagNumber(7)
  CloudOtpTokenType get type => $_getN(6);

  @$pb.TagNumber(7)
  set type(CloudOtpTokenType v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasType() => $_has(6);

  @$pb.TagNumber(7)
  void clearType() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get period => $_getI64(7);

  @$pb.TagNumber(8)
  set period($fixnum.Int64 v) {
    $_setInt64(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasPeriod() => $_has(7);

  @$pb.TagNumber(8)
  void clearPeriod() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get counter => $_getI64(8);

  @$pb.TagNumber(9)
  set counter($fixnum.Int64 v) {
    $_setInt64(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasCounter() => $_has(8);

  @$pb.TagNumber(9)
  void clearCounter() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get pinned => $_getI64(9);

  @$pb.TagNumber(10)
  set pinned($fixnum.Int64 v) {
    $_setInt64(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasPinned() => $_has(9);

  @$pb.TagNumber(10)
  void clearPinned() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get copyTimes => $_getI64(10);

  @$pb.TagNumber(11)
  set copyTimes($fixnum.Int64 v) {
    $_setInt64(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasCopyTimes() => $_has(10);

  @$pb.TagNumber(11)
  void clearCopyTimes() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get lastCopyTimeStamp => $_getI64(11);

  @$pb.TagNumber(12)
  set lastCopyTimeStamp($fixnum.Int64 v) {
    $_setInt64(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasLastCopyTimeStamp() => $_has(11);

  @$pb.TagNumber(12)
  void clearLastCopyTimeStamp() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get imagePath => $_getSZ(12);

  @$pb.TagNumber(13)
  set imagePath($core.String v) {
    $_setString(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasImagePath() => $_has(12);

  @$pb.TagNumber(13)
  void clearImagePath() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get description => $_getSZ(13);

  @$pb.TagNumber(14)
  set description($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasDescription() => $_has(13);

  @$pb.TagNumber(14)
  void clearDescription() => clearField(14);

  @$pb.TagNumber(15)
  $core.String get uid => $_getSZ(14);

  @$pb.TagNumber(15)
  set uid($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasUid() => $_has(14);

  @$pb.TagNumber(15)
  void clearUid() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get remark => $_getSZ(15);

  @$pb.TagNumber(16)
  set remark($core.String v) {
    $_setString(15, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasRemark() => $_has(15);

  @$pb.TagNumber(16)
  void clearRemark() => clearField(16);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
