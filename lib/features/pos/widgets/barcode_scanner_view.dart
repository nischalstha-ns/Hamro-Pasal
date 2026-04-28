import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  final Function(String barcode) onDetect;

  const BarcodeScannerView({super.key, required this.onDetect});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  late MobileScannerController controller;
  bool _isDetected = false;
  bool _torchEnabled = false;
  bool _isBackCamera = true;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: () {
              controller.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isBackCamera ? Icons.camera_rear : Icons.camera_front,
            ),
            iconSize: 32.0,
            onPressed: () {
              controller.switchCamera();
              setState(() => _isBackCamera = !_isBackCamera);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isDetected) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() => _isDetected = true);
                widget.onDetect(barcodes.first.rawValue!);
                Navigator.pop(context);
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.green, width: 4), left: BorderSide(color: Colors.green, width: 4)))),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.green, width: 4), right: BorderSide(color: Colors.green, width: 4)))),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.green, width: 4), left: BorderSide(color: Colors.green, width: 4)))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.green, width: 4), right: BorderSide(color: Colors.green, width: 4)))),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame',
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
