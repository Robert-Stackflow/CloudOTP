import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Item/item_builder.dart';

class InputBottomSheet extends StatefulWidget {
  const InputBottomSheet({
    super.key,
    this.maxLines = 5,
    this.minLines = 1,
    this.hint,
    this.onConfirm,
    this.onValidConfirm,
    this.message = "",
    this.text = "",
    this.onCancel,
    this.title = "",
    this.textInputAction,
    this.leadingIcon,
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
    this.readOnly,
    this.maxLength,
    this.inputFormatters = const [],
    this.leadingMinWidth,
    this.preventPop = false,
    this.validator,
    this.validateAsyncController,
    this.checkSyncValidator = true,
  });

  final String? hint;
  final String text;
  final String title;
  final String message;
  final int maxLines;
  final int minLines;
  final bool checkSyncValidator;
  final InputValidateAsyncController? validateAsyncController;
  final FormFieldValidator? validator;
  final Function()? onCancel;
  final Function(String)? onConfirm;
  final Function(String)? onValidConfirm;
  final TextInputAction? textInputAction;
  final IconData? leadingIcon;
  final bool? obscureText;
  final InputItemTailingType tailingType;
  final InputItemLeadingType leadingType;
  final String? tailingText;
  final bool? showTailing;
  final IconData? tailingIcon;
  final Function()? onTailingTap;
  final Widget? tailingWidget;
  final Widget? leadingWidget;
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
  final bool preventPop;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      child: Wrap(
        runAlignment: WrapAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: ResponsiveUtil.isWideLandscape()
                      ? const Radius.circular(20)
                      : Radius.zero),
              color: Theme.of(context).canvasColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (Utils.isNotEmpty(widget.title) ||
                    Utils.isNotEmpty(widget.message))
                  _buildHeader(),
                const SizedBox(height: 8.0),
                Center(
                  child: Form(
                    key: formKey,
                    child: InputItem(
                      controller: controller,
                      focusNode: _focusNode,
                      hint: widget.hint,
                      maxLines:
                          widget.tailingType == InputItemTailingType.password ||
                                  (widget.obscureText != null &&
                                      widget.obscureText!)
                              ? 1
                              : widget.maxLines,
                      minLines: widget.minLines,
                      validator: widget.validator,
                      validateAsyncController: widget.validateAsyncController,
                      textInputAction: widget.textInputAction,
                      leadingIcon: widget.leadingIcon,
                      obscureText: widget.obscureText,
                      tailingType: widget.tailingType,
                      leadingType: widget.leadingType,
                      tailingText: widget.tailingText,
                      showTailing: widget.showTailing,
                      tailingIcon: widget.tailingIcon,
                      onTailingTap: widget.onTailingTap,
                      tailingWidget: widget.tailingWidget,
                      leadingWidget: widget.leadingWidget,
                      leadingText: widget.leadingText,
                      backgroundColor: widget.backgroundColor,
                      keyboardType: widget.keyboardType,
                      topRadius: widget.topRadius,
                      bottomRadius: widget.bottomRadius,
                      disabled: widget.readOnly,
                      maxLength: widget.maxLength,
                      inputFormatters: widget.inputFormatters,
                      leadingMinWidth: widget.leadingMinWidth,
                      onSubmit: (_) => processConfirm(),
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (Utils.isNotEmpty(widget.title))
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (Utils.isNotEmpty(widget.message)) const SizedBox(height: 8),
          if (Utils.isNotEmpty(widget.message))
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
      await widget.onValidConfirm?.call(controller.text);
      if (!widget.preventPop) {
        Navigator.of(context).pop();
      }
    } else {
      _focusNode.requestFocus();
    }
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: ItemBuilder.buildRoundButton(
                context,
                text: S.current.cancel,
                onTap: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 45,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                color: Colors.white,
                text: S.current.confirm,
                onTap: processConfirm,
                fontSizeDelta: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
