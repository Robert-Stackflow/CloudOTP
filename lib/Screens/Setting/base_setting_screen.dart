import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

abstract class BaseSettingScreen extends StatefulWidget {
  const BaseSettingScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
    this.searchText = "",
    this.searchConfig,
  });

  final bool showTitleBar;
  final EdgeInsets padding;
  final String searchText;
  final SearchConfig? searchConfig;

  @override
  State<StatefulWidget> createState();
}
