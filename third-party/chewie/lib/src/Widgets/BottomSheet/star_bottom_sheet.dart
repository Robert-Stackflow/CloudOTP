import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_gesture_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/my_divider.dart';

class StarBottomSheet extends StatefulWidget {
  const StarBottomSheet({
    super.key,
  });

  @override
  StarBottomSheetState createState() => StarBottomSheetState();
}

class StarBottomSheetState extends State<StarBottomSheet> {
  int currentStar = 0;
  String currentComment = ChewieS.current.pleaseRate;

  @override
  void initState() {
    super.initState();
  }

  Radius radius = ChewieDimens.radius16;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ChewieTheme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
                top: radius,
                bottom:
                    ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
            border: ChewieTheme.border,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const MyDivider(horizontal: 12, vertical: 0),
              _buildStars(),
              const MyDivider(horizontal: 12, vertical: 0),
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
        ChewieS.current.scoreDialogTitle(ResponsiveUtil.appName),
        style: ChewieTheme.titleLarge,
      ),
    );
  }

  updateComment() {
    switch (currentStar) {
      case 1:
        currentComment = ChewieS.current.rate1Star;
        break;
      case 2:
        currentComment = ChewieS.current.rate2Star;
        break;
      case 3:
        currentComment = ChewieS.current.rate3Star;
        break;
      case 4:
        currentComment = ChewieS.current.rate4Star;
        break;
      case 5:
        currentComment = ChewieS.current.rate5Star;
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
            style: ChewieTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) {
                return ClickableGestureDetector(
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
            child: RoundIconTextButton(
              text: ChewieS.current.rateLater,
              onPressed: () {
                Navigator.of(context).pop();
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: RoundIconTextButton(
              background: ChewieTheme.primaryColor,
              text: " ${ChewieS.current.confirm} ",
              onPressed: () {
                if (currentStar != 0) {
                  IToast.showTop(ChewieS.current.rateSuccess);
                  Navigator.of(context).pop();
                } else {
                  IToast.showTop(ChewieS.current.pleaseClickToRate);
                }
              },
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
    );
  }
}
