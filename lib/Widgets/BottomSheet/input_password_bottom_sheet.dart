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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

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

  Radius radius = ChewieDimens.defaultRadius;

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
                  top: radius,
                  bottom:
                      ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
              color: ChewieTheme.scaffoldBackgroundColor,
              border: ChewieTheme.border,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.title.notNullOrEmpty ||
                      widget.message.notNullOrEmpty)
                    _buildHeader(),
                  const SizedBox(height: 8.0),
                  Center(
                    child: InputItem(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.next,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.password,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return S.current.encryptDatabasePasswordCannotBeEmpty;
                        }
                        return null;
                      },
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetterAndSymbol,
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                    child: InputItem(
                      controller: _confirmController,
                      textInputAction: TextInputAction.done,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.password,
                      ),
                      validator: (value) {
                        if (value != _controller.text) {
                          return S.current.encryptDatabasePasswordNotMatch;
                        }
                        return null;
                      },
                      inputFormatters: [
                        RegexInputFormatter.onlyNumberAndLetterAndSymbol,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (widget.title.notNullOrEmpty)
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (widget.message.notNullOrEmpty) const SizedBox(height: 8),
          if (widget.message.notNullOrEmpty)
            Text(
              widget.message,
              style: ChewieTheme.bodyMedium.apply(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
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
              child: RoundIconTextButton(
                text: S.current.cancel,
                onPressed: () {
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
              child: RoundIconTextButton(
                background: ChewieTheme.primaryColor,
                color: Colors.white,
                text: S.current.confirm,
                onPressed: () async {
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
