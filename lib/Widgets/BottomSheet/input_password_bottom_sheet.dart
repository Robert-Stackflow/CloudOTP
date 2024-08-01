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
  TextEditingController _controller = TextEditingController();
  TextEditingController _confirmController = TextEditingController();
  late InputStateController _stateController;
  late InputStateController _confirmStateController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _stateController = InputStateController(
        validate: (value) {
          if (value.isEmpty) {
            return Future.value(S.current.encryptDatabasePasswordCannotBeEmpty);
          }
          return Future.value(null);
        });
    _confirmStateController = InputStateController(
        validate: (value) {
          if (value != _controller.text) {
            return Future.value(S.current.encryptDatabasePasswordNotMatch);
          }
          return Future.value(null);
        });
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
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.next,
                    tailingType: InputItemTailingType.password,
                    stateController: _stateController,
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
                    stateController: _confirmStateController,
                    inputFormatters: [
                      RegexInputFormatter.onlyNumberAndLetter,
                    ],
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
                  String? error1 = await _stateController.doValidate();
                  String? error2 = await _confirmStateController.doValidate();
                  widget.onConfirm
                      ?.call(_controller.text, _confirmController.text);
                  if (error1 == null && error2 == null) {
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
