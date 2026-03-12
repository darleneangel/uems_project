import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isReadyToShow = false;
  String? _statusText = "Detecting Institutional Hardware...";
  bool _hasError = false;
  Timer? _scanTimer;
  int _currentCameraIndex = 0;
  List<CameraDescription> _availableCameras = [];

  @override
  void initState() {
    super.initState();
    // Delay to let the UI dialog animation finish
    Future.delayed(const Duration(milliseconds: 1000), () => _probeHardware());
  }

  /// THE PROBER: Iterates through all Windows camera handles to bypass locks
  Future<void> _probeHardware() async {
    if (!mounted) return;

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        setState(() {
          _statusText = "No 2M USB Camera found. Check connection.";
          _hasError = true;
        });
        return;
      }

      _attemptHandshake(_currentCameraIndex);
    } catch (e) {
      setState(() {
        _statusText = "Hardware Access Denied: $e";
        _hasError = true;
      });
    }
  }

  Future<void> _attemptHandshake(int index) async {
    if (!mounted) return;

    // Release any previous attempts
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final camera = _availableCameras[index];
    setState(() {
      _statusText = "Pinging Hardware Hub [Index $index]...";
      _hasError = false;
    });

    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.low, // Minimum bandwidth for best chance of success
        enableAudio: false,
      );

      // Timeout wrapper: If driver doesn't answer in 5s, it's locked
      await controller.initialize().timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _controller = controller;
          _isReadyToShow = true;
          _statusText = "Encrypted Stream Active";
        });

        // Scan loop (Throttled for Windows stability)
        _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (!mounted || _hasError || _controller == null) timer.cancel();
          _captureAndProcess();
        });
      }
    } catch (e) {
      // If index 0 fails, try the next one (Windows often has multiple handles for 1 camera)
      if (index + 1 < _availableCameras.length) {
        _currentCameraIndex++;
        _attemptHandshake(_currentCameraIndex);
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusText =
                "Windows Driver Conflict Detected.\n(All hardware handles are locked)";
          });
        }
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _hasError)
      return;
    try {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final img.Image? bitmap = img.decodeImage(bytes);

      if (bitmap != null && mounted) {
        final pixels = bitmap.toUint8List().buffer.asInt32List();
        final source = RGBLuminanceSource(bitmap.width, bitmap.height, pixels);
        final result =
            QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source)));

        if (result.text != null) {
          HapticFeedback.vibrate();
          widget.onScan(result.text!);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F071D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 500,
        height: 620,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                Text("CORE VALIDATOR",
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white24))
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: _hasError
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.white10),
                ),
                child: _isReadyToShow && _controller != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CameraPreview(_controller!))
                    : _buildStatusView(),
              ),
            ),
            const SizedBox(height: 32),
            _buildActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_hasError)
              const CircularProgressIndicator(color: Color(0xFF8B5CF6))
            else
              const Icon(LucideIcons.alertCircle,
                  color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_statusText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _buildActionArea() => Column(
        children: [
          const Text("Point Student QR at webcam lens.",
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: widget.onManualEntry,
              icon: const Icon(LucideIcons.keyboard),
              label: const Text("USE SECURE MANUAL ENTRY"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          )
        ],
      );
}
