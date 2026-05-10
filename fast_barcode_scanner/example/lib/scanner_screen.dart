import 'dart:async';

import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'detections_counter.dart';

final codeStream = StreamController<Barcode>.broadcast();

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _torchIconState = ValueNotifier(false);

  Future<void> _zoomIn() async {
    await CameraController.instance.zoomIn();
    setState(() {});
  }

  Future<void> _zoomOut() async {
    await CameraController.instance.zoomOut();
    setState(() {});
  }

  Future<void> _setZoom(double zoom) async {
    await CameraController.instance.setZoom(zoom);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Fast Barcode Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _torchIconState,
            builder: (context, state, _) => IconButton(
              icon: state
                  ? const Icon(Icons.flash_on)
                  : const Icon(Icons.flash_off),
              onPressed: () async {
                await CameraController.instance.toggleTorch();
                _torchIconState.value =
                    CameraController.instance.state.torchState;
              },
            ),
          ),
        ],
      ),
      body: BarcodeCamera(
        types: const [
          BarcodeType.ean8,
          BarcodeType.ean13,
          BarcodeType.code128,
          BarcodeType.qr
        ],
        resolution: Resolution.hd720,
        framerate: Framerate.fps30,
        mode: DetectionMode.pauseVideo,
        position: CameraPosition.back,
        onScan: (code) => codeStream.add(code),
        children: [
          const MaterialPreviewOverlay(animateDetection: false),
          const BlurPreviewOverlay(),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ElevatedButton(
                  child: const Text("Resume"),
                  onPressed: () => CameraController.instance.resumeDetector(),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<CameraEvent>(
                  valueListenable: CameraController.instance.state.eventNotifier,
                  builder: (context, _, __) {
                    final cameraState = CameraController.instance.state;
                    final minZoom = cameraState.minZoom;
                    final maxZoom = cameraState.maxZoom <= minZoom
                        ? minZoom + 0.01
                        : cameraState.maxZoom;
                    final zoom = cameraState.zoom.clamp(minZoom, maxZoom);

                    return Column(
                      children: [
                        Text(
                          'Zoom ${zoom.toStringAsFixed(2)}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            SizedBox(
                              width: 220,
                              child: Slider(
                                value: zoom,
                                min: minZoom,
                                max: maxZoom,
                                onChanged: _setZoom,
                              ),
                            ),
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const DetectionsCounter()
              ],
            ),
          )
        ],
      ),
    );
  }
}
