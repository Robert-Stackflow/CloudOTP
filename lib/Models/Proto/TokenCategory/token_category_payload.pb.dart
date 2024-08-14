//
//  Generated code. Do not modify.
//  source: token_category_payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TokenCategoryPayload extends $pb.GeneratedMessage {
  factory TokenCategoryPayload({
    $core.Iterable<TokenCategoryParameters>? categoryParameters,
    $core.int? version,
    $core.int? batchSize,
    $core.int? batchIndex,
    $core.int? batchId,
  }) {
    final $result = create();
    if (categoryParameters != null) {
      $result.categoryParameters.addAll(categoryParameters);
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
  TokenCategoryPayload._() : super();
  factory TokenCategoryPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TokenCategoryPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TokenCategoryPayload', createEmptyInstance: create)
    ..pc<TokenCategoryParameters>(1, _omitFieldNames ? '' : 'categoryParameters', $pb.PbFieldType.PM, subBuilder: TokenCategoryParameters.create)
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
  TokenCategoryPayload clone() => TokenCategoryPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TokenCategoryPayload copyWith(void Function(TokenCategoryPayload) updates) => super.copyWith((message) => updates(message as TokenCategoryPayload)) as TokenCategoryPayload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TokenCategoryPayload create() => TokenCategoryPayload._();
  TokenCategoryPayload createEmptyInstance() => create();
  static $pb.PbList<TokenCategoryPayload> createRepeated() => $pb.PbList<TokenCategoryPayload>();
  @$core.pragma('dart2js:noInline')
  static TokenCategoryPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TokenCategoryPayload>(create);
  static TokenCategoryPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TokenCategoryParameters> get categoryParameters => $_getList(0);

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

class TokenCategoryParameters extends $pb.GeneratedMessage {
  factory TokenCategoryParameters({
    $core.List<$core.int>? secret,
    $core.String? title,
    $core.String? description,
    $core.String? tokenIds,
    $core.String? remark,
  }) {
    final $result = create();
    if (secret != null) {
      $result.secret = secret;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (tokenIds != null) {
      $result.tokenIds = tokenIds;
    }
    if (remark != null) {
      $result.remark = remark;
    }
    return $result;
  }
  TokenCategoryParameters._() : super();
  factory TokenCategoryParameters.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TokenCategoryParameters.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TokenCategoryParameters', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'tokenIds', protoName: 'tokenIds')
    ..aOS(5, _omitFieldNames ? '' : 'remark')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TokenCategoryParameters clone() => TokenCategoryParameters()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TokenCategoryParameters copyWith(void Function(TokenCategoryParameters) updates) => super.copyWith((message) => updates(message as TokenCategoryParameters)) as TokenCategoryParameters;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TokenCategoryParameters create() => TokenCategoryParameters._();
  TokenCategoryParameters createEmptyInstance() => create();
  static $pb.PbList<TokenCategoryParameters> createRepeated() => $pb.PbList<TokenCategoryParameters>();
  @$core.pragma('dart2js:noInline')
  static TokenCategoryParameters getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TokenCategoryParameters>(create);
  static TokenCategoryParameters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get tokenIds => $_getSZ(3);
  @$pb.TagNumber(4)
  set tokenIds($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTokenIds() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokenIds() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get remark => $_getSZ(4);
  @$pb.TagNumber(5)
  set remark($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasRemark() => $_has(4);
  @$pb.TagNumber(5)
  void clearRemark() => clearField(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
