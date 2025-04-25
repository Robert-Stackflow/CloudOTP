import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

ProgressDialog showProgressDialog(
  String? msg, {
  bool barrierDismissible = false,
  bool showProgress = true,
}) {
  ProgressDialog dialog = ProgressDialog(context: chewieProvider.rootContext);
  dialog.show(
    msg: msg ?? '加载中...',
    barrierDismissible: barrierDismissible,
    showProgress: showProgress,
  );
  return dialog;
}

class LoadingDialogData {
  String msg;

  double progress;

  bool complete;

  bool error;

  Duration delayDuration;

  bool showProgress;

  LoadingDialogData({
    required this.msg,
    required this.progress,
    required this.complete,
    required this.error,
    required this.delayDuration,
    required this.showProgress,
  });

  LoadingDialogData copyWith({
    String? msg,
    double? progress,
    bool? complete,
    bool? error,
    Duration? delayDuration,
    bool? showProgress,
  }) {
    return LoadingDialogData(
      msg: msg ?? this.msg,
      progress: progress ?? this.progress,
      complete: complete ?? this.complete,
      error: error ?? this.error,
      delayDuration: delayDuration ?? this.delayDuration,
      showProgress: showProgress ?? this.showProgress,
    );
  }
}

class ProgressDialog {
  final ValueNotifier<LoadingDialogData> _data = ValueNotifier(
    LoadingDialogData(
      error: false,
      complete: false,
      progress: 0,
      msg: 'Loading',
      delayDuration: const Duration(milliseconds: 2000),
      showProgress: false,
    ),
  );

  /// [_dialogIsOpen] Shows whether the dialog is open.
  //  Not directly accessible.
  bool _dialogIsOpen = false;

  /// [_context] Required to show the alert.
  // Can only be accessed with the constructor.
  late BuildContext _context;

  ProgressDialog({required context}) {
    _context = context;
  }

  void updateProgress({
    required double progress,
    String? msg,
    bool showProgress = true,
  }) {
    if (progress < 0) {
      progress = 0;
    }
    if (progress > 1) {
      progress = 1;
    }
    _data.value = _data.value
        .copyWith(progress: progress, msg: msg, showProgress: showProgress);
  }

  void updateMessage({required String msg, bool showProgress = true}) {
    _data.value = _data.value.copyWith(msg: msg, showProgress: showProgress);
  }

  void complete(String msg, {Duration? delayDuration}) {
    _data.value = _data.value
        .copyWith(complete: true, msg: msg, delayDuration: delayDuration);
  }

  void completeWithError(String msg, {Duration? delayDuration}) {
    _data.value = _data.value
        .copyWith(error: true, msg: msg, delayDuration: delayDuration);
  }

  void dismiss() {
    if (_dialogIsOpen) {
      Navigator.pop(chewieProvider.rootContext);
      _dialogIsOpen = false;
    }
  }

  bool isOpen() {
    return _dialogIsOpen;
  }

  show({
    required String msg,
    bool barrierDismissible = true,
    bool showProgress = true,
  }) {
    _dialogIsOpen = true;
    _data.value = _data.value.copyWith(msg: msg, showProgress: showProgress);
    return showDialog(
      barrierDismissible: barrierDismissible,
      context: _context,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          PopScope(
            canPop: barrierDismissible,
            onPopInvoked: (_) {
              if (barrierDismissible) {
                _dialogIsOpen = false;
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ChewieTheme.canvasColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: ValueListenableBuilder(
                valueListenable: _data,
                builder: (BuildContext context, LoadingDialogData value,
                    Widget? child) {
                  if (value.complete || value.error) {
                    Future.delayed(_data.value.delayDuration, () {
                      dismiss();
                    });
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LoadingDialogIndicator(
                        complete: _data.value.complete,
                        error: _data.value.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_data.value.msg}${showProgress ? (_data.value.progress * 100).toStringAsFixed(1) : ''}%',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChewieTheme.labelLarge,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDialogIndicator extends StatefulWidget {
  final bool complete;
  final bool error;

  const LoadingDialogIndicator({
    super.key,
    required this.complete,
    required this.error,
  });

  @override
  State<LoadingDialogIndicator> createState() => _LoadingDialogIndicatorState();
}

class _LoadingDialogIndicatorState extends State<LoadingDialogIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return chewieProvider.loadingWidgetBuilder(40, false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
