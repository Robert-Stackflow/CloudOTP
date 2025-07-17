import 'package:flutter/cupertino.dart';
import 'package:pinyin/pinyin.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class SearchConfig {
  final bool enableSplit;
  bool enablePinyin;
  bool enableShortPinyin;
  bool caseSensitive;

  SearchConfig({
    this.enablePinyin = true,
    this.enableShortPinyin = false,
    this.caseSensitive = false,
  }) : enableSplit = true;

  @override
  String toString() {
    return 'SearchConfig{enableSplit: $enableSplit, enablePinyin: $enablePinyin, enableShortPinyin: $enableShortPinyin}';
  }
}

abstract class SearchableStatefulWidget extends StatefulWidget {
  final String searchText;
  final SearchConfig? searchConfig;

  final String title;
  final String description;

  const SearchableStatefulWidget({
    super.key,
    this.searchConfig,
    this.searchText = "",
    required this.title,
    this.description = "",
  });

  List<String> get sentences => [title, description];

  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  });
}

abstract class SearchableState<T extends SearchableStatefulWidget>
    extends BaseDynamicState<T> {
  bool get shouldShow {
    final searchText = widget.searchText.trim().toLowerCase();
    if (searchText.isEmpty) return true;

    final queries = searchText.split(RegExp(r'\s+'));

    return queries.any((query) {
      return _matchesOriginal(query) ||
          _matchesPinyin(query) ||
          _matchesAbbreviation(query);
    });
  }

  bool _matchesOriginal(String query) {
    return widget.sentences
        .any((keyword) => keyword.toLowerCase().contains(query));
  }

  bool _matchesPinyin(String query) {
    var tmpSearchConfig = widget.searchConfig ?? SearchConfig();
    for (final keyword in widget.sentences) {
      final lower = keyword.toLowerCase();
      final pinyinStr =
          PinyinHelper.getPinyinE(lower, separator: '<EOS>', defPinyin: '');
      List<String> singlePinyins = pinyinStr.split('<EOS>');
      if (tmpSearchConfig.enablePinyin && pinyinStr.isNotEmpty) {
        for (int s = 0; s < singlePinyins.length; s++) {
          for (int e = s + 1; e <= singlePinyins.length; e++) {
            final pinyinSlice = singlePinyins.sublist(s, e).join();
            if (pinyinSlice.toLowerCase() == query) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool _matchesAbbreviation(String query) {
    var tmpSearchConfig = widget.searchConfig ?? SearchConfig();
    for (final keyword in widget.sentences) {
      final lower = keyword.toLowerCase();
      final abbr = PinyinHelper.getShortPinyin(lower);
      if (tmpSearchConfig.enableShortPinyin &&
          abbr.isNotEmpty &&
          abbr.contains(query)) {
        return true;
      }
    }
    return false;
  }
}

class SearchableBuilderWidget extends SearchableStatefulWidget {
  final Widget Function(
    BuildContext context,
    String title,
    String description,
    String searchText,
    SearchConfig? searchConfig,
  ) builder;

  const SearchableBuilderWidget({
    super.key,
    super.searchText,
    super.description,
    super.searchConfig,
    required super.title,
    required this.builder,
  });

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return SearchableBuilderWidget(
      key: key,
      title: title,
      searchConfig: searchConfig,
      description: description,
      searchText: searchText ?? this.searchText,
      builder: builder,
    );
  }

  @override
  State<SearchableBuilderWidget> createState() =>
      _SearchableBuilderWidgetState();
}

class _SearchableBuilderWidgetState
    extends SearchableState<SearchableBuilderWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.title, widget.description,
        widget.searchText, widget.searchConfig);
  }
}
