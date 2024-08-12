library model;

import 'dart:collection';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/widgets.dart';

import '../const.dart';
import '../widget/item_widget.dart' show RenderedItem;
import './permutations.dart';
import '../util/misc.dart';
import '../util/offset_animation.dart';

part 'item.dart';
part 'overlayed_item.dart';
part 'item_builder.dart';
part 'item_decorator.dart';
part 'controller_state.dart';
