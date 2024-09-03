import 'dart:async';

import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/utils.dart';

enum InputItemTailingType { none, clear, password, icon, text, widget }

enum InputItemLeadingType { none, icon, text, widget }

class InputValidateAsyncController {
  TextEditingController controller;
  String? errorMessage;
  Future<String?> Function(String) validator;
  void Function() onError = () {};
  Function()? doPop;

  InputValidateAsyncController({
    this.errorMessage,
    required this.validator,
    required this.controller,
    bool listen = true,
  }) {
    if (listen) {
      controller.addListener(validate);
    }
  }

  Future<String?> validate() async {
    String? error = await validator(controller.text);
    errorMessage = error;
    onError();
    return error;
  }

  void reset() {
    errorMessage = null;
    onError();
  }

  Future<bool> isValid() async {
    return await validate() == null;
  }

  void setError(String error) {
    errorMessage = error;
    onError();
  }
}

class InputItem extends StatefulWidget {
  const InputItem({
    super.key,
    this.textInputAction,
    this.leadingIcon,
    this.hint,
    this.controller,
    this.validateAsyncController,
    this.obscureText,
    this.tailingType = InputItemTailingType.none,
    this.leadingType = InputItemLeadingType.none,
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
    this.disabled,
    this.maxLength,
    this.inputFormatters = const [],
    this.leadingMinWidth,
    this.maxLines,
    this.minLines,
    this.onSubmit,
    this.showBorder = true,
    this.validator,
    this.dense = false,
  });

  final TextInputAction? textInputAction;
  final IconData? leadingIcon;
  final String? hint;
  final TextEditingController? controller;
  final bool? obscureText;
  final InputItemTailingType tailingType;
  final InputItemLeadingType leadingType;
  final InputValidateAsyncController? validateAsyncController;
  final FormFieldValidator? validator;
  final String? tailingText;
  final bool dense;
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
  final bool? disabled;
  final int? maxLength;
  final List<TextInputFormatter> inputFormatters;
  final double? leadingMinWidth;
  final Function(String)? onSubmit;
  final bool showBorder;

  @override
  State<StatefulWidget> createState() => InputItemState();
}

class InputItemState extends State<InputItem> {
  TextInputAction get textInputAction =>
      widget.textInputAction ?? TextInputAction.done;

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

  bool get readOnly => widget.disabled ?? false;

  String? get errorMessage => widget.validateAsyncController?.errorMessage;

  int? get maxLength => widget.maxLength;

  int? get maxLines => widget.maxLines;

  int? get minLines => widget.minLines;

  double get leadingMinWidth => widget.leadingMinWidth ?? 40;

  @override
  void initState() {
    super.initState();
    controller = widget.validateAsyncController?.controller ??
        widget.controller ??
        TextEditingController();
    obscureText = widget.obscureText ?? false;
    widget.validateAsyncController?.onError = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget? leading = getLeading();
    Widget? tailing = getTailing();
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return Container(
      margin: EdgeInsets.only(
          left: widget.dense ? 0 : 10,
          right: widget.dense ? 0 : 10,
          bottom: widget.dense ? 0 : 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.canvasColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.vertical(
          top: topRadius ? const Radius.circular(10) : Radius.zero,
          bottom: bottomRadius ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) leading,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: TextFormField(
                    focusNode: focusNode,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: controller,
                    textInputAction: textInputAction,
                    keyboardType: keyboardType,
                    readOnly: readOnly,
                    obscureText: obscureText,
                    maxLength: maxLength,
                    enabled: !readOnly,
                    scrollPhysics: const ClampingScrollPhysics(),
                    onFieldSubmitted: widget.onSubmit,
                    style: textTheme.titleMedium?.copyWith(
                      letterSpacing: 1.1,
                      color: readOnly ? textTheme.labelSmall?.color : null,
                    ),
                    maxLines: widget.tailingType ==
                                InputItemTailingType.password ||
                            (widget.obscureText != null && widget.obscureText!)
                        ? 1
                        : widget.maxLines,
                    minLines: minLines,
                    inputFormatters: [
                      if (maxLength != null && maxLength! > 0)
                        LengthLimitingTextInputFormatter(maxLength),
                      ...inputFormatters
                    ],
                    cursorColor: theme.primaryColor,
                    cursorRadius: const Radius.circular(5),
                    validator: widget.validator,
                    forceErrorText: errorMessage,
                    decoration: InputDecoration(
                      hintText: hint,
                      contentPadding: EdgeInsets.only(
                          left: 5, bottom: widget.dense ? 5 : 0),
                      counterStyle: textTheme.bodySmall,
                      isDense: widget.dense,
                      hintStyle: textTheme.titleSmall
                          ?.apply(color: textTheme.bodySmall?.color),
                      border: widget.showBorder
                          ? UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.primaryColor, width: 0.5))
                          : InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.primaryColor, width: 1)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.primaryColor, width: 0.5)),
                      disabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: textTheme.bodySmall!.color!, width: 0.5)),
                      prefixIcon: null,
                      errorStyle: textTheme.bodySmall?.apply(color: Colors.red),
                      errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1)),
                      errorMaxLines: 1,
                      focusedErrorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2)),
                    ),
                    contextMenuBuilder: (contextMenuContext, details) =>
                        ItemBuilder.editTextContextMenuBuilder(
                            contextMenuContext, details,
                            context: context),
                  ),
                ),
              ),
              if (tailing != null) tailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget? getLeading() {
    Widget? leading;
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    if (leadingType == InputItemLeadingType.text &&
        Utils.isNotEmpty(leadingText)) {
      leading = Container(
        constraints: BoxConstraints(minWidth: leadingMinWidth),
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: Text(
          leadingText!,
          style: textTheme.titleMedium
              ?.apply(fontWeightDelta: 2, fontSizeDelta: -2),
        ),
      );
    }
    if (leadingType == InputItemLeadingType.icon && leadingIcon != null) {
      leading = Icon(leadingIcon, color: theme.iconTheme.color);
    }
    if (leadingType == InputItemLeadingType.widget && leadingWidget != null) {
      leading = leadingWidget;
    }
    return leading;
  }

  Widget? getTailing() {
    Widget? tailing;
    Function()? defaultTapFunction;
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    if (tailingType == InputItemTailingType.clear) {
      tailing = Icon(Icons.clear_rounded,
          color: theme.iconTheme.color?.withAlpha(120));
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
              color: theme.iconTheme.color?.withAlpha(120), size: 16),
          onTap: defaultTapFunction,
        ),
      );
    }
    if (tailingType == InputItemTailingType.icon && tailingIcon != null) {
      tailing = Icon(tailingIcon, color: theme.iconTheme.color);
    }
    if (tailingType == InputItemTailingType.text && tailingText != null) {
      tailing = Text(
        tailingText!,
        style: textTheme.titleSmall?.apply(
          color: showTailing ? theme.primaryColor : textTheme.labelSmall?.color,
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
  static RegexInputFormatter onlyNumberAndLetterAndSymbol = RegexInputFormatter(
      RegExp(r'^[a-zA-Z0-9!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:",<>.?/\\|`~]*$'));

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

class TrimInputFormatter implements TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.trimLeft(),
      selection: newValue.selection,
    );
  }
}
