import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n.dart';

class TokenOptionBottomSheet extends StatefulWidget {
  const TokenOptionBottomSheet({
    super.key,
    this.onCopyTokenCode,
    this.onCopyNextTokenCode,
    this.onViewTokenQrCode,
    this.onCopyTokenUri,
    this.onEditToken,
    this.onEditTokenCategory,
    this.onEditTokenIcon,
    this.onPinOrUnPinToken,
    this.onDeleteToken,
    required this.isPinned,
    this.nextCode,
  });

  final Function()? onCopyTokenCode;
  final Function()? onCopyNextTokenCode;
  final Function()? onViewTokenQrCode;
  final Function()? onCopyTokenUri;
  final Function()? onEditToken;
  final Function()? onEditTokenCategory;
  final Function()? onEditTokenIcon;
  final Function()? onPinOrUnPinToken;
  final Function()? onDeleteToken;
  final bool isPinned;
  final String? nextCode;

  @override
  TokenOptionBottomSheetState createState() => TokenOptionBottomSheetState();
}

class TokenOptionBottomSheetState extends State<TokenOptionBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
          ),
          child: _buildPrimaryButtons(),
        ),
      ],
    );
  }

  _buildPrimaryButtons() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      children: [
        ItemBuilder.buildEntryItem(
          context: context,
          radius: 20,
          showLeading: true,
          topRadius: true,
          showTrailing: false,
          leading: Icons.copy_rounded,
          title: S.current.copyTokenCode,
          onTap: () {
            Navigator.pop(context);
            widget.onCopyTokenCode?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.content_copy_rounded,
          title: S.current.copyNextTokenCode,
          onTap: () {
            Navigator.pop(context);
            widget.onCopyNextTokenCode?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.qr_code_rounded,
          title: S.current.viewTokenQrCode,
          onTap: () {
            Navigator.pop(context);
            widget.onViewTokenQrCode?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.text_fields_rounded,
          title: S.current.copyTokenUri,
          onTap: () {
            Navigator.pop(context);
            widget.onCopyTokenUri?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: widget.isPinned
              ? Icons.push_pin_rounded
              : Icons.push_pin_outlined,
          title: widget.isPinned ? S.current.unPinToken : S.current.pinToken,
          titleColor: widget.isPinned ? Colors.green : null,
          leadingColor: widget.isPinned ? Colors.green : null,
          onTap: () {
            Navigator.pop(context);
            widget.onPinOrUnPinToken?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.edit_rounded,
          title: S.current.editToken,
          onTap: () {
            Navigator.pop(context);
            widget.onEditToken?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.category_outlined,
          title: S.current.editTokenCategory,
          onTap: () {
            Navigator.pop(context);
            widget.onEditTokenCategory?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          leading: Icons.image_search_rounded,
          title: S.current.editTokenIcon,
          onTap: () {
            Navigator.pop(context);
            widget.onEditTokenIcon?.call();
          },
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          showLeading: true,
          showTrailing: false,
          bottomRadius: true,
          leading: Icons.delete_outline_rounded,
          title: S.current.deleteToken,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            widget.onDeleteToken?.call();
          },
        ),
      ],
    );
  }
}
