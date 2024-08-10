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
    this.controller,
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
    this.preventPop = false,
  });

  final String? hint;
  final String text;
  final String title;
  final String message;
  final int maxLines;
  final int minLines;
  final Function()? onCancel;
  final Function(String)? onConfirm;
  final Function(String)? onValidConfirm;
  final TextEditingController? controller;

  final TextInputAction? textInputAction;
  final IconData? leadingIcon;
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
  late InputStateController stateController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    controller.value = TextEditingValue(text: widget.text);
    stateController = widget.stateController ??
        InputStateController(validate: (_) => Future.value(null));
    stateController.pop = () {
      Navigator.of(context).pop();
    };
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: ResponsiveUtil.isLandscape()
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
                  child: InputItem(
                    controller: controller,
                    stateController: stateController,
                    focusNode: _focusNode,
                    hint: widget.hint,
                    maxLines: widget.tailingType ==
                                InputItemTailingType.password ||
                            (widget.obscureText != null && widget.obscureText!)
                        ? 1
                        : widget.maxLines,
                    minLines: widget.minLines,
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
                    readOnly: widget.readOnly,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    leadingMinWidth: widget.leadingMinWidth,
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
                onTap: () async {
                  String? error = await stateController.doValidate();
                  widget.onConfirm?.call(controller.text);
                  if (error == null) {
                    widget.onValidConfirm?.call(controller.text);
                    if (!widget.preventPop) Navigator.of(context).pop();
                  }
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
