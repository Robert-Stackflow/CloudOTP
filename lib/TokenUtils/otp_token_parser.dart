import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/utils.dart';

import '../Models/opt_token.dart';
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
        "otpauth://${token.tokenType.label}/$labelAndIssuer?secret=${token.secret}&algorithm=${token.algorithm.label}&digits=${token.digits.digit}&period=${token.period}";
    switch (token.tokenType) {
      case OtpTokenType.HOTP:
        uriText += "&counter=${token.counter + 1}";
        break;
      case OtpTokenType.TOTP:
      default:
        break;
    }
    return Uri.parse(uriText);
  }

  static OtpToken? createFromUri(Uri uri) {
    OtpToken token = OtpToken.init();
    if (uri.scheme != "otpauth" ||
        Utils.isEmpty(uri.path) ||
        Utils.isEmpty(uri.authority) ||
        uri.queryParameters.isEmpty ||
        !uri.queryParameters.containsKey("secret") ||
        !OtpTokenType.TOTP.strings.contains(uri.authority.toLowerCase())) {
      return null;
    }
    if ((!uri.queryParameters.containsKey("algorithm") ||
            !uri.queryParameters.containsKey("digits") ||
            !uri.queryParameters.containsKey("period")) &&
        !HiveUtil.getBool(HiveUtil.autoCompleteParameterKey)) {
      return null;
    }
    token.tokenType =
        uri.authority == "totp" ? OtpTokenType.TOTP : OtpTokenType.HOTP;
    String path = uri.path;
    int j = 0;
    while (path[j] == '/') {
      j++;
    }
    path = Uri.decodeFull(path.substring(j));
    if (path.isEmpty) {
      return null;
    }
    int i = path.indexOf(':');
    String issuerExt;
    if (i < 0) {
      issuerExt = "";
    } else {
      issuerExt = path.substring(0, i);
    }
    if (i >= 0) {
      token.account = path.substring(i + 1);
    } else {
      token.account = path;
    }
    Map<String, String> queryParameters = uri.queryParameters;
    if (queryParameters.containsKey("issuer") &&
        Utils.isNotEmpty(queryParameters["issuer"])) {
      token.issuer = queryParameters["issuer"]!;
    } else {
      token.issuer = issuerExt;
    }
    if (queryParameters.containsKey("algorithm") &&
        Utils.isNotEmpty(queryParameters["algorithm"])) {
      token.algorithm = OtpAlgorithm.fromLabel(queryParameters["algorithm"]!);
    } else {
      token.algorithm = OtpAlgorithm.SHA1;
    }
    if (queryParameters.containsKey("digits") &&
        Utils.isNotEmpty(queryParameters["digits"])) {
      token.digits = OtpDigits.fromLabel(queryParameters["digits"]!);
    } else {
      token.digits = OtpDigits.D6;
    }
    if (queryParameters.containsKey("period") &&
        Utils.isNotEmpty(queryParameters["period"])) {
      token.periodString = queryParameters["period"]!;
    } else {
      token.periodString = "30";
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
    }
    token.imagePath = TokenImageUtil.matchBrandLogo(token) ?? "";
    return token;
  }
}
