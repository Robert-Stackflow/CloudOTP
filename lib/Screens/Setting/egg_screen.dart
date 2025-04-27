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
import 'package:flutter/material.dart';

import '../../Utils/lottie_util.dart';
import '../../generated/l10n.dart';

class EggScreen extends StatefulWidget {
  const EggScreen({super.key});

  static const String routeName = "/setting/egg";

  @override
  State<EggScreen> createState() => _EggScreenState();
}

class _EggScreenState extends State<EggScreen> with TickerProviderStateMixin {
  Widget? celebrateWidget;
  bool _showCelebrate = false;
  late AnimationController _celebrateController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _celebrateController = AnimationController(
          duration: const Duration(seconds: 5), vsync: this);
      celebrateWidget = LottieFiles.load(
        LottieFiles.celebrate,
        size: 40,
        controller: _celebrateController,
      );
      diaplayCelebrate();
    });
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    super.dispose();
  }

  diaplayCelebrate() {
    if (_showCelebrate) return;
    _showCelebrate = true;
    _celebrateController.forward(from: 0);
    _celebrateController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showCelebrate = false;
        setState(() {});
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: ResponsiveUtil.isLandscape()
              ? null
              : const ResponsiveAppBar(
                  showBorder: true,
                  showBack: true,
                ),
          body: EasyRefresh(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: [
                if (ResponsiveUtil.isLandscape())
                  const SizedBox(height: kToolbarHeight),
                Center(
                  child: ClickableGestureDetector(
                    onTap: diaplayCelebrate,
                    child: Hero(
                      tag: "logo-egg",
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ContainerItem(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: CustomHtmlWidget(
                      content: S.current.eggEssay,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _showCelebrate,
          child: Positioned(
            left: 0,
            right: 0,
            top: ResponsiveUtil.isLandscape() ? 500 : 380,
            child: IgnorePointer(
              child: Transform.scale(
                scale: ResponsiveUtil.isLandscape()
                    ? MediaQuery.of(context).size.width / 40
                    : MediaQuery.of(context).size.width * 2 / 40,
                child: Center(
                  child: celebrateWidget,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
