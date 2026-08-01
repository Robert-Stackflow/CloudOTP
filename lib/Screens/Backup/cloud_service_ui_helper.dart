import 'package:awesome_chewie/awesome_chewie.dart';

import '../../l10n/l10n.dart';

class CloudServiceUiHelper {
  const CloudServiceUiHelper._();

  static Future<T> runWithLoading<T>({
    required Future<T> Function() action,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(
        title: appLocalizations.cloudConnecting,
      );
    }
    try {
      return await action();
    } finally {
      if (showLoading) {
        await CustomLoadingDialog.dismissLoading();
      }
    }
  }
}
