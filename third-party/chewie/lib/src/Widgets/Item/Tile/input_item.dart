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

import 'dart:async';

import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/circle_icon_button.dart';

enum InputItemLeadingTailingType {
  none,
  clear,
  copy,
  addSelection,
  openExternal,
  password,
  icon,
  text,
  widget
}

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

class InputItemLeadingTailingConfig {
  final IconData? icon;
  final String? text;
  final Widget? widget;
  final InputItemLeadingTailingType type;
  final bool show;
  final Function()? onTap;

  InputItemLeadingTailingConfig({
    this.icon,
    this.text,
    this.widget,
    this.show = true,
    this.type = InputItemLeadingTailingType.none,
    this.onTap,
  });
}

class InputItemStyle {
  final Color? backgroundColor;
  final Color? fieldBackgroundColor;
  final EdgeInsets? contentPadding;
  final bool topRadius;
  final bool bottomRadius;
  final double titleTopMargin;
  final bool showBorder;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final double radius;
  final bool isDense;
  final double horizontalMargin;
  final double topMargin;
  final double bottomMargin;
  bool obscure;

  InputItemStyle({
    this.backgroundColor,
    this.fieldBackgroundColor,
    this.topRadius = true,
    this.bottomRadius = true,
    this.radius = 8,
    this.showBorder = true,
    this.maxLength,
    this.contentPadding,
    this.horizontalMargin = 0,
    this.topMargin = 5,
    this.bottomMargin = 5,
    this.titleTopMargin = 10,
    this.maxLines,
    this.minLines,
    this.obscure = false,
    this.isDense = true,
  });
}

class InputItem extends StatefulWidget {
  const InputItem({
    super.key,
    this.title,
    this.description,
    this.hint,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.disabled,
    this.onSubmit,
    this.validator,
    this.validateAsyncController,
    this.inputFormatters = const [],
    this.leadingConfig,
    this.tailingConfig,
    this.style,
    this.initialValue,
  });

  final TextInputAction? textInputAction;
  final String? hint;
  final TextEditingController? controller;
  final InputValidateAsyncController? validateAsyncController;
  final FormFieldValidator? validator;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool? disabled;
  final List<TextInputFormatter> inputFormatters;
  final Function(String)? onSubmit;
  final String? title;
  final String? description;
  final String? initialValue;

  final InputItemLeadingTailingConfig? leadingConfig;
  final InputItemLeadingTailingConfig? tailingConfig;
  final InputItemStyle? style;

  @override
  State<StatefulWidget> createState() => InputItemState();
}

class InputItemState extends State<InputItem> {
  TextInputAction get textInputAction =>
      widget.textInputAction ?? TextInputAction.done;

  List<TextInputFormatter> get inputFormatters => widget.inputFormatters;

  String? get hint => widget.hint;

  late TextEditingController controller;

  TextInputType get keyboardType => widget.keyboardType ?? TextInputType.text;

  FocusNode? get focusNode => widget.focusNode;

  bool get disabled => widget.disabled ?? false;

  String? get errorMessage => widget.validateAsyncController?.errorMessage;

  late InputItemLeadingTailingConfig leadingConfig;

  late InputItemLeadingTailingConfig tailingConfig;

  late InputItemStyle style;

  bool get isPassword =>
      widget.tailingConfig?.type == InputItemLeadingTailingType.password ||
      widget.leadingConfig?.type == InputItemLeadingTailingType.password;

  @override
  void initState() {
    super.initState();
    controller = widget.validateAsyncController?.controller ??
        widget.controller ??
        TextEditingController();
    if (widget.initialValue.notNullOrEmpty) {
      controller.text = widget.initialValue!;
    }
    widget.validateAsyncController?.onError = () {
      if (mounted) setState(() {});
    };
    leadingConfig = InputItemLeadingTailingConfig(
      type: widget.leadingConfig?.type ?? InputItemLeadingTailingType.none,
      show: widget.leadingConfig?.show ?? true,
      icon: widget.leadingConfig?.icon,
      text: widget.leadingConfig?.text,
      widget: widget.leadingConfig?.widget,
      onTap: widget.leadingConfig?.onTap,
    );
    tailingConfig = InputItemLeadingTailingConfig(
      type: widget.tailingConfig?.type ?? InputItemLeadingTailingType.none,
      show: widget.tailingConfig?.show ?? true,
      icon: widget.tailingConfig?.icon,
      text: widget.tailingConfig?.text,
      widget: widget.tailingConfig?.widget,
      onTap: widget.tailingConfig?.onTap,
    );
    style = widget.style ?? InputItemStyle(backgroundColor: Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    Widget? leading = getLeadingTailingByConfig(leadingConfig);
    Widget? tailing = getLeadingTailingByConfig(tailingConfig);
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return Container(
      margin: EdgeInsets.only(
        left: style.horizontalMargin,
        right: style.horizontalMargin,
        top: style.topMargin,
        bottom: style.bottomMargin,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor ?? Colors.transparent,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.vertical(
          top: style.topRadius ? const Radius.circular(10) : Radius.zero,
          bottom: style.bottomRadius ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title.notNullOrEmpty) ...[
            SizedBox(height: style.titleTopMargin),
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: Text(
                widget.title!,
                style: textTheme.bodyMedium?.apply(fontWeightDelta: 2),
              ),
            ),
          ],
          if (widget.description.notNullOrEmpty) ...[
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: Text(
                widget.description!,
                style: textTheme.bodySmall,
              ),
            ),
          ],
          if (widget.title.notNullOrEmpty || widget.description.notNullOrEmpty)
            const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: buildTextField(),
                ),
              ),
              if (tailing != null) ...[
                const SizedBox(width: 12),
                tailing,
              ],
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTextField() {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return TextFormField(
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      readOnly: disabled,
      enabled: !disabled,
      obscureText: style.obscure,
      maxLength: style.maxLength,
      scrollPhysics: const ClampingScrollPhysics(),
      onFieldSubmitted: widget.onSubmit,
      style: textTheme.bodyMedium?.copyWith(
        letterSpacing: 1.1,
        color: disabled ? textTheme.labelSmall?.color : null,
      ),
      maxLines: isPassword || style.obscure ? 1 : style.maxLines,
      minLines: style.minLines,
      inputFormatters: [
        if (style.maxLength != null && style.maxLength! > 0)
          LengthLimitingTextInputFormatter(style.maxLength),
        ...inputFormatters
      ],
      cursorColor: theme.primaryColor,
      cursorRadius: const Radius.circular(5),
      cursorOpacityAnimates: true,
      validator: widget.validator,
      forceErrorText: errorMessage,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: style.fieldBackgroundColor ?? theme.canvasColor,
        contentPadding: style.contentPadding ?? const EdgeInsets.all(12),
        isDense: style.isDense,
        counterStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
        prefixIcon: null,
        errorStyle: textTheme.bodySmall?.apply(color: ChewieTheme.errorColor),
        errorMaxLines: 1,
        border: style.showBorder
            ? OutlineInputBorder(
                borderSide: ChewieTheme.borderSide,
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              )
            : InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primaryColor, width: 0.8),
          borderRadius: BorderRadius.circular(style.radius),
          gapPadding: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: ChewieTheme.borderSide,
          borderRadius: BorderRadius.circular(style.radius),
          gapPadding: 0,
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: ChewieTheme.borderSide,
          borderRadius: BorderRadius.circular(style.radius),
          gapPadding: 0,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ChewieTheme.errorColor, width: 0.8),
          borderRadius: BorderRadius.circular(style.radius),
          gapPadding: 0,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ChewieTheme.errorColor, width: 1),
          borderRadius: BorderRadius.circular(style.radius),
          gapPadding: 0,
        ),
      ),
      contextMenuBuilder: (contextMenuContext, details) =>
          ItemBuilder.editTextContextMenuBuilder(
        contextMenuContext,
        details,
        context: context,
      ),
    );
  }

  Widget? getLeadingTailingByConfig(InputItemLeadingTailingConfig config) {
    Widget? res;
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    switch (config.type) {
      case InputItemLeadingTailingType.none:
        res = null;
        break;
      case InputItemLeadingTailingType.clear:
        res = RoundIconTextButton(
          background: theme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: Icon(
            LucideIcons.x,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () {
            controller.clear();
          },
        );
        break;
      case InputItemLeadingTailingType.copy:
        res = RoundIconTextButton(
          background: theme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: Icon(
            LucideIcons.copy,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () {
            ChewieUtils.copy(context, controller.text);
          },
        );
        break;
      case InputItemLeadingTailingType.openExternal:
        res = RoundIconTextButton(
          background: theme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: Icon(
            LucideIcons.externalLink,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () {
            UriUtil.openExternal(controller.text);
          },
        );
        break;
      case InputItemLeadingTailingType.addSelection:
        res = RoundIconTextButton(
          background: theme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: Icon(
            LucideIcons.plus,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: config.onTap,
        );
        break;
      case InputItemLeadingTailingType.password:
        res = Container(
          margin: const EdgeInsets.only(bottom: 3),
          child: CircleIconButton(
            icon: Icon(style.obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                color: theme.iconTheme.color?.withAlpha(120), size: 16),
            onTap: () {
              style.obscure = !style.obscure;
              setState(() {});
            },
          ),
        );
        break;
      case InputItemLeadingTailingType.icon:
        res = Icon(config.icon!, color: theme.iconTheme.color);
        break;
      case InputItemLeadingTailingType.text:
        res = RoundIconTextButton(
          background: theme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          text: config.text,
          textStyle: textTheme.bodySmall!,
          onPressed: config.onTap,
        );
        break;
      case InputItemLeadingTailingType.widget:
        res = config.widget;
        break;
    }
    return res;
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

  static final urlRegex = RegExp(
    r'^https?://'
    r'(?:'
    r'([a-zA-Z0-9-]+\.)+[a-zA-Z0-9-]+|' // 匹配域名（含国际化域名）
    r'(?:[0-9]{1,3}\.){3}[0-9]{1,3}|' // 匹配 IPv4
    r'\[([a-fA-F0-9:]+)\]' // 匹配 IPv6（需方括号包裹）
    r')'
    r'(?::[0-9]{1,5})?' // 匹配端口（可选）
    r'(?:/[^?#]*)?' // 匹配路径（可选）
    r'(?:\?[^#]*)?' // 匹配查询参数（可选）
    r'(?:#.*)?$', // 匹配锚点（可选）
    caseSensitive: false,
  );
  static RegexInputFormatter onlyUrl = RegexInputFormatter(urlRegex);

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
