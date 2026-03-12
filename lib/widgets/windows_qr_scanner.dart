import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class WindowsQRScanner extends StatefulWidget {
  final Function(String code) onScan;
  final VoidCallback onManualEntry;

  const WindowsQRScanner(
      {super.key, required this.onScan, required this.onManualEntry});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner>
    with SingleTickerProviderStateMixin {
  // Animation for the tech-ui pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// THE ENGINE: Opens the dedicated high-priority hardware window
  Future<void> _launchHardwareScanner(BuildContext context) async {
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (res is String && res != "-1") {
      widget.onScan(res);
      if (context.mounted) {
        Navigator.pop(context); // Close this hub after a successful scan
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F071D), // Deep Space Violet
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
      elevation: 32,
      child: Container(
        width: 800, // Ultra-wide presence
        height: 900, // Tall terminal aesthetic
        padding: const EdgeInsets.all(56),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 48),

            // --- THE ENLARGED TERMINAL VIEWPORT ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      blurRadius: 60,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Atmospheric Background Grid
                    Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: GridPainter(),
                        size: Size.infinite,
                      ),
                    ),

                    // 2. TECH DECORATIONS
                    _buildCorner(0, top: 40, left: 40),
                    _buildCorner(1, top: 40, right: 40),
                    _buildCorner(2, bottom: 40, right: 40),
                    _buildCorner(3, bottom: 40, left: 40),

                    // 3. CENTER STATUS
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: const Icon(LucideIcons.camera,
                              color: Color(0xFF8B5CF6), size: 100),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "HARDWARE HUB READY",
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "2M USB Camera Identified",
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 56),
            _buildActionButtons(context),
            const SizedBox(height: 32),

            const Text(
              "Institutional Protocol v5.2 • High-Priority Driver Link Active",
              style: TextStyle(
                  color: Colors.white10,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(LucideIcons.shieldCheck,
                color: Color(0xFF8B5CF6), size: 36),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CORE IDENTIFIER",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  letterSpacing: -1.5,
                ),
              ),
              const Text(
                "SSCR-Cavite Administrative Biometric Node",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          _statusBadge(),
        ],
      );

  Widget _statusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF69F0AE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: Color(0xFF69F0AE), shape: BoxShape.circle)),
            ),
            const SizedBox(width: 12),
            const Text("ONLINE",
                style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _buildActionButtons(BuildContext context) => Column(
        children: [
          // THE PRIMARY HARDWARE TRIGGER
          SizedBox(
            width: double.infinity,
            height: 85,
            child: ElevatedButton.icon(
              onPressed: () => _launchHardwareScanner(context),
              icon: const Icon(LucideIcons.maximize, size: 28),
              label: Text("ACTIVATE SCANNER WINDOW",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 12,
                shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // THE MANUAL FAIL-SAFE
          SizedBox(
            width: double.infinity,
            height: 70,
            child: TextButton.icon(
              onPressed: widget.onManualEntry,
              icon: const Icon(LucideIcons.keyboard, size: 20),
              label: const Text("USE SECURE MANUAL ENTRY",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontSize: 14)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      );

  Widget _buildCorner(int rotation,
          {double? top, double? bottom, double? left, double? right}) =>
      Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Transform.rotate(
          angle: rotation * 1.5708,
          child: FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF8B5CF6), width: 6),
                  left: BorderSide(color: Color(0xFF8B5CF6), width: 6),
                ),
              ),
            ),
          ),
        ),
      );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    for (var i = 0.0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
