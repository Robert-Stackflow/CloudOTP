/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'my_adaptive_text_selection_toolbar.dart';
import 'my_selectable_region.dart';

/// A widget that introduces an area for user selections with adaptive selection
/// controls.
///
/// This widget creates a [SelectableRegion] with platform-adaptive selection
/// controls.
///
/// Flutter widgets are not selectable by default. To enable selection for
/// a specific screen, consider wrapping the body of the [Route] with a
/// [MySelectionArea].
///
/// The [MySelectionArea] widget must have a [Localizations] ancestor that
/// contains a [MaterialLocalizations] delegate; using the [MaterialApp] widget
/// ensures that such an ancestor is present.
///
/// {@tool dartpad}
/// This example shows how to make a screen selectable.
///
/// ** See code in examples/api/lib/material/selection_area/selection_area.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SelectableRegion], which provides an overview of the selection system.
///  * [SelectableText], which enables selection on a single run of text.
class MySelectionArea extends StatefulWidget {
  /// Creates a [MySelectionArea].
  ///
  /// If [selectionControls] is null, a platform specific one is used.
  const MySelectionArea({
    super.key,
    this.focusNode,
    this.selectionControls,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.onRightclick,
    this.magnifierConfiguration,
    this.onSelectionChanged,
    required this.child,
  });

  /// The configuration for the magnifier in the selection region.
  ///
  /// By default, builds a [CupertinoTextMagnifier] on iOS and [TextMagnifier]
  /// on Android, and builds nothing on all other platforms. To suppress the
  /// magnifier, consider passing [TextMagnifierConfiguration.disabled].
  ///
  /// {@macro flutter.widgets.magnifier.intro}
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The delegate to build the selection handles and toolbar.
  ///
  /// If it is null, the platform specific selection control is used.
  final TextSelectionControls? selectionControls;

  /// {@macro flutter.widgets.EditableText.contextMenuBuilder}
  ///
  /// If not provided, will build a default menu based on the ambient
  /// [ThemeData.platform].
  ///
  /// {@tool dartpad}
  /// This example shows how to build a custom context menu for any selected
  /// content in a SelectionArea.
  ///
  /// ** See code in examples/api/lib/material/context_menu/selectable_region_toolbar_builder.0.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [AdaptiveTextSelectionToolbar], which is built by default.
  final MySelectableRegionContextMenuBuilder? contextMenuBuilder;

  final MySelectableRegionRightclickCallback? onRightclick;

  /// Called when the selected content changes.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  static Widget _defaultContextMenuBuilder(
      BuildContext context, MySelectableRegionState selectableRegionState) {
    return MyAdaptiveTextSelectionToolbar.selectableRegion(
      selectableRegionState: selectableRegionState,
    );
  }

  @override
  State<StatefulWidget> createState() => _MySelectionAreaState();
}

class _MySelectionAreaState extends State<MySelectionArea> {
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());
  FocusNode? _internalNode;

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final TextSelectionControls controls = widget.selectionControls ??
        switch (Theme.of(context).platform) {
          TargetPlatform.android ||
          TargetPlatform.fuchsia =>
            materialTextSelectionHandleControls,
          TargetPlatform.linux ||
          TargetPlatform.windows =>
            desktopTextSelectionHandleControls,
          TargetPlatform.iOS => cupertinoTextSelectionHandleControls,
          TargetPlatform.macOS => cupertinoDesktopTextSelectionHandleControls,
        };
    return MySelectableRegion(
      selectionControls: controls,
      focusNode: _effectiveFocusNode,
      contextMenuBuilder: widget.contextMenuBuilder,
      onRightclick: widget.onRightclick,
      magnifierConfiguration: widget.magnifierConfiguration ??
          TextMagnifier.adaptiveMagnifierConfiguration,
      onSelectionChanged: widget.onSelectionChanged,
      child: widget.child,
    );
  }
}
