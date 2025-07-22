import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class SelectableListViewController<T> extends ChangeNotifier {
  final Set<T> _selectedItems = {};

  Set<T> get selectedItems => _selectedItems;

  set selectedItems(Set<T> items) {
    _selectedItems.clear();
    _selectedItems.addAll(items);
    notifyListeners();
  }

  bool contains(T item) => _selectedItems.contains(item);

  bool get isNotEmpty => _selectedItems.isNotEmpty;

  int get length => _selectedItems.length;

  bool get hasSelection => isNotEmpty;

  void selectItem(T item) {
    _selectedItems.add(item);
    notifyListeners();
  }

  void selectItems(Set<T> items) {
    _selectedItems.addAll(items);
    notifyListeners();
  }

  void deselectItem(T item) {
    _selectedItems.remove(item);
    notifyListeners();
  }

  void deselectItems(Set<T> items) {
    _selectedItems.removeAll(items);
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  bool isSelected(T item) => _selectedItems.contains(item);

  void toggleItem(T item) {
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
    notifyListeners();
  }
}

class SelectableListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(
    BuildContext context,
    int index,
    T item,
    bool isSelected,
    bool isMultiSelect,
  ) itemBuilder;
  final void Function(List<T>)? onSelectionChanged;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final SelectableListViewController<T>? controller;
  final bool enableSelection;

  const SelectableListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onSelectionChanged,
    this.padding,
    this.scrollController,
    this.controller,
    this.enableSelection = true,
  });

  @override
  State<SelectableListView<T>> createState() => _SelectableListViewState<T>();
}

class _SelectableListViewState<T> extends State<SelectableListView<T>> {
  late final SelectableListViewController<T> selectionController;
  final Set<T> _hoveredItems = {};
  final _itemKeys = <GlobalKey>[];

  // 拖拽事件
  Rect? _selectionRect;
  Offset? _dragStart;
  RenderBox? _stackBox;
  bool _isDragging = false;
  final double _dragThreshold = 16.0;

  // 快捷键
  late FocusNode _focusNode;
  int? _lastTappedIndex;

  @override
  void initState() {
    super.initState();
    selectionController =
        widget.controller ?? SelectableListViewController<T>();
    selectionController.addListener(_onControllerChange);
    _itemKeys.addAll(List.generate(widget.items.length, (_) => GlobalKey()));
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(covariant SelectableListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(widget.items.length, (_) => GlobalKey()));
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      selectionController =
          widget.controller ?? SelectableListViewController<T>();
      selectionController.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    selectionController.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    setState(() {
      widget.onSelectionChanged
          ?.call(selectionController.selectedItems.toList());
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enableSelection) return;
    _stackBox ??= context.findRenderObject() as RenderBox;
    setState(() {
      _dragStart = _stackBox!.globalToLocal(event.position);
      _selectionRect = null;
      _isDragging = false;
      _hoveredItems.clear();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enableSelection) return;
    final localPosition = _stackBox!.globalToLocal(event.position);
    final dx = (localPosition.dx - _dragStart!.dx).abs();
    final dy = (localPosition.dy - _dragStart!.dy).abs();

    if (!_isDragging && (dx > _dragThreshold || dy > _dragThreshold)) {
      _isDragging = true;
    }

    if (_isDragging) {
      setState(() {
        _selectionRect = Rect.fromPoints(_dragStart!, localPosition);
        _hoveredItems.clear();
        for (int i = 0; i < _itemKeys.length; i++) {
          final context = _itemKeys[i].currentContext;
          if (context == null) continue;
          final box = context.findRenderObject() as RenderBox;
          final itemOffset =
              box.localToGlobal(Offset.zero, ancestor: _stackBox);
          final itemRect = itemOffset & box.size;
          if (_selectionRect!.overlaps(itemRect)) {
            _hoveredItems.add(widget.items[i]);
          }
        }
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enableSelection) return;
    if (_isDragging) {
      setState(() {
        _selectionRect = null;
        if (_isCtrlPressed()) {
          selectionController.selectItems(_hoveredItems);
        } else {
          selectionController.selectedItems = _hoveredItems;
        }
        _hoveredItems.clear();
      });
    } else {
      setState(() {
        _selectionRect = null;
        _hoveredItems.clear();
      });
    }
  }

  bool _isCtrlPressed() =>
      HardwareKeyboard.instance
          .isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
      HardwareKeyboard.instance
          .isLogicalKeyPressed(LogicalKeyboardKey.controlRight);

  bool _isShiftPressed() =>
      HardwareKeyboard.instance
          .isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) ||
      HardwareKeyboard.instance
          .isLogicalKeyPressed(LogicalKeyboardKey.shiftRight);

  void _onTapItem(T item, int index) {
    if (!widget.enableSelection) return;
    _focusNode.requestFocus();
    if (!selectionController.hasSelection) return;
    setState(() {
      if (_isShiftPressed()) {
        if (_lastTappedIndex != null) {
          int start = min(index, _lastTappedIndex!);
          int end = max(index, _lastTappedIndex!);
          for (int i = start; i <= end; i++) {
            selectionController.selectItem(widget.items[i]);
          }
        }
      } else {
        selectionController.toggleItem(item);
      }
      _lastTappedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        return KeyEventResult.handled;
      },
      child: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: ListView.builder(
              controller: widget.scrollController,
              padding: widget.padding,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final selected = selectionController.contains(item);
                return GestureDetector(
                  key: _itemKeys[index],
                  onTap: () => _onTapItem(item, index),
                  child: widget.itemBuilder(
                    context,
                    index,
                    item,
                    selected,
                    selectionController.hasSelection,
                  ),
                );
              },
            ),
          ),
          if (_selectionRect != null)
            IgnorePointer(
              child: CustomPaint(
                painter: _SelectionPainter(_selectionRect!),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Rect rect;

  _SelectionPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = ChewieTheme.canvasColor.withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    final border = Paint()
      ..color = ChewieTheme.cardColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
