import 'dart:async';

import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/token_option_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Models/opt_token.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/import_export_token_screen.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import 'bottom_sheet_builder.dart';

class AddBottomSheet extends StatefulWidget {
  const AddBottomSheet({
    super.key,
    this.onlyShowScanner = false,
  });

  final bool onlyShowScanner;

  @override
  AddBottomSheetState createState() => AddBottomSheetState();
}

class AddBottomSheetState extends State<AddBottomSheet>
    with WidgetsBindingObserver {
  final MobileScannerController scannerController =
      MobileScannerController(useNewCameraSelector: true);
  StreamSubscription<Object?>? _subscription;
  static const double _defaultZoomFactor = 0.43;
  double _zoomFactor = _defaultZoomFactor;
  final double _scaleSensitivity = 0.005;
  List<String> alreadyScanned = [];

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
    // initCamera();
  }

  initCamera() async {
    await Permission.camera
        .onDeniedCallback(() {
          print("onDeniedCallback");
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onGrantedCallback(() async {
          print("onGrantedCallback");
          unawaited(scannerController.start());
        })
        .onPermanentlyDeniedCallback(() {
          print("onPermanentlyDeniedCallback");
          IToast.showTop(S.current.hasRejectedCameraPermission);
        })
        .onRestrictedCallback(() {
          print("onRestrictedCallback");
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onLimitedCallback(() {
          print("onLimitedCallback");
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onProvisionalCallback(() {
          print("onProvisionalCallback");
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .request()
        .then((value) {
          print("value:${value}");
          if (value.isGranted) {
            print("Camera permission granted");
            unawaited(scannerController.start());
          }
        });
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
      if (Utils.isNotEmpty(barcode.rawValue) &&
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
            forceShowCode: true,
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              _buildScanner(),
              if (!widget.onlyShowScanner)
                ItemBuilder.buildDivider(context, horizontal: 10, vertical: 0),
              if (!widget.onlyShowScanner) _buildOptions(),
              if (!widget.onlyShowScanner) const SizedBox(height: 20),
            ],
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
        S.current.scanToken,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildScanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      height: 400,
      width: 400,
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
              child: MobileScanner(
                controller: scannerController,
                placeholderBuilder: (context, child) {
                  return ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        S.current.scanPlaceholder,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.apply(color: Colors.white),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, child) {
                  return ScannerErrorWidget(error: error);
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
        ItemBuilder.buildEntryItem(
          context: context,
          horizontalPadding: 20,
          title: S.current.addTokenByManual,
          showLeading: true,
          showTrailing: false,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushCupertinoRoute(context, const AddTokenScreen());
          },
          leading: Icons.add_rounded,
        ),
        ItemBuilder.buildEntryItem(
          context: context,
          horizontalPadding: 20,
          title: S.current.exportImport,
          showLeading: true,
          showTrailing: false,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushCupertinoRoute(
                context, const ImportExportTokenScreen());
          },
          leading: Icons.import_export_rounded,
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
    return ItemBuilder.buildIconButton(
      context: context,
      padding: const EdgeInsets.all(12),
      background: Colors.black.withOpacity(0.2),
      icon: const Icon(Icons.photo_rounded, color: Colors.white, size: 32),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
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

        return ItemBuilder.buildIconButton(
          context: context,
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
            return ItemBuilder.buildIconButton(
              context: context,
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_auto, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.off:
            return ItemBuilder.buildIconButton(
              context: context,
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_off, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.on:
            return ItemBuilder.buildIconButton(
              context: context,
              padding: const EdgeInsets.all(12),
              background: Colors.black.withOpacity(0.2),
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onTap: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.unavailable:
            return ItemBuilder.buildIconButton(
              context: context,
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
        errorMessage = S.current.scanControllerUninitialized;
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        errorMessage = S.current.scanControllerAlreadyInitialized;
      case MobileScannerErrorCode.controllerDisposed:
        errorMessage = S.current.scanControllerDisposed;
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = S.current.scanPermissionDenied;
      case MobileScannerErrorCode.unsupported:
        errorMessage = S.current.scanUnsupported;
      default:
        errorMessage = S.current.scanGenericError;
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