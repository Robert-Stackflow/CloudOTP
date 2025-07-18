import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

import '../awesome_chewie.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.latestReleaseItem,
    required this.latestVersion,
    required this.currentVersion,
  });

  final String latestVersion;
  final String currentVersion;
  final ReleaseItem latestReleaseItem;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum DownloadUpdateState { normal, downloading, toInstall, installing }

class _UpdateScreenState extends BaseDynamicState<UpdateScreen>
    with TickerProviderStateMixin {
  late String currentVersion;

  late String latestVersion;

  late ReleaseItem latestReleaseItem;

  String buttonText = chewieLocalizations.immediatelyDownload;
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
        title: chewieLocalizations.getNewVersion(latestVersion),
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
              chewieLocalizations.changelogAsFollow(item.body ?? ""),
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
            text: chewieLocalizations.updateLater,
            onPressed: () {
              DialogNavigatorHelper.popPage();
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
                    buttonText = chewieLocalizations.installing;
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
                      buttonText = chewieLocalizations.immediatelyInstall;
                    });
                    downloadState == DownloadUpdateState.toInstall;
                  }
                } else if (downloadState == DownloadUpdateState.installing) {
                } else {
                  if (asset.browserDownloadUrl.notNullOrEmpty) {
                    double progressValue = 0.0;
                    setState(() {
                      buttonText =
                          chewieLocalizations.alreadyDownloadProgress(0);
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
                            buttonText =
                                chewieLocalizations.alreadyDownloadProgress(
                                    (progressValue * 100).toInt());
                          });
                        }
                      },
                    ).then((response) async {
                      if (response.statusCode == 200) {
                        IToast.showTop(chewieLocalizations.downloadComplete);
                        setState(() {
                          buttonText = chewieLocalizations.immediatelyInstall;
                          downloadState = DownloadUpdateState.toInstall;
                        });
                      } else {
                        IToast.showTop(chewieLocalizations.downloadFailed);
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
                IToast.showTop(chewieLocalizations.downloadFailed);
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
