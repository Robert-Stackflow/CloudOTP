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

import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n.dart';

class StarBottomSheet extends StatefulWidget {
  const StarBottomSheet({
    super.key,
  });

  @override
  StarBottomSheetState createState() => StarBottomSheetState();
}

class StarBottomSheetState extends State<StarBottomSheet> {
  int currentStar = 0;
  String currentComment = S.current.pleaseRate;

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
                bottom: ResponsiveUtil.isWideLandscape()
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
        S.current.rateTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  updateComment() {
    switch (currentStar) {
      case 1:
        currentComment = S.current.rate1Star;
        break;
      case 2:
        currentComment = S.current.rate2Star;
        break;
      case 3:
        currentComment = S.current.rate3Star;
        break;
      case 4:
        currentComment = S.current.rate4Star;
        break;
      case 5:
        currentComment = S.current.rate5Star;
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
                text: S.current.rateLater,
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
                text: S.current.submitRate,
                onTap: () {
                  if (currentStar != 0) {
                    IToast.showTop(S.current.rateSuccess);
                    Navigator.of(context).pop();
                  } else {
                    IToast.showTop(S.current.pleaseClickToRate);
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
