import 'package:flutter/material.dart';

/// Custom builder method to create custom buttons by index
typedef GroupButtonIndexedBuilder = Widget Function(
  bool selected,
  int index,
  BuildContext context,
);

/// Custom builder method to create custom buttons by value
typedef GroupButtonValueBuilder<T> = Widget Function(
  bool selected,
  T value,
  BuildContext context,
  Function()? onTap,
  bool disabled,
);

/// Custom builder method to create custom buttons by index
typedef GroupButtonIndexedTextBuilder = String Function(
  bool selected,
  int index,
  BuildContext context,
);

/// Custom builder method to create custom buttons by value
typedef GroupbuttonTextBuilder<T> = String Function(
  bool selected,
  T value,
  BuildContext context,
);
