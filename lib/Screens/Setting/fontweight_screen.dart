import 'package:flutter/material.dart';

import '../../Resources/fonts.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class FontWeightScreen extends StatefulWidget {
  const FontWeightScreen({super.key});

  static const String routeName = "/setting/fontWeight";

  @override
  State<FontWeightScreen> createState() => _FontWeightScreenState();
}

class _FontWeightScreenState extends State<FontWeightScreen>
    with TickerProviderStateMixin {
  FontEnum _currentFont = FontEnum.getCurrentFont();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
            title: "查看字重", context: context, transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "选择字体",
                topRadius: true,
                bottomRadius: true,
                tip: _currentFont.fontName,
                onTap: () {
                  BottomSheetBuilder.showListBottomSheet(
                    context,
                    (sheetContext) => TileList.fromOptions(
                      FontEnum.getFontList(),
                      (item2) async {
                        FontEnum t = item2 as FontEnum;
                        _currentFont = t;
                        Navigator.pop(sheetContext);
                        setState(() {});
                        FontEnum.loadFont(context, t);
                      },
                      selected: _currentFont,
                      context: context,
                      title: "选择字体",
                      onCloseTap: () => Navigator.pop(context),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ...FontWeight.values.map(
                (weight) => FittedBox(
                  child: Text(
                    '你好世界 hello world',
                    style: TextStyle(
                      fontFamily: _currentFont.fontFamily,
                      fontWeight: weight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
