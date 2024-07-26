import 'package:flutter/material.dart';

import '../../Utils/lottie_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

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
      celebrateWidget = LottieUtil.load(
        LottieUtil.celebrate,
        size: MediaQuery.sizeOf(context).width * 2,
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
          appBar: ResponsiveUtil.isDesktop()
              ? null
              : ItemBuilder.buildSimpleAppBar(
                  transparent: true,
                  leading: Icons.close_rounded,
                  context: context,
                ),
          body: EasyRefresh(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ItemBuilder.buildClickItem(
                    GestureDetector(
                      onTap: diaplayCelebrate,
                      child: Hero(
                        tag: "logo-egg",
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1),
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
                ),
                const SizedBox(height: 30),
                ItemBuilder.buildContainerItem(
                  backgroundColor: Theme.of(context).canvasColor,
                  bottomRadius: true,
                  topRadius: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: ItemBuilder.buildHtmlWidget(
                      context,
                      "&emsp;&emsp;恭喜你发现了我藏在CloudOTP中的<strong>小彩蛋</strong>！<br/>&emsp;&emsp;相信发现这个彩蛋的你已经很熟悉CloudOTP了，那么我先做个自我介绍吧。我呢，是一个喜欢用开发来方便自己的人，并经常乐此不疲地投入时间和精力去打磨自己的作品。由于实在无法忍受Lofter中烦人的广告，我在机缘巧合下重新拾起了Flutter开发CloudOTP，并适配了平板设备和Windows系统。<br/>&emsp;&emsp;在CloudOTP之前，我用原生安卓开发过一个完整的小项目CloudOTP，这款简洁的双因素身份验证器受到我室友的青睐，甚至他的同事还询问有没有IOS版本的，这是我第一次体会到自己的作品被他人认可的那种奇妙的感觉。兴许以后闲暇的时候，我也会用Flutter重构CloudOTP，将自己的作品呈现给更多喜欢它的人们。<br/>&emsp;&emsp;我总喜欢在我的作品中埋藏彩蛋，然而却都不够精彩和独一无二。这个彩蛋的灵感呢，来源于Android 14系统，是我设计过的彩蛋中唯一差强人意的一个，以此献给使用CloudOTP的你，希望你喜欢这个彩蛋，也希望你能喜欢CloudOTP💕💕。",
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  context: context,
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
            top: 0,
            child: IgnorePointer(
              child: celebrateWidget,
            ),
          ),
        ),
      ],
    );
  }
}
