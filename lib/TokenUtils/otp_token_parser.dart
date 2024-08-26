import 'dart:convert';

import 'package:cloudotp/Models/Proto/OtpMigration/otp_migration.pb.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:protobuf/protobuf.dart';

import '../Models/Proto/CloudOtpToken/cloudotp_token_payload.pb.dart';
import '../Models/Proto/TokenCategory/token_category_payload.pb.dart';
import '../Models/opt_token.dart';
import '../Models/token_category.dart';
import '../Utils/constant.dart';
import 'check_token_util.dart';
import 'token_image_util.dart';

class OtpTokenParser {
  static Uri toUri(OtpToken token) {
    String labelAndIssuer;
    if (!Utils.isEmpty(token.issuer)) {
      labelAndIssuer = "${token.issuer}:${token.account}";
    } else {
      labelAndIssuer = token.account;
    }
    String uriText =
        "otpauth://${token.tokenType.authority}/$labelAndIssuer?secret=${token.secret}&algorithm=${token.algorithm.label}&digits=${token.digits.digit}&period=${token.period}";
    switch (token.tokenType) {
      case OtpTokenType.HOTP:
        uriText += "&counter=${token.counter + 1}";
        break;
      case OtpTokenType.MOTP:
        uriText +=
            "motp://$labelAndIssuer?secret=${token.secret}&pin=${token.pin}";
      case OtpTokenType.Yandex:
        uriText += "&pin=${token.pin}";
      case OtpTokenType.TOTP:
      default:
        break;
    }
    return Uri.parse(Uri.encodeFull(uriText));
  }

  static List<OtpToken> parseUri(String line) {
    Uri uri = Uri.tryParse(line) ?? Uri();
    if (!(otpauthReg.hasMatch(line) ||
        motpReg.hasMatch(line) ||
        otpauthMigrationReg.hasMatch(line) ||
        cloudotpauthMigrationReg.hasMatch(line))) {
      return [];
    }
    try {
      if (cloudotpauthMigrationReg.hasMatch(line)) {
        return parseCloudOtpauthMigrationUri(uri);
      } else if (otpauthMigrationReg.hasMatch(line)) {
        return parseOtpauthMigrationUri(uri);
      } else if (motpReg.hasMatch(line)) {
        OtpToken? token = parseMotpUri(line);
        return token == null ? [] : [token];
      } else {
        OtpToken? token = parseOtpauthUri(uri);
        return token == null ? [] : [token];
      }
    } catch (e, t) {
      print("$e\n$t");
      return [];
    }
  }

  static OtpToken? parseOtpauthUri(Uri uri) {
    if (Utils.isEmpty(uri.path) ||
        Utils.isEmpty(uri.authority) ||
        uri.queryParameters.isEmpty ||
        !uri.queryParameters.containsKey("secret")) {
      return null;
    }
    OtpToken token = OtpToken.init();
    //Get the token type
    String authority = uri.authority;
    token.tokenType = OtpTokenType.fromString(authority);
    if (uri.queryParameters.containsKey("steam")) {
      token.tokenType = OtpTokenType.Steam;
    }
    //Get the path
    String path = uri.path;
    int j = 0;
    while (path[j] == '/') {
      j++;
    }
    path = Uri.decodeFull(path.substring(j));
    if (path.isEmpty) return null;
    int i = path.indexOf(':');
    //Get the issuer
    String issuerExt;
    if (i < 0) {
      issuerExt = "";
    } else {
      issuerExt = path.substring(0, i);
    }
    //Get the account
    if (i >= 0) {
      token.account = path.substring(i + 1);
    } else {
      token.account = path;
    }
    //Get the query parameters
    Map<String, String> queryParameters = uri.queryParameters;
    if (queryParameters.containsKey("issuer") &&
        Utils.isNotEmpty(queryParameters["issuer"])) {
      token.issuer = queryParameters["issuer"]!;
    } else {
      token.issuer = issuerExt;
    }
    if (queryParameters.containsKey("algorithm") &&
        Utils.isNotEmpty(queryParameters["algorithm"])) {
      token.algorithm = OtpAlgorithm.fromString(queryParameters["algorithm"]!);
    } else {
      token.algorithm = OtpAlgorithm.SHA1;
    }
    if (queryParameters.containsKey("digits") &&
        Utils.isNotEmpty(queryParameters["digits"])) {
      token.digits = OtpDigits.froMString(queryParameters["digits"]!);
    } else {
      token.digits = token.tokenType.defaultDigits;
    }
    if (queryParameters.containsKey("period") &&
        Utils.isNotEmpty(queryParameters["period"])) {
      token.periodString = queryParameters["period"]!;
    } else {
      token.periodString = token.tokenType.defaultPeriod.toString();
    }
    if (queryParameters.containsKey("counter") &&
        Utils.isNotEmpty(queryParameters["counter"])) {
      token.counterString = queryParameters["counter"]!;
    } else {
      token.counterString = "0";
    }
    if (queryParameters.containsKey("secret") &&
        Utils.isNotEmpty(queryParameters["secret"])) {
      token.secret = queryParameters["secret"]!;
      if (!CheckTokenUtil.isSecretBase32(token.secret)) return null;
    }
    if (queryParameters.containsKey("pin")) {
      token.pin = queryParameters["pin"]!;
    }
    token.imagePath = TokenImageUtil.matchBrandLogo(token) ?? "";
    return token;
  }

  static OtpToken? parseMotpUri(String line) {
    Uri uri = Uri.tryParse(line) ?? Uri();
    var match = motpReg.firstMatch(line);
    OtpToken token = OtpToken.init();
    token.tokenType = OtpTokenType.MOTP;
    String issuerAndUsername = ":";
    if (match!.groupCount > 2) {
      issuerAndUsername = match.group(1)!;
    }
    String issuerExt = issuerAndUsername.split(":")[0];
    token.account = issuerAndUsername.split(":")[1];
    Map<String, String> queryParameters = uri.queryParameters;
    if (queryParameters.containsKey("pin")) {
      token.pin = queryParameters["pin"]!;
    }
    if (queryParameters.containsKey("issuer") &&
        Utils.isNotEmpty(queryParameters["issuer"])) {
      token.issuer = queryParameters["issuer"]!;
    } else {
      token.issuer = issuerExt;
    }
    if (queryParameters.containsKey("digits") &&
        Utils.isNotEmpty(queryParameters["digits"])) {
      token.digits = OtpDigits.froMString(queryParameters["digits"]!);
    } else {
      token.digits = token.tokenType.defaultDigits;
    }
    if (queryParameters.containsKey("period") &&
        Utils.isNotEmpty(queryParameters["period"])) {
      token.periodString = queryParameters["period"]!;
    } else {
      token.periodString = token.tokenType.defaultPeriod.toString();
    }
    if (queryParameters.containsKey("secret") &&
        Utils.isNotEmpty(queryParameters["secret"])) {
      token.secret = queryParameters["secret"]!;
      if (!CheckTokenUtil.isSecretBase32(token.secret)) return null;
    }
    token.imagePath = TokenImageUtil.matchBrandLogo(token) ?? "";
    return token;
  }

  static List<OtpToken> parseOtpauthMigrationUri(Uri uri) {
    if (!uri.queryParameters.containsKey("data") ||
        Utils.isEmpty(uri.queryParameters["data"])) {
      return [];
    }
    String rawData = uri.queryParameters["data"]!;
    if (rawData.length % 4 != 0) {
      final nextFactor = (rawData.length + 4 - 1) ~/ 4 * 4;
      rawData = rawData.padRight(nextFactor, '=');
    }
    OtpMigrationPayload payload =
        OtpMigrationPayload.fromBuffer(base64Decode(rawData));
    List<OtpToken> tokens = [];
    for (var param in payload.otpParameters) {
      OtpToken? token = OtpToken.fromOtpMigrationParameters(param);
      if (token != null) {
        tokens.add(token);
      }
    }
    return tokens;
  }

  static List<OtpToken> parseCloudOtpauthMigrationUri(Uri uri) {
    if (!uri.queryParameters.containsKey("tokens") ||
        Utils.isEmpty(uri.queryParameters["tokens"])) {
      return [];
    }
    String rawData = uri.queryParameters["tokens"]!;
    if (rawData.length % 4 != 0) {
      final nextFactor = (rawData.length + 4 - 1) ~/ 4 * 4;
      rawData = rawData.padRight(nextFactor, '=');
    }
    CloudOtpTokenPayload payload =
        CloudOtpTokenPayload.fromBuffer(base64Decode(rawData));
    List<OtpToken> tokens = [];
    for (var param in payload.tokenParameters) {
      OtpToken token = OtpToken.fromCloudOtpParameters(param);
      tokens.add(token);
    }
    return tokens;
  }

  static Future<List<TokenCategory>> parseCloudOtpauthCategoryMigration(
      String line) async {
    Uri uri = Uri.tryParse(line) ?? Uri();
    if (!uri.queryParameters.containsKey("categories") ||
        Utils.isEmpty(uri.queryParameters["categories"])) {
      return [];
    }
    String rawData = uri.queryParameters["categories"]!;
    if (rawData.length % 4 != 0) {
      final nextFactor = (rawData.length + 4 - 1) ~/ 4 * 4;
      rawData = rawData.padRight(nextFactor, '=');
    }
    TokenCategoryPayload payload =
        TokenCategoryPayload.fromBuffer(base64Decode(rawData));
    List<TokenCategory> categories = [];
    for (var param in payload.categoryParameters) {
      TokenCategory category = TokenCategory.fromCategoryParameters(param);
      categories.add(category);
    }
    return categories;
  }
}

enum OtpAuthMigrationDataAlgorithm {
  Unknown,
  SHA1,
  SHA256,
  SHA512,
}

enum OtpAuthMigrationDataType {
  Unknown,
  HOTP,
  TOTP,
}

class OtpAuthMigrationData {
  final String secret;
  final String username;
  final String issuer;
  final OtpAuthMigrationDataAlgorithm algorithm;
  final OtpAuthMigrationDataType type;
  final int counter;

  OtpAuthMigrationData({
    required this.secret,
    required this.username,
    required this.issuer,
    required this.algorithm,
    required this.type,
    required this.counter,
  });

  factory OtpAuthMigrationData.fromBuffer(List<int> data) {
    final reader = CodedBufferReader(data);
    String secret = reader.readString();
    String username = reader.readString();
    String issuer = reader.readString();
    OtpAuthMigrationDataAlgorithm algorithm =
        OtpAuthMigrationDataAlgorithm.values[reader.readInt32()];
    OtpAuthMigrationDataType type =
        OtpAuthMigrationDataType.values[reader.readInt32()];
    int counter = reader.readInt32();
    return OtpAuthMigrationData(
      secret: secret,
      username: username,
      issuer: issuer,
      algorithm: algorithm,
      type: type,
      counter: counter,
    );
  }
}
