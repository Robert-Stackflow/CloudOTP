/*
 * Copyright (c) 2024-2025 Robert-Stackflow.
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

import 'dart:math';
import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../l10n/l10n.dart';

class QrcodesDialogWidget extends StatefulWidget {
  final List<String> qrcodes;
  final String? title;
  final String? message;
  final Alignment align;
  final String? asset;

  const QrcodesDialogWidget({
    super.key,
    required this.qrcodes,
    this.title,
    this.message,
    this.align = Alignment.bottomCenter,
    this.asset,
  });

  @override
  QrcodesDialogWidgetState createState() => QrcodesDialogWidgetState();
}

class QrcodesDialogWidgetState extends BaseDynamicState<QrcodesDialogWidget> {
  PageController controller = PageController();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        currentPage = controller.page!.toInt();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxHeight = min(360, MediaQuery.sizeOf(context).width - 90);
    return BackdropFilter(
      filter: ResponsiveUtil.isDesktop()
          ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Align(
        alignment: widget.align,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: ResponsiveUtil.isWideLandscape()
                ? const BoxConstraints(maxWidth: 430)
                : null,
            margin: ResponsiveUtil.isWideLandscape()
                ? const EdgeInsets.all(24)
                : EdgeInsets.zero,
            decoration: ChewieTheme.defaultDecoration.copyWith(
              color: ChewieTheme.scaffoldBackgroundColor,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              shrinkWrap: true,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title ?? "",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.apply(fontSizeDelta: 1),
                          textAlign: TextAlign.center,
                        ),
                      if (widget.title.notNullOrEmpty)
                        const SizedBox(height: 20),
                      if (widget.message != null)
                        Text(
                          widget.message ?? "",
                          style: ChewieTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      if (widget.message.notNullOrEmpty)
                        const SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(
                  height: maxHeight,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: widget.qrcodes.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: ColorUtil.isDark(context)
                              ? Colors.white
                              : ChewieTheme.canvasColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtil.isWideLandscape()
                                ? 30
                                : (MediaQuery.sizeOf(context).width -
                                        maxHeight) /
                                    2),
                        padding: const EdgeInsets.all(20),
                        child: PrettyQrView.data(
                          data: widget.qrcodes[index],
                          errorCorrectLevel: QrErrorCorrectLevel.M,
                          errorBuilder: (context, error, stacktrace) {
                            return Text(
                              appLocalizations.errorQrCode + error.toString(),
                              textAlign: TextAlign.center,
                            );
                          },
                          decoration: PrettyQrDecoration(
                            // shape: PrettyQrSmoothSymbol(
                            // roundFactor: 1,
                            // color: PrettyQrBrush.gradient(
                            //   gradient: LinearGradient(
                            //     begin: Alignment.topCenter,
                            //     end: Alignment.bottomCenter,
                            //     colors: [
                            //       ChewieTheme.primaryColor,
                            //       Colors.blue[200]!,
                            //       Colors.teal[200]!,
                            //       Colors.red[200]!,
                            //     ],
                            //   ),
                            // ),
                            // ),
                            image:
                                widget.asset != null && widget.asset!.isNotEmpty
                                    ? PrettyQrDecorationImage(
                                        scale: 0.15,
                                        isAntiAlias: true,
                                        padding: const EdgeInsets.all(20),
                                        filterQuality: FilterQuality.high,
                                        image: AssetImage(widget.asset!),
                                      )
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: widget.qrcodes.length == 1
                      ? RoundIconTextButton(
                          text: appLocalizations.confirm,
                          fontSizeDelta: 2,
                          background: ChewieTheme.primaryColor,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      : Row(
                          children: [
                            RoundIconTextButton(
                              fontSizeDelta: 2,
                              disabled: currentPage <= 0,
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: currentPage <= 0 ? Colors.grey : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 31, vertical: 8),
                              onPressed: currentPage <= 0
                                  ? null
                                  : () {
                                      controller.previousPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                            ),
                            Expanded(
                              child: Text(
                                "${currentPage + 1}/${widget.qrcodes.length}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            currentPage == widget.qrcodes.length - 1
                                ? RoundIconTextButton(
                                    text: appLocalizations.complete,
                                    background: ChewieTheme.primaryColor,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                : RoundIconTextButton(
                                    icon:
                                        const Icon(Icons.arrow_forward_rounded),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 31, vertical: 8),
                                    onPressed: () {
                                      controller.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
