import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/scan_token_screen.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class AddBottomSheet extends StatefulWidget {
  const AddBottomSheet({
    super.key,
  });

  @override
  AddBottomSheetState createState() => AddBottomSheetState();
}

class AddBottomSheetState extends State<AddBottomSheet>
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
              ItemBuilder.buildDivider(context, horizontal: 8, vertical: 0),
              _buildOptions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      height: 300,
      width: 400,
      child: GestureDetector(
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
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
          ),
        ),
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
          title: S.current.addToken,
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
          title: S.current.scanFromImageFile,
          showLeading: true,
          showTrailing: false,
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
          leading: Icons.insert_photo_outlined,
        ),
      ],
    );
  }
}
