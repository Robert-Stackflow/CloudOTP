import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';

class StarBottomSheet extends StatefulWidget {
  const StarBottomSheet({
    super.key,
  });

  @override
  StarBottomSheetState createState() => StarBottomSheetState();
}

class StarBottomSheetState extends State<StarBottomSheet> {
  int currentStar = 0;
  String currentComment = "请评分";

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
              _buildStars(),
              ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        "为CloudOTP评个分吧",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  updateComment() {
    switch (currentStar) {
      case 1:
        currentComment = "革命仍需努力";
        break;
      case 2:
        currentComment = "还请你多反馈和建议";
        break;
      case 3:
        currentComment = "我会继续进步的！";
        break;
      case 4:
        currentComment = "收下你的认可啦";
        break;
      case 5:
        currentComment = "啾咪~~";
        break;
    }
  }

  _buildStars() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 24, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentComment,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) {
                return ItemBuilder.buildClickItem(
                  GestureDetector(
                    child: Icon(
                      index < currentStar
                          ? Icons.star_rate_rounded
                          : Icons.star_border_purple500_rounded,
                      color: Colors.yellow,
                      size: 40,
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        currentStar = index + 1;
                        updateComment();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ItemBuilder.buildRoundButton(
                context,
                text: "暂不评分",
                onTap: () {
                  Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                text: " 确定 ",
                onTap: () {
                  if (currentStar != 0) {
                    IToast.showTop("感谢您的评分");
                    Navigator.of(context).pop();
                  } else {
                    IToast.showTop("请点击评分");
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
