import 'package:flutter/cupertino.dart';

import '../generated/l10n.dart';

class FontSizeUtil with ChangeNotifier {
  static String getFontSizeLabel(int? fontSize) {
    if (fontSize == null) {
      return S.current.fontDefault;
    }
    switch (fontSize) {
      case 0:
        return S.current.fontMini;
      case 1:
        return S.current.fontSmall;
      case 2:
        return S.current.fontDefault;
      case 3:
        return S.current.fontBig;
      case 4:
        return S.current.fontBigger;
      case 5:
        return S.current.fontLarge;
    }
    return S.current.fontDefault;
  }

  static double getTextFactor(int? fontSize) {
    if (fontSize == null) {
      return 1;
    }
    switch (fontSize) {
      case 0:
        return 0.6;
      case 1:
        return 0.8;
      case 2:
        return 1;
      case 3:
        return 1.2;
      case 4:
        return 1.5;
      case 5:
        return 2;
    }
    return 1;
  }
}
