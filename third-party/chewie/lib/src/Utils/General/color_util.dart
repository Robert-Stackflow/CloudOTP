import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:awesome_chewie/src/Utils/enums.dart';

class ColorUtil {
  static Color getColor(String colorStr) {
    try {
      colorStr = colorStr.replaceAll("#", "");
      if (colorStr.length == 6) {
        colorStr = "FF$colorStr";
      }
      return Color(int.parse(colorStr, radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }

  static Color getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  static isDark(BuildContext context) {
    return (chewieProvider.themeMode == ActiveThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark) ||
        chewieProvider.themeMode == ActiveThemeMode.dark;
  }

  static Color getDarkColor(Color color, {Color darkColor = Colors.black}) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? color
        : darkColor;
  }

  static Future<EncodedImage> _getImagePixelsByUrl(String url) async {
    final Completer<EncodedImage> completer = Completer();
    final ImageStream stream =
        CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    final listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) async {
      final ByteData? data = await info.image.toByteData();
      if (data != null && !completer.isCompleted) {
        completer.complete(
            EncodedImage(data, width: 1, height: data.lengthInBytes ~/ 4));
      }
    });
    stream.addListener(listener);
    final EncodedImage encodedImage = await completer.future;
    stream.removeListener(listener);
    return encodedImage;
  }

  static Future<EncodedImage> _getImagePixelsByFile(File file) async {
    final Completer<EncodedImage> completer = Completer();
    final ImageStream stream =
        FileImage(file).resolve(const ImageConfiguration());
    final listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) async {
      final ByteData? data = await info.image.toByteData();
      if (data != null && !completer.isCompleted) {
        completer.complete(
            EncodedImage(data, width: 1, height: data.lengthInBytes ~/ 4));
      }
    });
    stream.addListener(listener);
    final EncodedImage encodedImage = await completer.future;
    stream.removeListener(listener);
    return encodedImage;
  }

  static FutureOr<PaletteGenerator> _getPaletteGenerator(
    EncodedImage encodedImage,
  ) async {
    final Completer<PaletteGenerator> completer = Completer();
    PaletteGenerator.fromByteData(encodedImage).then((paletteGenerator) {
      completer.complete(paletteGenerator);
    });
    return await completer.future;
  }

  static Future<PaletteGenerator> getPaletteGenerator(
    String imageUrl, {
    BuildContext? context,
    bool getByFile = true,
  }) async {
    late final EncodedImage encodedImage;
    if (getByFile && context != null) {
      File file = await FileUtil.getImageFile(context, imageUrl);
      encodedImage = await _getImagePixelsByFile(file);
    } else {
      encodedImage = await _getImagePixelsByUrl(imageUrl);
    }
    PaletteGenerator generator =
        await compute(_getPaletteGenerator, encodedImage);
    return generator;
  }

  static Future<List<Color>> getMainColors(
    BuildContext context,
    List<String> imageUrls, {
    Function()? onFinished,
  }) async {
    List<Color> mainColors = List.filled(imageUrls.length, Colors.black);
    for (var e in imageUrls) {
      int index = imageUrls.indexOf(e);
      String smallUrl = e;
      await getPaletteGenerator(smallUrl, context: context)
          .then((paletteGenerator) {
        if (paletteGenerator.darkMutedColor != null) {
          mainColors[index] = paletteGenerator.darkMutedColor!.color;
        } else if (paletteGenerator.darkVibrantColor != null) {
          mainColors[index] = paletteGenerator.darkVibrantColor!.color;
        }
      });
    }
    return mainColors;
  }

  static Color convertAlphaToOpaque(Color color) {
    final double alpha = color.a / 255.0;
    final int red = ((color.r * alpha) + (1 - alpha) * 255).round();
    final int green = ((color.g * alpha) + (1 - alpha) * 255).round();
    final int blue = ((color.b * alpha) + (1 - alpha) * 255).round();
    return Color.fromARGB(255, red, green, blue);
  }
}
