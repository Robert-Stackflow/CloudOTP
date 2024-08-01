import 'dart:async';

import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/utils.dart';

enum InputItemTailingType { none, clear, password, icon, text, widget }

enum InputItemLeadingType { none, icon, text, widget }

enum InputState { normal, success, error }

class InputStateController {
  TextEditingController controller;
  InputState state = InputState.normal;
  String? errorMessage;
  Future<String?> Function(String) validate;
  void Function() onStateChanged = () {};
  Function()? pop;

  InputStateController({
    required this.controller,
    this.state = InputState.normal,
    this.errorMessage,
    required this.validate,
  }) {
    controller.addListener(doValidate);
  }

  Future<String?> doValidate() async {
    String? error = await validate(controller.text);
    errorMessage = error;
    if (Utils.isNotEmpty(error)) {
      setInputState(InputState.error);
    } else {
      setInputState(InputState.success);
    }
    onStateChanged();
    return error;
  }

  void reset() {
    setInputState(InputState.normal);
    errorMessage = null;
    onStateChanged();
  }

  Future<bool> isValid() async {
    return await doValidate() == null;
  }

  void setInputState(InputState state) {
    this.state = state;
  }

  void setError(String error) {
    errorMessage = error;
    setInputState(InputState.error);
    onStateChanged();
  }

  void setTextEditingController(TextEditingController controller) {
    this.controller = controller;
    controller.addListener(doValidate);
  }
}

class InputItem extends StatefulWidget {
  const InputItem({
    super.key,
    this.textInputAction,
    this.leadingIcon,
    this.hint,
    this.controller,
    this.obscureText,
    this.tailingType = InputItemTailingType.none,
    this.leadingType = InputItemLeadingType.none,
    this.stateController,
    this.tailingText,
    this.showTailing,
    this.tailingIcon,
    this.onTailingTap,
    this.tailingWidget,
    this.leadingWidget,
    this.leadingText,
    this.backgroundColor,
    this.keyboardType,
    this.focusNode,
    this.topRadius,
    this.bottomRadius,
    this.readOnly,
    this.maxLength,
    this.inputFormatters = const [],
    this.leadingMinWidth,
    this.maxLines,
    this.minLines,
  });

  final TextInputAction? textInputAction;
  final IconData? leadingIcon;
  final String? hint;
  final TextEditingController? controller;
  final bool? obscureText;
  final InputItemTailingType tailingType;
  final InputItemLeadingType leadingType;
  final InputStateController? stateController;
  final String? tailingText;
  final bool? showTailing;
  final IconData? tailingIcon;
  final Function()? onTailingTap;
  final Widget? tailingWidget;
  final Widget? leadingWidget;
  final int? maxLines;
  final int? minLines;
  final String? leadingText;
  final Color? backgroundColor;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool? topRadius;
  final bool? bottomRadius;
  final bool? readOnly;
  final int? maxLength;
  final List<TextInputFormatter> inputFormatters;
  final double? leadingMinWidth;

  @override
  State<StatefulWidget> createState() => InputItemState();
}

class InputItemState extends State<InputItem> {
  TextInputAction get textInputAction =>
      widget.textInputAction ?? TextInputAction.done;
  late InputStateController stateController;

  List<TextInputFormatter> get inputFormatters => widget.inputFormatters;

  IconData? get leadingIcon => widget.leadingIcon;

  String? get hint => widget.hint;

  late TextEditingController controller;

  late bool obscureText;

  InputItemTailingType get tailingType => widget.tailingType;

  InputItemLeadingType get leadingType => widget.leadingType;

  String? get tailingText => widget.tailingText;

  bool get showTailing => widget.showTailing ?? true;

  IconData? get tailingIcon => widget.tailingIcon;

  Function()? get onTailingTap => widget.onTailingTap;

  Widget? get tailingWidget => widget.tailingWidget;

  Widget? get leadingWidget => widget.leadingWidget;

  String? get leadingText => widget.leadingText;

  Color? get backgroundColor => widget.backgroundColor;

  TextInputType get keyboardType => widget.keyboardType ?? TextInputType.text;

  FocusNode? get focusNode => widget.focusNode;

  bool get topRadius => widget.topRadius ?? false;

  bool get bottomRadius => widget.bottomRadius ?? false;

  bool get readOnly => widget.readOnly ?? false;

  InputState get state => stateController.state;

  String get errorMessage => stateController.errorMessage ?? '';

  int? get maxLength => widget.maxLength;

  int? get maxLines => widget.maxLines;

  int? get minLines => widget.minLines;

  double get leadingMinWidth => widget.leadingMinWidth ?? 40;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    obscureText = widget.obscureText ?? false;
    stateController = widget.stateController ??
        InputStateController(
            controller: controller, validate: (value) => Future.value(null));
    stateController.onStateChanged = () {
      if (mounted) setState(() {});
    };
    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? leading = getLeading();
    Widget? tailing = getTailing();
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).canvasColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.vertical(
          top: topRadius ? const Radius.circular(10) : Radius.zero,
          bottom: bottomRadius ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: leading,
                ),
              Expanded(
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: state == InputState.error
                              ? Colors.red
                              : Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: TextField(
                              focusNode: focusNode,
                              controller: controller,
                              textInputAction: textInputAction,
                              keyboardType: keyboardType,
                              readOnly: readOnly,
                              obscureText: obscureText,
                              maxLength: maxLength,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    letterSpacing: 1.1,
                                    color: readOnly
                                        ? Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.color
                                        : null,
                                  ),
                              maxLines: widget.tailingType ==
                                          InputItemTailingType.password ||
                                      (widget.obscureText != null &&
                                          widget.obscureText!)
                                  ? 1
                                  : widget.maxLines,
                              minLines: minLines,
                              inputFormatters: [
                                if (maxLength != null && maxLength! > 0)
                                  LengthLimitingTextInputFormatter(maxLength),
                                ...inputFormatters
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintText: hint,
                                contentPadding: EdgeInsets.only(
                                    top: 8, left: leading != null ? 10 : 5),
                                counterText: '',
                                counter: Container(),
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.apply(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color),
                                prefixIcon: null,
                              ),
                              contextMenuBuilder:
                                  (contextMenuContext, details) =>
                                      ItemBuilder.editTextContextMenuBuilder(
                                          contextMenuContext, details,
                                          context: context),
                            ),
                          ),
                        ),
                        if (tailing != null) tailing,
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          state == InputState.error && errorMessage.isNotEmpty
                              ? errorMessage
                              : '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.apply(color: Colors.red),
                        ),
                      ),
                      if (maxLength != null && maxLength! > 0)
                        Text(
                          '${controller.text.length}/$maxLength',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? getLeading() {
    Widget? leading;
    if (leadingType == InputItemLeadingType.text &&
        Utils.isNotEmpty(leadingText)) {
      leading = Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: leadingMinWidth),
        margin: const EdgeInsets.only(left: 10, right: 5),
        child: Text(
          leadingText!,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
      );
    }
    if (leadingType == InputItemLeadingType.icon && leadingIcon != null) {
      leading = Icon(leadingIcon, color: Theme.of(context).iconTheme.color);
    }
    if (leadingType == InputItemLeadingType.widget && leadingWidget != null) {
      leading = leadingWidget;
    }
    return leading;
  }

  Widget? getTailing() {
    Widget? tailing;
    Function()? defaultTapFunction;
    if (tailingType == InputItemTailingType.clear) {
      tailing = Icon(Icons.clear_rounded,
          color: Theme.of(context).iconTheme.color?.withAlpha(120));
      defaultTapFunction = () {
        controller.clear();
      };
    }
    if (tailingType == InputItemTailingType.password) {
      defaultTapFunction = () {
        obscureText = !obscureText;
        setState(() {});
      };
      tailing = Container(
        margin: const EdgeInsets.only(bottom: 3),
        child: ItemBuilder.buildIconButton(
          context: context,
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).iconTheme.color?.withAlpha(120),
              size: 16),
          onTap: defaultTapFunction,
        ),
      );
    }
    if (tailingType == InputItemTailingType.icon && tailingIcon != null) {
      tailing = Icon(tailingIcon, color: Theme.of(context).iconTheme.color);
    }
    if (tailingType == InputItemTailingType.text && tailingText != null) {
      tailing = Text(
        tailingText!,
        style: Theme.of(context).textTheme.titleSmall?.apply(
              color: showTailing
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.labelSmall?.color,
              fontWeightDelta: 2,
            ),
      );
    }
    if (tailingType == InputItemTailingType.widget && tailingWidget != null) {
      tailing = tailingWidget;
    }
    if (tailing != null) {
      tailing = GestureDetector(
        onTap: () {
          if (showTailing) {
            onTailingTap?.call();
            defaultTapFunction?.call();
          }
        },
        child: ItemBuilder.buildClickItem(tailing),
      );
    }
    return tailing;
  }
}

class RegexInputFormatter implements TextInputFormatter {
  final RegExp regex;

  RegexInputFormatter(this.regex);

  static RegexInputFormatter onlyNumber = RegexInputFormatter(RegExp(r'^\d*$'));
  static RegexInputFormatter onlyLetter =
      RegexInputFormatter(RegExp(r'^[a-zA-Z]*$'));
  static RegexInputFormatter onlyNumberAndLetter =
      RegexInputFormatter(RegExp(r'^[a-zA-Z0-9]*$'));
  static RegexInputFormatter onlyUrl = RegexInputFormatter(
      RegExp(r'''^[a-zA-Z0-9!@#$%^&*()-_+=~{}:";',./|\\\[\]<>?]+$'''));

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newString = newValue.text;
    if (regex.hasMatch(newString)) {
      return newValue;
    }
    return oldValue;
  }
}
