import 'dart:async';

import 'package:flutter/cupertino.dart';

mixin RefreshMixin {
  FutureOr refresh();

  FutureOr scrollToTop();

  ScrollController? getScrollController();
}

mixin BottomNavgationMixin {
  FutureOr onTapBottomNavigation();
}

mixin ScrollToHideMixin {
  List<ScrollController> getScrollControllers();
}

abstract class StatefulWidgetForFlow extends StatefulWidget {
  final double triggerOffset;
  final bool nested;
  final ScrollController? scrollController;

  const StatefulWidgetForFlow({
    super.key,
    this.scrollController,
    this.triggerOffset = 0,
    this.nested = false,
  });

  @override
  State<StatefulWidget> createState();
}
