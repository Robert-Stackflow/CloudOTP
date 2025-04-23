import 'dart:convert';

import 'package:awesome_chewie/src/Models/github_response.dart';
import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'package:awesome_chewie/src/Widgets/Component/markdown_widget.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/responsive_app_bar.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/selectable_area_wrapper.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.latestReleaseItem,
    required this.latestVersion,
    required this.currentVersion,
    this.overrideDialogNavigatorKey,
  });

  final String latestVersion;
  final String currentVersion;
  final ReleaseItem latestReleaseItem;
  final GlobalKey<DialogWrapperWidgetState>? overrideDialogNavigatorKey;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum DownloadUpdateState { normal, downloading, toInstall, installing }

class _UpdateScreenState extends State<UpdateScreen>
    with TickerProviderStateMixin {
  late String currentVersion;

  late String latestVersion;

  late ReleaseItem latestReleaseItem;

  String buttonText = ChewieS.current.immediatelyDownload;
  DownloadUpdateState downloadState = DownloadUpdateState.normal;

  @override
  void initState() {
    super.initState();
    currentVersion = widget.currentVersion;
    latestVersion = widget.latestVersion;
    latestReleaseItem = widget.latestReleaseItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: ChewieS.current.getNewVersion(latestVersion),
        titleLeftMargin: 15,
        showBack: false,
        backgroundColor: ChewieTheme.canvasColor,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildItem(latestReleaseItem),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  _buildItem(ReleaseItem item) {
    print(jsonEncode(item.body));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      height: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableAreaWrapper(
            focusNode: FocusNode(),
            child: CustomMarkdownWidget(
              ChewieS.current.changelogAsFollow(item.body ?? ""),
              baseStyle: ChewieTheme.titleMedium.apply(
                fontSizeDelta: 1,
                color: ChewieTheme.bodySmall.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        border: ChewieTheme.topDivider,
        color: ChewieTheme.canvasColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RoundIconTextButton(
            text: ChewieS.current.updateLater,
            onPressed: () {
              if (widget.overrideDialogNavigatorKey != null) {
                widget.overrideDialogNavigatorKey?.currentState?.popPage();
              } else {
                chewieProvider.dialogNavigatorState?.popPage();
              }
            },
            fontSizeDelta: 2,
          ),
          const SizedBox(width: 8),
          RoundIconTextButton(
            background: ChewieTheme.primaryColor,
            color: ChewieTheme.primaryButtonColor,
            text: buttonText,
            onPressed: () async {
              try {
                late ReleaseAsset asset;
                if (ResponsiveUtil.isWindows()) {
                  asset = FileUtil.getWindowsInstallerAsset(
                      latestVersion, latestReleaseItem);
                }
                String url = asset.browserDownloadUrl;
                var appDocDir = await getDownloadsDirectory();
                String savePath =
                    "${appDocDir?.path}/${FileUtil.extractFileNameFromUrl(url)}";
                if (downloadState == DownloadUpdateState.downloading) {
                  return;
                } else if (downloadState == DownloadUpdateState.toInstall) {
                  setState(() {
                    buttonText = ChewieS.current.installing;
                    downloadState == DownloadUpdateState.installing;
                  });
                  try {
                    var shell = Shell();
                    await shell
                        .runExecutableArguments(savePath, []).then((result) {
                      downloadState == DownloadUpdateState.normal;
                    });
                  } catch (e, t) {
                    ILogger.error("Failed to install", e, t);
                    IToast.showTop(e.toString());
                    setState(() {
                      buttonText = ChewieS.current.immediatelyInstall;
                    });
                    downloadState == DownloadUpdateState.toInstall;
                  }
                } else if (downloadState == DownloadUpdateState.installing) {
                } else {
                  if (asset.browserDownloadUrl.notNullOrEmpty) {
                    double progressValue = 0.0;
                    setState(() {
                      buttonText = ChewieS.current.alreadyDownloadProgress(0);
                    });
                    downloadState = DownloadUpdateState.downloading;
                    await Dio().download(
                      url,
                      savePath,
                      onReceiveProgress: (count, total) {
                        final value = count / total;
                        if (progressValue != value) {
                          if (progressValue < 1.0) {
                            progressValue = count / total;
                          } else {
                            progressValue = 0.0;
                          }
                          setState(() {
                            buttonText = ChewieS.current
                                .alreadyDownloadProgress(
                                    (progressValue * 100).toInt());
                          });
                        }
                      },
                    ).then((response) async {
                      if (response.statusCode == 200) {
                        IToast.showTop(ChewieS.current.downloadComplete);
                        setState(() {
                          buttonText = ChewieS.current.immediatelyInstall;
                          downloadState = DownloadUpdateState.toInstall;
                        });
                      } else {
                        IToast.showTop(ChewieS.current.downloadFailed);
                        downloadState == DownloadUpdateState.normal;
                        UriUtil.openExternal(latestReleaseItem.url);
                      }
                    });
                  } else {
                    downloadState == DownloadUpdateState.normal;
                    UriUtil.openExternal(latestReleaseItem.url);
                  }
                }
              } catch (e, t) {
                ILogger.error("Failed to download package", e, t);
                IToast.showTop(ChewieS.current.downloadFailed);
                downloadState == DownloadUpdateState.normal;
              }
            },
            fontSizeDelta: 2,
          ),
        ],
      ),
    );
  }
}
