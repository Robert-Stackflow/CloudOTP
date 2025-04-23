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

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/Tile/input_item.dart';

class EditAIModelBottomSheet extends StatefulWidget {
  const EditAIModelBottomSheet({
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
  EditAIModelBottomSheetState createState() => EditAIModelBottomSheetState();
}

class EditAIModelBottomSheetState extends State<EditAIModelBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Radius radius = ChewieDimens.radius8;

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
                      title: "模型名称",
                      hint: "请输入模型名称",
                      description: "模型显示的名称",
                      textInputAction: TextInputAction.next,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.clear,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "模型名称不能为空";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                    child: InputItem(
                      controller: _confirmController,
                      focusNode: _confirmFocusNode,
                      title: "模型ID",
                      hint: "请输入模型ID",
                      description: "发送请求时的model参数",
                      textInputAction: TextInputAction.next,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.clear,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "模型ID不能为空";
                        }
                        return null;
                      },
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
              style: ChewieTheme.titleLarge,
            ),
          if (widget.message.notNullOrEmpty) const SizedBox(height: 8),
          if (widget.message.notNullOrEmpty)
            Text(
              widget.message,
              style: ChewieTheme.bodyMedium.apply(
                color: ChewieTheme.bodySmall.color,
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
                text: ChewieS.current.cancel,
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
                color: ChewieTheme.primaryButtonColor,
                text: ChewieS.current.confirm,
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
