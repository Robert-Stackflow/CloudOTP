import 'dart:math';

import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../Utils/utils.dart';
import '../../../generated/l10n.dart';

class QrcodesDialogWidget extends StatefulWidget {
  final List<String> qrcodes;
  final String? title;
  final String? message;
  final Alignment align;

  const QrcodesDialogWidget({
    super.key,
    required this.qrcodes,
    this.title,
    this.message,
    this.align = Alignment.bottomCenter,
  });

  @override
  QrcodesDialogWidgetState createState() => QrcodesDialogWidgetState();
}

class QrcodesDialogWidgetState extends State<QrcodesDialogWidget> {
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
    return Align(
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
          decoration: BoxDecoration(
            color: MyTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(15),
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
                    if (Utils.isNotEmpty(widget.title))
                      const SizedBox(height: 20),
                    if (widget.message != null)
                      Text(
                        widget.message ?? "",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    if (Utils.isNotEmpty(widget.message))
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      margin: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtil.isWideLandscape()
                              ? 30
                              : (MediaQuery.sizeOf(context).width - maxHeight) /
                                  2),
                      padding: const EdgeInsets.all(20),
                      child: PrettyQrView.data(
                        data: widget.qrcodes[index],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: widget.qrcodes.length == 1
                    ? ItemBuilder.buildRoundButton(context,
                        text: S.current.confirm,
                        fontSizeDelta: 2,
                        background: Theme.of(context).primaryColor, onTap: () {
                        Navigator.of(context).pop();
                      })
                    : Row(
                        children: [
                          ItemBuilder.buildRoundButton(
                            context,
                            fontSizeDelta: 2,
                            icon: const Icon(Icons.arrow_back_rounded),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 31, vertical: 8),
                            onTap: currentPage <= 0
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
                              ? ItemBuilder.buildRoundButton(
                                  context,
                                  text: S.current.complete,
                                  background: Theme.of(context).primaryColor,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              : ItemBuilder.buildRoundButton(
                                  context,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 31, vertical: 8),
                                  onTap: () {
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
    );
  }
}
