import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../TokenUtils/token_image_util.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../generated/l10n.dart';

class SelectIconBottomSheet extends StatefulWidget {
  const SelectIconBottomSheet({
    super.key,
    required this.token,
    required this.onSelected,
    this.doUpdate = false,
  });

  final OtpToken token;
  final bool doUpdate;
  final Function(String) onSelected;

  @override
  SelectIconBottomSheetState createState() => SelectIconBottomSheetState();
}

class SelectIconBottomSheetState extends State<SelectIconBottomSheet> {
  GroupButtonController controller = GroupButtonController();
  TextEditingController searchController = TextEditingController();
  List<String> icons = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        searchController.text = widget.token.issuer;
        icons = TokenImageUtil.matchBrandLogos(searchController.text);
      });
      searchController.addListener(() {
        setState(() {
          icons = TokenImageUtil.matchBrandLogos(searchController.text);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.vertical(
            top: const Radius.circular(20),
            bottom: ResponsiveUtil.isLandscape()
                ? const Radius.circular(20)
                : Radius.zero),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(),
          ItemBuilder.buildDesktopSearchBar(
            controller: searchController,
            context: context,
            borderRadius: 8,
            bottomMargin: 18,
            hintFontSizeDelta: 1,
            background: Colors.grey.withAlpha(40),
            hintText: S.current.searchIconName,
            onSubmitted: (str) {
              setState(() {
                icons = TokenImageUtil.matchBrandLogos(str);
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildButtons(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  _buildButtons() {
    return WaterfallFlow.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 10),
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => ItemBuilder.buildRoundButton(
        context,
        radius: 8,
        align: true,
        icon: AssetUtil.loadBrand(icons[index], width: 16, height: 16),
        text: icons[index].split(".")[0],
        onTap: () async {
          widget.token.imagePath = icons[index];
          widget.onSelected.call(widget.token.imagePath);
          if (widget.doUpdate) {
            await TokenDao.updateToken(widget.token);
            homeScreenState?.refresh();
          }
          Navigator.of(context).pop();
        },
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        textStyle:
            Theme.of(context).textTheme.titleSmall?.apply(fontSizeDelta: 1),
      ),
      itemCount: icons.length,
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      alignment: Alignment.center,
      child: Text(
        textAlign: TextAlign.center,
        widget.token.issuer.isNotEmpty
            ? S.current.setIconForToken
            : S.current.setIconForTokenDetail(widget.token.issuer),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
