import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class WindowsQRScanner extends StatelessWidget {
  final Function(String code) onScan;
  final VoidCallback onManualEntry;

  const WindowsQRScanner(
      {super.key, required this.onScan, required this.onManualEntry});

  /// THE SIMPLE ENGINE: Opens the dedicated high-priority camera window
  Future<void> _launchSimpleScanner(BuildContext context) async {
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (res is String && res != "-1") {
      onScan(res);
      if (context.mounted) {
        Navigator.pop(context); // Close this hub after a successful scan
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F071D), // Deep Space Violet
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      elevation: 24,
      child: Container(
        width: 600, // Enlarge the terminal width
        height: 750, // Enlarge the terminal height
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),

            // --- THE VISUAL VIEWPORT (Simulated Scanner Area) ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Atmospheric Background Grid
                    Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: GridPainter(),
                        size: Size.infinite,
                      ),
                    ),

                    // Center Instruction
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scanLine,
                            color: Color(0xFF8B5CF6), size: 80),
                        const SizedBox(height: 24),
                        Text(
                          "HARDWARE READY",
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Corner Brackets
                    Positioned(top: 30, left: 30, child: _buildCorner(0)),
                    Positioned(top: 30, right: 30, child: _buildCorner(1)),
                    Positioned(bottom: 30, left: 30, child: _buildCorner(3)),
                    Positioned(bottom: 30, right: 30, child: _buildCorner(2)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
            _buildActionButtons(context),
            const SizedBox(height: 24),

            const Text(
              "Institutional Protocol v4.4 • Encrypted Channel Active",
              style: TextStyle(
                  color: Colors.white10,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.shieldCheck,
                color: Color(0xFF8B5CF6), size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CORE IDENTIFIER",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                "SSCR-Cavite Administrative Node",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          _statusBadge(),
        ],
      );

  Widget _statusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF69F0AE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF69F0AE), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            const Text("ONLINE",
                style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ],
        ),
      );

  Widget _buildActionButtons(BuildContext context) => Column(
        children: [
          // THE PRIMARY CAMERA TRIGGER
          SizedBox(
            width: double.infinity,
            height: 75, // Taller button for better presence
            child: ElevatedButton.icon(
              onPressed: () => _launchSimpleScanner(context),
              icon: const Icon(LucideIcons.maximize, size: 24),
              label: Text("ACTIVATE SCANNER WINDOW",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // THE MANUAL FAIL-SAFE
          SizedBox(
            width: double.infinity,
            height: 65,
            child: TextButton.icon(
              onPressed: onManualEntry,
              icon: const Icon(LucideIcons.keyboard, size: 18),
              label: const Text("USE SECURE MANUAL ENTRY",
                  style: TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );

  Widget _buildCorner(int rotation) => Transform.rotate(
        angle: rotation * 1.5708, // 90 degrees in radians
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF8B5CF6), width: 4),
              left: BorderSide(color: Color(0xFF8B5CF6), width: 4),
            ),
          ),
        ),
      );
}

/// Custom Grid Painter for the tech-background feel
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    for (var i = 0.0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
