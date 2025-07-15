import 'package:awesome_chewie/src/Models/github_response.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/time_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Widgets/Component/markdown_widget.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_gesture_detector.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/responsive_app_bar.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/selectable_area_wrapper.dart';
import 'package:awesome_chewie/src/Widgets/Module/EasyRefresh/easy_refresh.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../awesome_chewie.dart';

class UpdateLogScreen extends StatefulWidget {
  const UpdateLogScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  final bool showTitleBar;
  final EdgeInsets padding;

  @override
  State<UpdateLogScreen> createState() => _UpdateLogScreenState();
}

class _UpdateLogScreenState extends State<UpdateLogScreen>
    with TickerProviderStateMixin {
  List<ReleaseItem> releaseItems = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  String currentVersion = "";
  String latestVersion = "";

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
  }

  Future<void> fetchReleases() async {
    await ChewieUtils.getReleases(
      context: context,
      showLoading: false,
      showUpdateDialog: false,
      showLatestToast: false,
      noUpdateToastText: ChewieS.current.failedToGetChangelog,
      onGetCurrentVersion: (currentVersion) {
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        setState(() {
          this.latestVersion = latestVersion;
        });
      },
      onGetReleases: (releases) {
        setState(() {
          releaseItems = releases;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showTitleBar
          ? ResponsiveAppBar(
              title: ChewieS.current.changelog,
              showBack: true,
              onTapBack: () {
                if (ResponsiveUtil.isLandscape()) {
                  chewieProvider.dialogNavigatorState?.popPage();
                } else {
                  Navigator.pop(context);
                }
              },
              backgroundColor: ResponsiveUtil.isLandscape()
                  ? ChewieTheme.canvasColor
                  : ChewieTheme.scaffoldBackgroundColor,
            )
          : null,
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          await fetchReleases();
        },
        child: ListView.builder(
          padding: widget.padding
              .add(const EdgeInsets.symmetric(horizontal: 8, vertical: 20)),
          itemBuilder: (context, index) => _buildItem(
            releaseItems[index],
            index,
            index == releaseItems.length - 1,
          ),
          itemCount: releaseItems.length,
        ),
      ),
    );
  }

  Widget _buildItem(ReleaseItem item, int index, bool isLast) {
    final isCurrent = ChewieUtils.compareVersion(
            item.tagName.replaceAll(RegExp(r'[a-zA-Z]'), ''), currentVersion) ==
        0;

    final releaseDate =
        item.publishedAt != null ? TimeUtil.formatDate(item.publishedAt!) : "";

    final color = HSLColor.fromAHSL(
      1.0,
      140 + (index * 220 / (releaseItems.length + 1)),
      0.6,
      isCurrent ? 0.5 : 0.4,
    ).toColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? ChewieTheme.primaryColor : color,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(delay: 50.ms),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 2),
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${item.tagName}  $releaseDate",
                        style: ChewieTheme.bodyMedium,
                      ),
                      const SizedBox(width: 6),
                      if (isCurrent)
                        RoundIconTextButton(
                          height: 20,
                          text: ChewieS.current.currentVersion,
                          background: ChewieTheme.primaryColor,
                          textStyle: ChewieTheme.labelMedium.apply(
                            color: ChewieTheme.primaryButtonColor,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          radius: 4,
                        ),
                      const Spacer(),
                      ClickableGestureDetector(
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 6,
                        //   vertical: 2,
                        // ),
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: ChewieTheme.labelMedium.color,
                        ),
                        onTap: () {
                          UriUtil.launchUrlUri(context, item.htmlUrl);
                        },
                      ),
                    ],
                  ),
                  if ((item.body ?? "").isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ChewieTheme.cardColor,
                        borderRadius: ChewieDimens.borderRadius8,
                      ),
                      child: SelectableAreaWrapper(
                        focusNode: FocusNode(),
                        child: CustomMarkdownWidget(
                          item.body ?? "",
                          baseStyle: ChewieTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
