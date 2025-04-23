import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ChewieAssetUtil {
  static load(
    String path, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      path,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static loadFile(String path) async {
    return await rootBundle.loadString(path);
  }

  static loadDynamic(
    BuildContext context,
    String light,
    String dark, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      ColorUtil.isDark(context) ? dark : light,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static loadDecorationImage(
    String path, {
    BoxFit? fit,
  }) {
    return DecorationImage(
      image: AssetImage(path),
      fit: fit,
    );
  }
}
