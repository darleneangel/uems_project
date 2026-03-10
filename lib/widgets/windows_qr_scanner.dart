import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:image/image.dart' as img;

class WindowsQRScanner extends StatefulWidget {
  final Function(String code) onScan;
  final VoidCallback onManualEntry;

  const WindowsQRScanner(
      {super.key, required this.onScan, required this.onManualEntry});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isDiscovering = true;
  String? _error;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the build context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCameraWithRetry();
    });
  }

  /// RE-ENHANCED: Multi-attempt discovery to wake up Windows drivers
  Future<void> _setupCameraWithRetry() async {
    setState(() {
      _isDiscovering = true;
      _error = null;
    });

    try {
      List<CameraDescription> cameras = [];

      // Attempt 1: Immediate check
      cameras = await availableCameras();

      // Attempt 2: If empty, wait 800ms and try again (Handles Windows Latency)
      if (cameras.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        cameras = await availableCameras();
      }

      if (cameras.isEmpty) {
        throw Exception(
            "No webcam detected. If your camera is plugged in, another app (Zoom/Teams) might be using it.");
      }

      // Initialize with Medium resolution for faster CPU-based decoding
      final newController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888, // Optimal for Windows
      );

      await newController.initialize();

      if (mounted) {
        setState(() {
          _controller = newController;
          _isInitialized = true;
          _isDiscovering = false;
        });
        // Start the decoding loop (every 700ms)
        _scanTimer = Timer.periodic(
            const Duration(milliseconds: 700), (_) => _captureAndDecode());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _error = e.toString().contains("MissingPluginException")
              ? "App Build Mismatch: Please run 'flutter clean' and restart."
              : e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  /// THE DECODER ENGINE
  Future<void> _captureAndDecode() async {
    if (_isScanning || _controller == null || !_controller!.value.isInitialized)
      return;
    if (!mounted) return;

    setState(() => _isScanning = true);

    try {
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List bytes = await imageFile.readAsBytes();

      final img.Image? bitmap = img.decodeImage(bytes);

      if (bitmap != null && mounted) {
        // Safe conversion to Int32List for ZXing consumption
        final Uint8List rgbaBytes = bitmap.toUint8List();
        final Int32List pixels = rgbaBytes.buffer.asInt32List();

        final RGBLuminanceSource source = RGBLuminanceSource(
          bitmap.width,
          bitmap.height,
          pixels,
        );

        final HybridBinarizer binarizer = HybridBinarizer(source);
        final BinaryBitmap binaryBitmap = BinaryBitmap(binarizer);
        final QRCodeReader reader = QRCodeReader();

        final Result result = reader.decode(binaryBitmap);

        if (result.text != null && result.text!.isNotEmpty) {
          _scanTimer?.cancel();
          widget.onScan(result.text!);
        }
      }
    } catch (_) {
      // Loop continues if no QR is detected in current frame
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    // Crucial: Dispose the controller to release hardware lock for other apps
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1B4B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 550,
        height: 720,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black,
                  border: Border.all(color: Colors.white10, width: 2),
                ),
                child: _buildCameraPreview(),
              ),
            ),
            const SizedBox(height: 32),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          const Icon(LucideIcons.camera, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Text("Official Camera Core",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const Spacer(),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.x, color: Colors.white24)),
        ],
      );

  Widget _buildCameraPreview() {
    if (_isDiscovering) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 20),
            Text("SCANNING FOR HARDWARE...",
                style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _setupCameraWithRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text("RE-INITIALIZE WEBCAM"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6)),
              )
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        _buildOverlay(),
        if (_isScanning)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(LucideIcons.zap,
                  color: Color(0xFF69F0AE), size: 16),
            ),
          )
      ],
    );
  }

  Widget _buildOverlay() => IgnorePointer(
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 260,
                    height: 1,
                    decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF8B5CF6),
                              blurRadius: 10,
                              spreadRadius: 2)
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFooter() => Column(
        children: [
          const Text("Hardware verified. Ensure the QR is well-lit.",
              style: TextStyle(color: Colors.white24, fontSize: 11)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                _scanTimer?.cancel();
                Navigator.pop(context);
                widget.onManualEntry();
              },
              icon: const Icon(LucideIcons.keyboard),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E1B4B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              label: const Text("USE MANUAL ENTRY",
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
}
