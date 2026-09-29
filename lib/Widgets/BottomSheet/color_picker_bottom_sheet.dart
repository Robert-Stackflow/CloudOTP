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
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/l10n.dart';

class ColorPickerBottomSheet extends StatefulWidget {
  final Color initialColor;
  final String title;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerBottomSheet({
    super.key,
    required this.initialColor,
    required this.title,
    required this.onColorChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Color initialColor,
    required String title,
    required ValueChanged<Color> onColorChanged,
  }) {
    return BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => ColorPickerBottomSheet(
        initialColor: initialColor,
        title: title,
        onColorChanged: onColorChanged,
      ),
    );
  }

  @override
  State<ColorPickerBottomSheet> createState() => _ColorPickerBottomSheetState();
}

class _ColorPickerBottomSheetState extends State<ColorPickerBottomSheet> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
              top: radius,
              bottom: ResponsiveUtil.isWideDevice() ? radius : Radius.zero),
          color: ChewieTheme.scaffoldBackgroundColor,
          border: ChewieTheme.responsiveBorder,
          boxShadow: ChewieTheme.defaultBoxShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(widget.title, style: ChewieTheme.titleLarge),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: ColorPicker(
                    color: _currentColor,
                    onColorChanged: (Color color) {
                      setState(() => _currentColor = color);
                    },
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.wheel: true,
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false,
                    },
                    enableShadesSelection: true,
                    enableOpacity: true,
                    showColorCode: true,
                    colorCodeHasColor: true,
                    copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                      copyFormat: ColorPickerCopyFormat.hexRRGGBB,
                      copyIcon: LucideIcons.copy,
                      pasteButton: true,
                      pasteIcon: LucideIcons.clipboardPaste,
                    ),
                    actionButtons: const ColorPickerActionButtons(
                      okButton: false,
                      closeButton: false,
                      dialogActionButtons: false,
                    ),
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    heading: null,
                    subheading: null,
                    wheelWidth: 20,
                    wheelDiameter: 220,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: RoundIconTextButton(
                          text: appLocalizations.cancel,
                          onPressed: () => Navigator.of(context).pop(),
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
                          text: appLocalizations.confirm,
                          onPressed: () {
                            widget.onColorChanged(_currentColor);
                            Navigator.of(context).pop();
                          },
                          fontSizeDelta: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
