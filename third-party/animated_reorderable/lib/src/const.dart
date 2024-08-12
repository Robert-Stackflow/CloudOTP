import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

const alpha = 0.001;

const maxInt = kIsWeb ? 9007199254740992 : ((1 << 63) - 1);

const maxZIndex = maxInt;

const defaultZIndex = 0;

const outgoingItemZIndex = -1;

const defaultAutoScrollVelocityScalar = 50.0;

const duration500ms = Duration(milliseconds: 500);

const defaultMotionAnimationCurve = Curves.easeInOut;

const defaultMotionAnimationDuration = duration500ms;

const defaultSwipeToRemoveExtent = 0.6;

const defaultSwipeToRemoveVelocity = 700.0;

const defaultSwipedItemDecorationAnimationDuration = duration500ms;

const defaultDraggedItemDecorationAnimationDuration = duration500ms;

const defaultInsertItemAnimationDuration = duration500ms;

const defaultRemoveItemAnimationDuration = duration500ms;

const defaultFlingSpringDescription = SpringDescription(
  mass: 1.0,
  stiffness: 500.0,
  damping: 75.0,
);
