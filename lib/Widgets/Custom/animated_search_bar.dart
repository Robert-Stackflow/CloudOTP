import 'dart:async';

import 'package:flutter/material.dart';

/// A customizable animated search bar widget for Flutter applications.
class AnimatedSearchBar extends StatefulWidget {
  /// Creates an `AnimatedSearchBar` widget.
  ///
  /// [label] is the text to display when the search bar is not active.
  /// [labelAlignment] specifies the alignment of the label text.
  /// [labelTextAlign] specifies the text alignment of the label.
  /// [onChanged] is a callback function that is called,
  ///    when the text in the search bar changes.
  /// [labelStyle] is the style for the label text.
  /// [searchDecoration] is the decoration for the search input field.
  /// [animationDuration] is the duration for the animation,
  ///   when switching between label and search input.
  /// [searchStyle] is the style for the search input text.
  /// [cursorColor] is the color of the cursor in the search input field.
  /// [duration] is the debounce duration for input changes.
  /// [height] is the height of the search bar.
  /// [closeIcon] is the icon to display when the search bar is active.
  /// [searchIcon] is the icon to display when the search bar is not active.
  /// [controller] is a TextEditingController to control the text input.
  /// [onFieldSubmitted] is a callback function that is called
  ///  when the user submits the search field.
  /// [textInputAction] is the action to take when the user presses
  ///   the keyboard's done button.

  const AnimatedSearchBar({
    super.key,
    this.label = '',
    this.labelAlignment = Alignment.centerLeft,
    this.labelTextAlign = TextAlign.start,
    this.onChanged,
    this.labelStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    this.searchDecoration,
    this.animationDuration = const Duration(milliseconds: 350),
    this.searchStyle,
    this.cursorColor,
    this.duration = const Duration(milliseconds: 300),
    this.height = 40,
    this.closeIcon,
    this.immediatelyClose = true,
    this.searchIcon,
    this.controller,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.search,
    this.onClose,
  });

  final String label;
  final Alignment labelAlignment;
  final TextAlign labelTextAlign;
  final Function(String)? onChanged;
  final bool immediatelyClose;
  final TextStyle labelStyle;
  final InputDecoration? searchDecoration;
  final Duration animationDuration;
  final TextStyle? searchStyle;
  final Color? cursorColor;
  final Duration duration;
  final double height;
  final Widget? closeIcon;
  final Widget? searchIcon;
  final TextEditingController? controller;
  final Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;
  final VoidCallback? onClose;

  @override
  AnimatedSearchBarState createState() => AnimatedSearchBarState();
}

class AnimatedSearchBarState extends State<AnimatedSearchBar> {
  late final ValueNotifier<bool> _isSearch =
      ValueNotifier(_conSearch.text.isNotEmpty);
  final _fnSearch = FocusNode();
  late final _debouncer = Debouncer(delay: widget.duration);

  late final TextEditingController _conSearch =
      widget.controller ?? TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isSearch.value) {
          _isSearch.value = true;
          _fnSearch.requestFocus();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: widget.animationDuration,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final inAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: const Offset(0.0, 0.0),
                ).animate(animation);
                final outAnimation = Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: const Offset(0.0, 0.0),
                ).animate(animation);

                return ClipRect(
                  child: SlideTransition(
                    position: child.key == const ValueKey('textF')
                        ? inAnimation
                        : outAnimation,
                    child: child,
                  ),
                );
              },
              child: ValueListenableBuilder(
                valueListenable: _isSearch,
                builder: (_, bool value, __) {
                  return value
                      ? SizedBox(
                          key: const ValueKey('textF'),
                          height: widget.height,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextFormField(
                              focusNode: _fnSearch,
                              controller: _conSearch,
                              keyboardType: TextInputType.text,
                              textInputAction: widget.textInputAction,
                              textAlign: widget.labelTextAlign,
                              style: widget.searchStyle ??
                                  Theme.of(context).textTheme.titleMedium,
                              minLines: 1,
                              cursorColor: widget.cursorColor ??
                                  Theme.of(context).primaryColor,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: widget.searchDecoration ??
                                  InputDecoration(
                                    alignLabelWithHint: true,
                                    contentPadding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                      left: 5,
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    border: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                              onChanged: widget.onChanged != null
                                  ? (value) => _debouncer
                                      .run(() => widget.onChanged?.call(value))
                                  : null,
                              onFieldSubmitted: widget.onFieldSubmitted,
                            ),
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('align'),
                          height: 60,
                          child: Align(
                            alignment: widget.labelAlignment,
                            child: Text(
                              widget.label,
                              style: widget.labelStyle,
                              textAlign: widget.labelTextAlign,
                            ),
                          ),
                        );
                },
              ),
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final inAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: const Offset(0.0, 0.0),
                ).animate(animation);
                final outAnimation = Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: const Offset(0.0, 0.0),
                ).animate(animation);

                return ClipRect(
                  child: SlideTransition(
                    position: child.key == const ValueKey('close')
                        ? inAnimation
                        : outAnimation,
                    child: child,
                  ),
                );
              },
              child: ValueListenableBuilder(
                valueListenable: _isSearch,
                builder: (_, bool value, __) => value
                    ? widget.closeIcon ??
                        Icon(
                          Icons.close_rounded,
                          key: const ValueKey('close'),
                          color: Theme.of(context).iconTheme.color,
                        )
                    : widget.searchIcon ??
                        Icon(
                          Icons.search_rounded,
                          key: const ValueKey('close'),
                          color: Theme.of(context).iconTheme.color,
                        ),
              ),
            ),
            onPressed: () {
              if (_isSearch.value && _conSearch.text.isNotEmpty) {
                _conSearch.clear();
                widget.onChanged?.call(_conSearch.text);
                if (widget.immediatelyClose) {
                  _isSearch.value = false;
                  widget.onClose?.call();
                }
              } else {
                _isSearch.value = !_isSearch.value;
                if (!_isSearch.value) widget.onClose?.call();
                if (_isSearch.value) _fnSearch.requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// A utility class for debouncing actions in Dart and Flutter applications.
class Debouncer {
  /// Creates a new Debouncer with the specified [delay].
  ///
  /// The [delay] defines the duration for which to delay the execution of
  /// the provided action after the last call to the `run` method. It is
  /// required and must be a non-null [Duration].
  Debouncer({this.delay});

  /// The delay duration for debouncing.
  Duration? delay;

  /// The callback action to be executed after the debounce delay.
  VoidCallback? _action;

  /// The timer used to manage the delay.
  Timer? _timer;

  /// Runs the provided [action] after a delay defined by [delay].
  ///
  /// If this method is called while a previous timer is active, it cancels
  /// the previous timer and starts a new one, effectively resetting the
  /// delay period.
  ///
  /// - [action]: The callback function to be executed after the delay.
  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    if (delay != null) {
      _timer = Timer(delay!, () {
        // Check if the action is not null before executing it.
        if (_action != null) {
          _action!();
        }
      });
    }
  }

  /// Cancels any active timer and clears the currently scheduled action.
  ///
  /// This can be used to prevent the scheduled action from executing if it
  /// is no longer needed.
  void cancel() {
    _timer?.cancel();
    _action = null;
  }
}
