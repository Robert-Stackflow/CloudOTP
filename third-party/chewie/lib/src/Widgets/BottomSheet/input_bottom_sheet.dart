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

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Widgets/Item/Tile/input_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';

class InputBottomSheet extends StatefulWidget {
  const InputBottomSheet({
    super.key,
    this.hint,
    this.onConfirm,
    this.onValidConfirm,
    this.message = "",
    this.text = "",
    this.onCancel,
    this.title = "",
    this.textInputAction,
    this.keyboardType,
    this.focusNode,
    this.inputFormatters = const [],
    this.preventPop = false,
    this.validator,
    this.validateAsyncController,
    this.checkSyncValidator = true,
    this.leadingConfig,
    this.tailingConfig,
    this.style,
  });

  final String? hint;
  final String text;
  final String title;
  final String message;
  final bool checkSyncValidator;
  final InputValidateAsyncController? validateAsyncController;
  final FormFieldValidator? validator;
  final Function()? onCancel;
  final Function(String)? onConfirm;
  final Function(String)? onValidConfirm;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final List<TextInputFormatter> inputFormatters;
  final bool preventPop;

  final InputItemLeadingTailingConfig? leadingConfig;
  final InputItemLeadingTailingConfig? tailingConfig;
  final InputItemStyle? style;

  @override
  InputBottomSheetState createState() => InputBottomSheetState();
}

class InputBottomSheetState extends State<InputBottomSheet> {
  late TextEditingController controller;
  final FocusNode _focusNode = FocusNode();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller =
        widget.validateAsyncController?.controller ?? TextEditingController();
    if (mounted) controller.value = TextEditingValue(text: widget.text);
    widget.validateAsyncController?.doPop = () {
      Navigator.of(context).pop();
    };
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Radius radius = ChewieDimens.radius16;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      child: Wrap(
        runAlignment: WrapAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  top: radius,
                  bottom: ResponsiveUtil.isWideDevice() ? radius : Radius.zero),
              color: ChewieTheme.scaffoldBackgroundColor,
              border: ChewieTheme.border,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.title.notNullOrEmpty ||
                    widget.message.notNullOrEmpty)
                  _buildHeader(),
                const SizedBox(height: 20),
                Center(
                  child: Form(
                    key: formKey,
                    child: InputItem(
                      controller: controller,
                      focusNode: _focusNode,
                      hint: widget.hint,
                      leadingConfig: widget.leadingConfig,
                      tailingConfig: widget.tailingConfig,
                      style: widget.style,
                      validator: widget.validator,
                      validateAsyncController: widget.validateAsyncController,
                      textInputAction: widget.textInputAction,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      onSubmit: (_) => processConfirm(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildHeader() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          if (widget.title.notNullOrEmpty)
            Text(
              widget.title,
              style: ChewieTheme.titleLarge,
            ),
          if (widget.message.notNullOrEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: ChewieTheme.bodyMedium.apply(
                color: ChewieTheme.bodySmall.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  processConfirm() async {
    bool isValid = widget.checkSyncValidator
        ? formKey.currentState?.validate() ?? false
        : true;
    bool isValidAsync = await widget.validateAsyncController?.isValid() ?? true;
    widget.onConfirm?.call(controller.text);
    if (isValid && isValidAsync) {
      if (!widget.preventPop) {
        Navigator.of(context).pop();
      }
      await widget.onValidConfirm?.call(controller.text);
    } else {
      _focusNode.requestFocus();
    }
  }

  _buildFooter() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: RoundIconTextButton(
              text: chewieLocalizations.cancel,
              height: 48,
              onPressed: () {
                widget.onCancel?.call();
                Navigator.of(context).pop();
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: RoundIconTextButton(
              height: 48,
              background: ChewieTheme.primaryColor,
              color: ChewieTheme.primaryButtonColor,
              text: chewieLocalizations.confirm,
              onPressed: processConfirm,
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
    );
  }
}
