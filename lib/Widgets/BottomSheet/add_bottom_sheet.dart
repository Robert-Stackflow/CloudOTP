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

import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Widgets/BottomSheet/token_option_bottom_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Models/opt_token.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/import_export_token_screen.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../l10n/l10n.dart';
import 'import_from_third_party_bottom_sheet.dart';

class AddBottomSheet extends StatefulWidget {
  const AddBottomSheet({
    super.key,
    this.onlyShowScanner = false,
  });

  final bool onlyShowScanner;

  @override
  AddBottomSheetState createState() => AddBottomSheetState();
}

class AddBottomSheetState extends BaseDynamicState<AddBottomSheet>
    with WidgetsBindingObserver {
  final MobileScannerController scannerController =
      MobileScannerController(useNewCameraSelector: true);
  StreamSubscription<Object?>? _subscription;
  static const double _defaultZoomFactor = 0.43;
  double _zoomFactor = _defaultZoomFactor;
  final double _scaleSensitivity = 0.005;
  List<String> alreadyScanned = [];
  int quatertTurns = 0;
  GlobalKey scannerKey = GlobalKey();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!scannerController.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = scannerController.barcodes.listen(_handleBarcode);
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = scannerController.barcodes.listen(_handleBarcode);
  }

  _handleBarcode(
    BarcodeCapture barcodeCapture, {
    bool autoPopup = false,
    bool addToAlready = true,
  }) async {
    _subscription?.pause();
    List<Barcode> barcodes = barcodeCapture.barcodes;
    List<String> rawValues = [];
    for (Barcode barcode in barcodes) {
      if (barcode.rawValue.notNullOrEmpty &&
          ((addToAlready && !alreadyScanned.contains(barcode.rawValue!)) ||
              !addToAlready)) {
        HapticFeedback.lightImpact();
        rawValues.add(barcode.rawValue!);
        if (addToAlready) alreadyScanned.add(barcode.rawValue!);
      }
    }
    if (rawValues.isNotEmpty) {
      List<OtpToken> tokens = (await ImportTokenUtil.parseRawUri(rawValues,
          autoPopup: autoPopup, context: context))[0];
      if (tokens.length == 1) {
        BottomSheetBuilder.showBottomSheet(
          context,
          responsive: true,
          (context) => TokenOptionBottomSheet(
            token: tokens.first,
            isNewToken: true,
          ),
        );
      }
    }
    _subscription?.resume();
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await scannerController.stop();
    await scannerController.dispose();
  }

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
                top: radius,
                bottom:
                    ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.border,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                _buildScanner(),
                if (!widget.onlyShowScanner)
                  const MyDivider(horizontal: 10, vertical: 5),
                if (!widget.onlyShowScanner) _buildOptions(),
                // if (!widget.onlyShowScanner) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _operationRows() {
    return ValueListenableBuilder(
      valueListenable: scannerController,
      builder: (context, state, child) {
        List<Widget> children = [];
        if (state.isInitialized && state.isRunning) {
          final int? availableCameras = state.availableCameras;
          if (availableCameras != null && availableCameras >= 2) {
            children.add(SwitchCameraButton(controller: scannerController));
          }
          children.add(ToggleFlashlightButton(controller: scannerController));
        }
        children
            .add(AnalyzeImageFromGalleryButton(controller: scannerController));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: children,
          ),
        );
      },
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      alignment: Alignment.center,
      child: Text(
        appLocalizations.scanToken,
        style: ChewieTheme.titleLarge,
      ),
    );
  }

  _buildScanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.isLandscape() ? 20 : 10),
      alignment: Alignment.center,
      height: 400,
      width: MediaQuery.sizeOf(context).width,
      child: Stack(
        children: [
          GestureDetector(
            onDoubleTap: () {
              scannerController.resetZoomScale();
              _zoomFactor = _defaultZoomFactor;
            },
            onScaleUpdate: (details) {
              setState(() {
                _zoomFactor += _scaleSensitivity * (details.scale - 1);
                _zoomFactor = _zoomFactor.clamp(0.0, 1.0);
                scannerController.setZoomScale(_zoomFactor);
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NativeDeviceOrientationReader(
                useSensor: true,
                builder: (ctx) {
                  final orientation =
                      NativeDeviceOrientationReader.orientation(ctx);
                  int turns = 0;
                  switch (orientation) {
                    case NativeDeviceOrientation.portraitUp:
                      turns = 0;
                      break;
                    case NativeDeviceOrientation.portraitDown:
                      turns = 2;
                      break;
                    case NativeDeviceOrientation.landscapeLeft:
                      turns = 3;
                      break;
                    case NativeDeviceOrientation.landscapeRight:
                      turns = 1;
                      break;
                    case NativeDeviceOrientation.unknown:
                      turns = 0;
                      break;
                  }
                  turns = !ResponsiveUtil.isWideLandscape() ? 0 : turns;
                  return RotatedBox(
                    quarterTurns: turns,
                    child: MobileScanner(
                      key: scannerKey,
                      controller: scannerController,
                      placeholderBuilder: (context, child) {
                        return RotatedBox(
                          quarterTurns: 4 - turns,
                          child: ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    appLocalizations.scanPlaceholder,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.apply(color: Colors.white),
                                  ),
                                  Text(
                                    "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.apply(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, child) {
                        return RotatedBox(
                          quarterTurns: 4 - turns,
                          child: ScannerErrorWidget(error: error),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _operationRows(),
          ),
        ],
      ),
    );
  }

  _buildOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EntryItem(
          paddingHorizontal: 20,
          title: appLocalizations.addTokenByManual,
          showLeading: true,
          showTrailing: false,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushDialogRoute(context, const AddTokenScreen());
          },
          leading: LucideIcons.pencilLine,
        ),
        EntryItem(
          paddingHorizontal: 20,
          title: appLocalizations.exportImport,
          showLeading: true,
          showTrailing: false,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushDialogRoute(context, const ImportExportTokenScreen());
          },
          leading: LucideIcons.import,
        ),
        EntryItem(
          paddingHorizontal: 20,
          title: appLocalizations.importFromThirdParty,
          showLeading: true,
          showTrailing: false,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushDialogRoute(
              context,
              const ImportFromThirdPartyBottomSheet(),
            );
          },
          leading: LucideIcons.waypoints,
        ),
      ],
    );
  }
}

class AnalyzeImageFromGalleryButton extends StatelessWidget {
  const AnalyzeImageFromGalleryButton({
    required this.controller,
    super.key,
  });

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      padding: const EdgeInsets.all(12),
      background: Colors.black.withOpacity(0.2),
      icon: const Icon(Icons.photo_rounded, color: Colors.white, size: 32),
      onTap: () async {
        FilePickerResult? result = await FileUtil.pickFiles(
          type: FileType.image,
          lockParentWindow: true,
        );
        if (result == null) return;
        await ImportTokenUtil.analyzeImageFile(result.files.single.path!,
            context: context);
      },
    );
  }
}

class SwitchCameraButton extends StatelessWidget {
  const SwitchCameraButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final int? availableCameras = state.availableCameras;

        if (availableCameras != null && availableCameras < 2) {
          return const SizedBox.shrink();
        }

        final Widget icon;

        switch (state.cameraDirection) {
          case CameraFacing.front:
            icon = const Icon(Icons.camera_front_rounded,
                color: Colors.white, size: 32);
          case CameraFacing.back:
            icon = const Icon(Icons.camera_rear_rounded,
                color: Colors.white, size: 32);
        }

        return CircleIconButton(
          padding: const EdgeInsets.all(12),
          background: Colors.black.withOpacity(0.2),
          icon: icon,
          onTap: () async {
            await controller.switchCamera();
          },
        );
      },
    );
  }
}

class ToggleFlashlightButton extends StatelessWidget {
  const ToggleFlashlightButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        switch (state.torchState) {
          case TorchState.auto:
            return CircleIconButton(
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_auto, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.off:
            return CircleIconButton(
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_off, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.on:
            return CircleIconButton(
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.unavailable:
            return CircleIconButton(
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.no_flash, color: Colors.grey, size: 32),
              onTap: null,
            );
        }
      },
    );
  }
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = appLocalizations.scanControllerUninitialized;
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        errorMessage = appLocalizations.scanControllerAlreadyInitialized;
      case MobileScannerErrorCode.controllerDisposed:
        errorMessage = appLocalizations.scanControllerDisposed;
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = appLocalizations.scanPermissionDenied;
      case MobileScannerErrorCode.unsupported:
        errorMessage = appLocalizations.scanUnsupported;
      default:
        errorMessage = appLocalizations.scanGenericError;
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.apply(color: Colors.white),
            ),
            Text(
              error.errorDetails?.message ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.apply(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
