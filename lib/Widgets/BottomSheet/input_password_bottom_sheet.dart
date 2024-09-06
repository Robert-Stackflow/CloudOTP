import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:flutter/material.dart';

import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Item/item_builder.dart';

class InputPasswordBottomSheet extends StatefulWidget {
  const InputPasswordBottomSheet({
    super.key,
    this.onConfirm,
    this.onValidConfirm,
    this.message = "",
    this.onCancel,
    this.title = "",
  });

  final String title;
  final String message;
  final Function()? onCancel;
  final Function(String, String)? onConfirm;
  final Function(String, String)? onValidConfirm;

  @override
  InputPasswordBottomSheetState createState() =>
      InputPasswordBottomSheetState();
}

class InputPasswordBottomSheetState extends State<InputPasswordBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: ResponsiveUtil.isWideLandscape()
                      ? const Radius.circular(20)
                      : Radius.zero),
              color: Theme.of(context).canvasColor,
            ),
            child: Form(
              key: formKey,
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
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.next,
                      tailingType: InputItemTailingType.password,
                      validator: (value) {
                        if (value.isEmpty) {
                          return S.current.encryptDatabasePasswordCannotBeEmpty;
                        }
                        return null;
                      },
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetter,
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                    child: InputItem(
                      controller: _confirmController,
                      textInputAction: TextInputAction.done,
                      tailingType: InputItemTailingType.password,
                      validator: (value) {
                        if (value != _controller.text) {
                          return S.current.encryptDatabasePasswordNotMatch;
                        }
                        return null;
                      },
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetter,
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
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
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 45,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                color: Colors.white,
                text: S.current.confirm,
                onTap: () async {
                  bool isValid = formKey.currentState?.validate() ?? false;
                  widget.onConfirm
                      ?.call(_controller.text, _confirmController.text);
                  if (isValid) {
                    widget.onValidConfirm
                        ?.call(_controller.text, _confirmController.text);
                    Navigator.of(context).pop();
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
