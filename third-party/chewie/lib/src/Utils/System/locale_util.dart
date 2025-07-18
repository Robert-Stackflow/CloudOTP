import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class LocaleUtil with ChangeNotifier {
  static List<Tuple2<String, Locale?>> localeLabels = <Tuple2<String, Locale?>>[
    Tuple2(chewieLocalizations.followSystem, null),
    const Tuple2("Deutsch", Locale("de")),
    const Tuple2("English", Locale("en")),
    const Tuple2("Español", Locale("es")),
    const Tuple2("Français", Locale("fr")),
    const Tuple2("hrvatski", Locale("hr")),
    const Tuple2("Português do Brasil", Locale("pt")),
    const Tuple2("Türkçe", Locale("tr")),
    const Tuple2("Українська", Locale("uk")),
    const Tuple2("简体中文", Locale("zh", "CN")),
    const Tuple2("繁體中文", Locale("zh", "TW")),
    const Tuple2("日本語", Locale("ja")),
  ];

  static Tuple2<String, Locale?>? getTuple(Locale? locale) {
    if (locale == null) {
      return LocaleUtil.localeLabels[0];
    }
    for (Tuple2<String, Locale?> t in LocaleUtil.localeLabels) {
      if (t.item2.toString() == locale.toString()) {
        return t;
      }
    }
    return null;
  }

  static SelectionItemModel<Locale?>? getSelectionItemModel(Locale? locale) {
    if (locale == null) {
      return SelectionItemModel<Locale?>(
          chewieLocalizations.followSystem, null);
    }
    for (Tuple2<String, Locale?> t in LocaleUtil.localeLabels) {
      if (t.item2.toString() == locale.toString()) {
        return SelectionItemModel<Locale?>(t.item1, t.item2);
      }
    }
    return null;
  }

  static String? getLabel(Locale? locale) {
    return getTuple(locale)?.item1;
  }

  static Locale? getLocale(String label) {
    for (Tuple2<String, Locale?> t in LocaleUtil.localeLabels) {
      if (t.item1 == label) {
        return t.item2;
      }
    }
    return null;
  }
}
