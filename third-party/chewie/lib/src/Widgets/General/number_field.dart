import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class NumberField extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;
  final double step;
  final ValueChanged<double>? onChanged;
  final double height;
  final int decimalPrecision;

  const NumberField({
    super.key,
    this.initialValue = 0,
    this.onChanged,
    this.minValue = 0,
    this.maxValue = 100,
    this.step = 1,
    this.height = 40,
    this.decimalPrecision = 2,
  })  : assert(step > 0),
        assert(maxValue > minValue),
        assert(decimalPrecision >= 0);

  @override
  NumberFieldState createState() => NumberFieldState();
}

class NumberFieldState extends State<NumberField> {
  double _value = 0;
  late TextEditingController _controller;
  bool _isLongPressing = false;
  late VoidCallback _incrementCallback;
  late VoidCallback _decrementCallback;

  int _longPressDuration = 0;
  final int _longPressThreshold = 1000;

  double get _maxStepRatio => 100;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _controller = TextEditingController();
    _updateTextController(_formatValue());

    _incrementCallback = () {
      setState(() {
        if (_value < widget.maxValue) {
          _value += widget.step * _getDynamicStep();
          _value = _value.clamp(widget.minValue, widget.maxValue);
          _updateTextController(_formatValue());
          widget.onChanged?.call(_value);
        }
      });
    };

    _decrementCallback = () {
      setState(() {
        if (_value > widget.minValue) {
          _value -= widget.step * _getDynamicStep();
          _value = _value.clamp(widget.minValue, widget.maxValue);
          _updateTextController(_formatValue());
          widget.onChanged?.call(_value);
        }
      });
    };

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _updateTextController(_formatValue());
      }
    });
  }

  void _updateTextController(String text) {
    final cursorPosition = _controller.selection.baseOffset;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(
      offset: cursorPosition.clamp(0, _controller.text.length),
    );
    _value = double.tryParse(text) ?? _value;
  }

  double _getDynamicStep() {
    double dynamicStep = 1.0;
    if (_longPressDuration >= _longPressThreshold) {
      dynamicStep =
          max(min(_longPressDuration / _longPressThreshold, _maxStepRatio), 1);
    }
    return dynamicStep;
  }

  String _formatValue() {
    String minimal = _value.toString();
    if (minimal.contains('.')) {
      int currentDecimals = minimal.split('.')[1].length;
      if (currentDecimals > widget.decimalPrecision) {
        minimal = _value.toStringAsFixed(widget.decimalPrecision);
      }
      minimal = minimal.replaceFirstMapped(
          RegExp(r'(\.\d*?[1-9])0+$'), (match) => match.group(1)!);
      minimal = minimal.replaceFirst(RegExp(r'\.0+$'), '');
      return minimal;
    }
    return minimal;
  }

  void _onLongPressIncrement() {
    _isLongPressing = true;
    _longPressDuration = 0;
    _incrementCallback();
    Future.delayed(const Duration(milliseconds: 300), _longPressLoopIncrement);
  }

  void _longPressLoopIncrement() {
    if (_isLongPressing) {
      _longPressDuration += 100;
      _incrementCallback();
      Future.delayed(
          const Duration(milliseconds: 100), _longPressLoopIncrement);
    }
  }

  void _onLongPressDecrement() {
    _isLongPressing = true;
    _longPressDuration = 0;
    _decrementCallback();
    Future.delayed(const Duration(milliseconds: 300), _longPressLoopDecrement);
  }

  void _longPressLoopDecrement() {
    if (_isLongPressing) {
      _longPressDuration += 100;
      _decrementCallback();
      Future.delayed(
          const Duration(milliseconds: 100), _longPressLoopDecrement);
    }
  }

  void resetLongPress() {
    _isLongPressing = false;
    _longPressDuration = 0;
  }

  void _onTextChanged(String value) {
    double? newValue = double.tryParse(value);
    if (newValue != null) {
      _value = newValue.clamp(widget.minValue, widget.maxValue);
      setState(() {
        widget.onChanged?.call(_value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkAnimation(
            onTap: _decrementCallback,
            onLongPress: _onLongPressDecrement,
            onLongPressUp: resetLongPress,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(6)),
            child: Container(
              width: widget.height,
              height: widget.height,
              decoration: BoxDecoration(
                border: Border(
                  left: ChewieTheme.borderSideWithWidth(0.6),
                  top: ChewieTheme.borderSideWithWidth(0.6),
                  bottom: ChewieTheme.borderSideWithWidth(0.6),
                ),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              child: const Icon(Icons.remove_rounded, size: 16),
            ),
          ),
          SizedBox(
            width: widget.height * 2,
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: _onTextChanged,
              onEditingComplete: () => widget.onChanged?.call(_value),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?$')),
              ],
              style: ChewieTheme.bodyMedium
                  .apply(fontWeightDelta: 2, fontSizeDelta: -1),
              cursorColor: ChewieTheme.primaryColor,
              cursorRadius: const Radius.circular(8),
              cursorOpacityAnimates: true,
              cursorHeight: 16,
              decoration: InputDecoration(
                filled: true,
                fillColor: ChewieTheme.canvasColor,
                border: OutlineInputBorder(
                  borderSide: ChewieTheme.borderSideWithWidth(0.6),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: ChewieTheme.primaryColor, width: 0.8),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: ChewieTheme.borderSideWithWidth(0.6),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: ChewieTheme.borderSideWithWidth(0.6),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                errorBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: ChewieTheme.errorColor, width: 0.8),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: ChewieTheme.errorColor, width: 1),
                  borderRadius: BorderRadius.circular(0),
                  gapPadding: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InkAnimation(
            onTap: _incrementCallback,
            onLongPress: _onLongPressIncrement,
            onLongPressUp: resetLongPress,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(6)),
            child: Container(
              width: widget.height,
              height: widget.height,
              decoration: BoxDecoration(
                border: Border(
                  right: ChewieTheme.borderSideWithWidth(0.6),
                  top: ChewieTheme.borderSideWithWidth(0.6),
                  bottom: ChewieTheme.borderSideWithWidth(0.6),
                ),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(6)),
              ),
              child: const Icon(Icons.add_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
