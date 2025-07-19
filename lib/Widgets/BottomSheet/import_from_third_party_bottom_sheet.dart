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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/andotp_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/enteauth_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/freeotpplus_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/totpauthenticator_importer.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/winauth_importer.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../TokenUtils/ThirdParty/2fas_importer.dart';
import '../../TokenUtils/ThirdParty/aegis_importer.dart';
import '../../TokenUtils/ThirdParty/bitwarden_importer.dart';
import '../../l10n/l10n.dart';
import 'add_bottom_sheet.dart';

class ImportFromThirdPartyBottomSheet extends StatefulWidget {
  const ImportFromThirdPartyBottomSheet({
    super.key,
  });

  @override
  ImportFromThirdPartyBottomSheetState createState() =>
      ImportFromThirdPartyBottomSheetState();
}

class ImportFromThirdPartyBottomSheetState
    extends BaseDynamicState<ImportFromThirdPartyBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        showBack: !ResponsiveUtil.isLandscapeLayout(),
        titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
        onTapBack: () {
          DialogNavigatorHelper.responsivePopPage();
        },
        title: appLocalizations.importFromThirdParty,
        actions: ResponsiveUtil.isLandscapeLayout()
            ? []
            : [
                const BlankIconButton(),
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
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 20,
        top: 10,
      ),
      children: [
        _buildItem(
          asset: AssetFiles.icGoogleauthenticator,
          title: appLocalizations.importFromGoogleAuthenticator,
          description: appLocalizations.importFromGoogleAuthenticatorTip,
          useImport: false,
          onImport: (path) {
            if (ResponsiveUtil.isMobile()) {
              BottomSheetBuilder.showBottomSheet(
                context,
                enableDrag: false,
                responsive: true,
                (context) => const AddBottomSheet(onlyShowScanner: true),
              );
            } else {
              IToast.showTop(
                  appLocalizations.importFromGoogleAuthenticatorInMobile);
            }
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icAegis,
          title: appLocalizations.importFromAegis,
          dialogTitle: appLocalizations.importFromAegisTitle,
          description: appLocalizations.importFromAegisTip,
          onImport: (path) {
            AegisTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.ic2Fas,
          title: appLocalizations.importFrom2FAS,
          dialogTitle: appLocalizations.importFrom2FASTitle,
          description: appLocalizations.importFrom2FASTip,
          allowedExtensions: ['2fas'],
          onImport: (path) {
            TwoFASTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icBitwarden,
          title: appLocalizations.importFromBitwarden,
          dialogTitle: appLocalizations.importFromBitwardenTitle,
          description: appLocalizations.importFromBitwardenTip,
          onImport: (path) {
            BitwardenTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icAndotp,
          title: appLocalizations.importFromAndOTP,
          dialogTitle: appLocalizations.importFromAndOTPTitle,
          description: appLocalizations.importFromAndOTPTip,
          allowedExtensions: ['json', 'aes'],
          onImport: (path) {
            AndOTPTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icAuthenticatorplus,
        //   title: appLocalizations.importFromAuthenticatorPlus,
        //   dialogTitle: appLocalizations.importFromAuthenticatorPlusTitle,
        //   description: appLocalizations.importFromAuthenticatorPlusTip,
        //   allowedExtensions: ['db'],
        //   onImport: (path) {
        //     AuthenticatorPlusTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icEnteauth,
          title: appLocalizations.importFromEnteAuth,
          dialogTitle: appLocalizations.importFromEnteAuthTitle,
          description: appLocalizations.importFromEnteAuthTip,
          allowedExtensions: ['txt'],
          onImport: (path) {
            EnteAuthTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icFreeotp,
        //   allowedExtensions: ['xml'],
        //   title: appLocalizations.importFromFreeOTP,
        //   dialogTitle: appLocalizations.importFromFreeOTPTitle,
        //   description: appLocalizations.importFromFreeOTPTip,
        //   onImport: (path) {
        //     FreeOTPTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icFreeotpplus,
          title: appLocalizations.importFromFreeOTPPlus,
          dialogTitle: appLocalizations.importFromFreeOTPPlusTitle,
          description: appLocalizations.importFromFreeOTPPlusTip,
          onImport: (path) {
            FreeOTPPlusTokenImporter().importFromPath(path);
          },
        ),
        // SizedBox(height: spacing),
        // _buildItem(
        //   asset: AssetUtil.icLastpass,
        //   title: appLocalizations.importFromLastPassAuthenticator,
        //   dialogTitle: appLocalizations.importFromLastPassAuthenticatorTitle,
        //   description: appLocalizations.importFromLastPassAuthenticatorTip,
        //   allowedExtensions: ['json'],
        //   onImport: (path) {
        //     WinauthTokenImporter().importFromPath(path);
        //   },
        // ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icTotpauthenticator,
          title: appLocalizations.importFromTOTPAuthenticator,
          dialogTitle: appLocalizations.importFromTOTPAuthenticatorTitle,
          description: appLocalizations.importFromTOTPAuthenticatorTip,
          allowedExtensions: ['encrypt'],
          onImport: (path) {
            TotpAuthenticatorTokenImporter().importFromPath(path);
          },
        ),
        SizedBox(height: spacing),
        _buildItem(
          asset: AssetFiles.icWinauth,
          title: appLocalizations.importFromWinauth,
          dialogTitle: appLocalizations.importFromWinauthTitle,
          description: appLocalizations.importFromWinauthTip,
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
      color: ChewieTheme.canvasColor,
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
              ChewieAssetUtil.load(asset, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      maxLines: 1,
                      style: ChewieTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: ChewieTheme.bodySmall,
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
