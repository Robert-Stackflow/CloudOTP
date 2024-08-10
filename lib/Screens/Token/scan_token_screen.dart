import 'dart:async';
import 'dart:io';

import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Utils/itoast.dart';
import '../../generated/l10n.dart';

class ScanTokenScreen extends StatefulWidget {
  const ScanTokenScreen({super.key});

  @override
  ScanTokenScreenState createState() => ScanTokenScreenState();
}

class ScanTokenScreenState extends State<ScanTokenScreen>
    with WidgetsBindingObserver {
  final MobileScannerController scannerController = MobileScannerController();
  StreamSubscription<Object?>? _subscription;
  double _zoomFactor = 0.0;
  final double _scaleSensitivity = 0.01;
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
        unawaited(scannerController.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
      // unawaited(scannerController.stop());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = scannerController.barcodes.listen(_handleBarcode);
    Permission.camera
        .onDeniedCallback(() {
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onGrantedCallback(() async {
          unawaited(scannerController.start());
        })
        .onPermanentlyDeniedCallback(() {
          IToast.showTop(S.current.hasRejectedCameraPermission);
        })
        .onRestrictedCallback(() {
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onLimitedCallback(() {
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .onProvisionalCallback(() {
          IToast.showTop(S.current.pleaseGrantCameraPermission);
        })
        .request()
        .then((_) {
          unawaited(scannerController.start());
        });
  }

  _handleBarcode(
    BarcodeCapture barcodeCapture, {
    bool autoPopup = true,
    bool addToAlready = true,
  }) async {
    _subscription?.pause();
    List<Barcode> barcodes = barcodeCapture.barcodes;
    List<String> rawValues = [];
    for (Barcode barcode in barcodes) {
      if (Utils.isNotEmpty(barcode.rawValue) &&
          ((addToAlready && !alreadyScanned.contains(barcode.rawValue!)) ||
              !addToAlready)) {
        rawValues.add(barcode.rawValue!);
        if (addToAlready) alreadyScanned.add(barcode.rawValue!);
      }
    }
    if (rawValues.isNotEmpty) {
      await ImportTokenUtil.parseRawUri(rawValues,
          autoPopup: autoPopup, context: context);
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

  Widget _buildBarcodeOverlay() {
    return ValueListenableBuilder(
      valueListenable: scannerController,
      builder: (context, value, child) {
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox();
        }
        return StreamBuilder<BarcodeCapture>(
          stream: scannerController.barcodes,
          builder: (context, snapshot) {
            final BarcodeCapture? barcodeCapture = snapshot.data;

            if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
              return const SizedBox();
            }

            final scannedBarcode = barcodeCapture.barcodes.first;

            if (scannedBarcode.corners.isEmpty ||
                value.size.isEmpty ||
                barcodeCapture.size.isEmpty) {
              return const SizedBox();
            }

            return CustomPaint(
              painter: BarcodeOverlay(
                barcodeCorners: scannedBarcode.corners,
                barcodeSize: barcodeCapture.size,
                boxFit: BoxFit.contain,
                cameraPreviewSize: value.size,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScanWindow(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: scannerController,
      builder: (context, value, child) {
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }

        return CustomPaint(
          painter: ScannerOverlay(scanWindowRect),
        );
      },
    );
  }

  Widget _operationRows() {
    return ValueListenableBuilder(
      valueListenable: scannerController,
      builder: (context, state, child) {
        List<Widget> children = [
          // StartStopMobileScannerButton(controller: scannerController),
        ];
        if (state.isInitialized && state.isRunning) {
          final int? availableCameras = state.availableCameras;
          if (availableCameras != null && availableCameras >= 2) {
            children.add(SwitchCameraButton(controller: scannerController));
          }
          children.add(ToggleFlashlightButton(controller: scannerController));
        }
        children.add(AnalyzeImageFromGalleryButton(
          controller: scannerController,
          onDetect: (barcodes) {
            _handleBarcode(barcodes, addToAlready: false, autoPopup: false);
          },
        ));
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: 240,
      height: 240,
    );
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: MyScaffold(
        body: Stack(
          children: <Widget>[
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoomFactor += _scaleSensitivity * (details.scale - 1);
                  _zoomFactor = _zoomFactor.clamp(0.0, 1.0);
                  scannerController.setZoomScale(_zoomFactor);
                });
              },
              child: MobileScanner(
                controller: scannerController,
                scanWindow: scanWindow,
                errorBuilder: (context, error, child) {
                  return ScannerErrorWidget(error: error);
                },
              ),
            ),
            _buildBarcodeOverlay(),
            _buildScanWindow(scanWindow),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _operationRows(),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyzeImageFromGalleryButton extends StatelessWidget {
  const AnalyzeImageFromGalleryButton({
    required this.controller,
    super.key,
    required this.onDetect,
  });

  final MobileScannerController controller;

  final Function(BarcodeCapture) onDetect;

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
        File file = File(result.files.single.path!);
        Uint8List? imageBytes = file.readAsBytesSync();
        ImportTokenUtil.analyzeImage(imageBytes);
        await file.delete();
      },
    );
  }
}

class StartStopMobileScannerButton extends StatelessWidget {
  const StartStopMobileScannerButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return ItemBuilder.buildIconButton(
            context: context,
            padding: const EdgeInsets.all(12),
            background: Colors.black.withOpacity(0.2),
            icon: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 32),
            onTap: () async {
              await controller.start();
            },
          );
        }

        return ItemBuilder.buildIconButton(
          context: context,
          padding: const EdgeInsets.all(12),
          background: Colors.black.withOpacity(0.2),
          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 32),
          onTap: () async {
            await controller.stop();
          },
        );
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

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BarcodeOverlay extends CustomPainter {
  BarcodeOverlay({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.boxFit,
    required this.cameraPreviewSize,
  });

  final List<Offset> barcodeCorners;
  final Size barcodeSize;
  final BoxFit boxFit;
  final Size cameraPreviewSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.isEmpty ||
        barcodeSize.isEmpty ||
        cameraPreviewSize.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);

    double verticalPadding = size.height - adjustedSize.destination.height;
    double horizontalPadding = size.width - adjustedSize.destination.width;
    if (verticalPadding > 0) {
      verticalPadding = verticalPadding / 2;
    } else {
      verticalPadding = 0;
    }

    if (horizontalPadding > 0) {
      horizontalPadding = horizontalPadding / 2;
    } else {
      horizontalPadding = 0;
    }

    final double ratioWidth;
    final double ratioHeight;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      ratioWidth = barcodeSize.width / adjustedSize.destination.width;
      ratioHeight = barcodeSize.height / adjustedSize.destination.height;
    } else {
      ratioWidth = cameraPreviewSize.width / adjustedSize.destination.width;
      ratioHeight = cameraPreviewSize.height / adjustedSize.destination.height;
    }

    final List<Offset> adjustedOffset = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
    ];

    final cutoutPath = Path()..addPolygon(adjustedOffset, true);

    final backgroundPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    canvas.drawPath(cutoutPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
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
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
