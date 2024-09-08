import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/andotp_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/enteauth_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/freeotpplus_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/totpauthenticator_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/winauth_importer.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../TokenUtils/ThirdParty/2fas_importer.dart';
import '../../TokenUtils/ThirdParty/aegis_importer.dart';
import '../../TokenUtils/ThirdParty/bitwarden_importer.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/file_util.dart';
import '../../generated/l10n.dart';
import '../General/EasyRefresh/easy_refresh.dart';
import '../Item/item_builder.dart';
import '../Scaffold/my_scaffold.dart';
import 'add_bottom_sheet.dart';
import 'bottom_sheet_builder.dart';

class ImportFromThirdPartyBottomSheet extends StatefulWidget {
  const ImportFromThirdPartyBottomSheet({
    super.key,
  });

  @override
  ImportFromThirdPartyBottomSheetState createState() =>
      ImportFromThirdPartyBottomSheetState();
}

class ImportFromThirdPartyBottomSheetState
    extends State<ImportFromThirdPartyBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: ResponsiveUtil.isLandscape()
            ? Icons.close_rounded
            : Icons.arrow_back_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.importFromThirdParty,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        actions: ResponsiveUtil.isLandscape()
            ? []
            : [
                ItemBuilder.buildBlankIconButton(context),
                const SizedBox(width: 5),
              ],
      ),
      body: EasyRefresh(
        child: _buildBody(),
      ),
    );
  }

  _buildBody({
    double spacing = 8,
    double horizontalPadding = 10,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
          left: horizontalPadding, right: horizontalPadding, bottom: 20),
      children: [
        _buildItem(
          asset: AssetUtil.icGoogleauthenticator,
          title: S.current.importFromGoogleAuthenticator,
          description: S.current.importFromGoogleAuthenticatorTip,
          useImport: false,
          onImport: (path) {
            if (ResponsiveUtil.isMobile()) {
              BottomSheetBuilder.showBottomSheet(
                rootContext,
                enableDrag: false,
                responsive: true,
                    (context) => const AddBottomSheet(onlyShowScanner: true),
              );
            } else {
              IToast.showTop(S.current.importFromGoogleAuthenticatorInMobile);
            }
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icAegis,
          title: S.current.importFromAegis,
          dialogTitle: S.current.importFromAegisTitle,
          description: S.current.importFromAegisTip,
          onImport: (path) {
            AegisTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.ic2Fas,
          title: S.current.importFrom2FAS,
          dialogTitle: S.current.importFrom2FASTitle,
          description: S.current.importFrom2FASTip,
          allowedExtensions: ['2fas'],
          onImport: (path) {
            TwoFASTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icBitwarden,
          title: S.current.importFromBitwarden,
          dialogTitle: S.current.importFromBitwardenTitle,
          description: S.current.importFromBitwardenTip,
          onImport: (path) {
            BitwardenTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icAndotp,
          title: S.current.importFromAndOTP,
          dialogTitle: S.current.importFromAndOTPTitle,
          description: S.current.importFromAndOTPTip,
          allowedExtensions: ['json', 'aes'],
          onImport: (path) {
            AndOTPTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icAuthenticatorplus,
        //   title: S.current.importFromAuthenticatorPlus,
        //   dialogTitle: S.current.importFromAuthenticatorPlusTitle,
        //   description: S.current.importFromAuthenticatorPlusTip,
        //   allowedExtensions: ['db'],
        //   onImport: (path) {
        //     AuthenticatorPlusTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icEnteauth,
          title: S.current.importFromEnteAuth,
          dialogTitle: S.current.importFromEnteAuthTitle,
          description: S.current.importFromEnteAuthTip,
          allowedExtensions: ['txt'],
          onImport: (path) {
            EnteAuthTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icFreeotp,
        //   allowedExtensions: ['xml'],
        //   title: S.current.importFromFreeOTP,
        //   dialogTitle: S.current.importFromFreeOTPTitle,
        //   description: S.current.importFromFreeOTPTip,
        //   onImport: (path) {
        //     FreeOTPTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icFreeotpplus,
          title: S.current.importFromFreeOTPPlus,
          dialogTitle: S.current.importFromFreeOTPPlusTitle,
          description: S.current.importFromFreeOTPPlusTip,
          onImport: (path) {
            FreeOTPPlusTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icLastpass,
        //   title: S.current.importFromLastPassAuthenticator,
        //   dialogTitle: S.current.importFromLastPassAuthenticatorTitle,
        //   description: S.current.importFromLastPassAuthenticatorTip,
        //   allowedExtensions: ['json'],
        //   onImport: (path) {
        //     WinauthTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icTotpauthenticator,
          title: S.current.importFromTOTPAuthenticator,
          dialogTitle: S.current.importFromTOTPAuthenticatorTitle,
          description: S.current.importFromTOTPAuthenticatorTip,
          allowedExtensions: ['encrypt'],
          onImport: (path) {
            TotpAuthenticatorTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetUtil.icWinauth,
          title: S.current.importFromWinauth,
          dialogTitle: S.current.importFromWinauthTitle,
          description: S.current.importFromWinauthTip,
          allowedExtensions: ['zip', 'txt'],
          onImport: (path) {
            WinauthTokenImporter().importFromPath(path);
          },
        ),
      ],
    );
  }

  _buildItem({
    required String asset,
    required String title,
    String? dialogTitle,
    required String description,
    List<String> allowedExtensions = const ['json'],
    Function(String)? onImport,
    bool useImport = true,
    double borderRadius = 12,
    bool showDivider = false,
  }) {
    final allowedExtensionsInAndroid = ['txt', 'json', 'zip'];
    bool containUnsupportExt = false;
    for (var ext in allowedExtensions) {
      if (!allowedExtensionsInAndroid.contains(ext)) containUnsupportExt = true;
    }
    containUnsupportExt = containUnsupportExt && ResponsiveUtil.isAndroid();
    return Material(
      color: Theme.of(context).canvasColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: useImport
            ? () async {
                FilePickerResult? result = await FileUtil.pickFiles(
                  dialogTitle: dialogTitle,
                  type: containUnsupportExt ? FileType.any : FileType.custom,
                  allowedExtensions:
                      containUnsupportExt ? [] : allowedExtensions,
                  lockParentWindow: true,
                );
                if (result != null) {
                  onImport?.call(result.files.single.path!);
                }
              }
            : () {
                onImport?.call("");
              },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              AssetUtil.load(asset, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
