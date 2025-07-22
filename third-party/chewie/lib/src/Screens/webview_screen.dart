import 'dart:collection';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({
    super.key,
    required this.url,
    required this.processUri,
  });

  final String url;
  final bool processUri;

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends BaseDynamicState<WebviewScreen>
    with TickerProviderStateMixin {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    allowsLinkPreview: false,
    useOnDownloadStart: true,
  );
  late ContextMenu contextMenu;
  String url = "";
  String title = "";
  bool canPop = true;
  bool showError = false;
  WebResourceError? currentError;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
      onCreateContextMenu: (hitTestResult) async {},
      onHideContextMenu: () {},
      onContextMenuActionItemClicked: (contextMenuItemClicked) async {},
    );
  }

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          chewieLocalizations.refresh,
          iconData: Icons.refresh_rounded,
          onPressed: () async {
            webViewController?.reload();
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.copyLink,
          iconData: Icons.copy_rounded,
          onPressed: () {
            ChewieUtils.copy(context, widget.url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.openWithBrowser,
          iconData: Icons.open_in_browser_rounded,
          onPressed: () {
            UriUtil.openExternal(widget.url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.shareToOtherApps,
          iconData: Icons.share_rounded,
          onPressed: () {
            UriUtil.share(widget.url);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (_, __) {
        showError = false;
        webViewController?.canGoBack().then((canGoBack) {
          webViewController?.goBack();
        });
      },
      child: Scaffold(
        appBar: ResponsiveAppBar(
          titleLeftMargin: 10,
          showBack: true,
          title: title,
          showBorder: true,
          onTapBack: () {
            DialogNavigatorHelper.responsivePopPage();
          },
          actions: [
            CircleIconButton(
              icon: Icon(
                LucideIcons.ellipsisVertical,
                color: ChewieTheme.iconColor,
              ),
              onTap: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
          ],
          desktopActions: [
            ToolButton(
              context: context,
              icon: LucideIcons.ellipsisVertical,
              buttonSize: const Size(32, 32),
              onPressed: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialSettings: settings,
              contextMenu: contextMenu,
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },
              onTitleChanged: (controller, title) {
                setState(() {
                  this.title = title ?? "";
                });
              },
              onLoadStart: (controller, url) async {
                setState(() {
                  this.url = url.toString();
                });
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT);
              },
              onDownloadStartRequest: (controller, url) async {
                IToast.showTop(chewieLocalizations.jumpToBrowserDownload);
                Future.delayed(const Duration(milliseconds: 300), () {
                  UriUtil.openExternalUri(url.url);
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about",
                ].contains(uri.scheme)) {
                  if (await UriUtil.canLaunchUri(uri)) {
                    UriUtil.launchUri(uri);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                bool processed = widget.processUri
                    ? await UriUtil.processUrl(
                        context,
                        uri.toString(),
                        quiet: true,
                        pass: true,
                      )
                    : false;
                if (processed) return NavigationActionPolicy.CANCEL;
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  this.url = url.toString();
                });
              },
              onReceivedError: (controller, request, error) {
                currentError = error;
                setState(() {});
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                setState(() {
                  this.url = url.toString();
                });
                webViewController!.canGoBack().then((value) => canPop = !value);
              },
              onConsoleMessage: (controller, consoleMessage) {},
            ),
            progress < 1.0
                ? LinearProgressIndicator(
                    value: progress,
                    color: ChewieTheme.primaryColor,
                    backgroundColor: Colors.transparent,
                    minHeight: 2,
                  )
                : emptyWidget,
            _buildErrorPage(),
          ],
        ),
      ),
    );
  }

  _buildErrorPage() {
    return Visibility(
      visible: showError,
      child: Container(
        height: MediaQuery.sizeOf(context).height - 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ChewieTheme.getBackground(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 100),
              Icon(
                LucideIcons.triangleAlert,
                size: 50,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 10),
              Text(
                chewieLocalizations.loadFailed,
                style: ChewieTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                chewieLocalizations.loadErrorType(currentError != null
                    ? currentError?.type ?? ""
                    : chewieLocalizations.loadUnkownError),
                style: ChewieTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Container(
                width: 180,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: RoundIconTextButton(
                  text: chewieLocalizations.reload,
                  onPressed: () {
                    webViewController?.reload();
                  },
                  fontSizeDelta: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
