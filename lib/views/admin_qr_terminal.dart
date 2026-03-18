import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../services/supabase_service.dart';

class AdminQRTerminal extends StatefulWidget {
  final String mode; // 'accounting' or 'registrar'
  const AdminQRTerminal({super.key, required this.mode});

  @override
  State<AdminQRTerminal> createState() => _AdminQRTerminalState();
}

class _AdminQRTerminalState extends State<AdminQRTerminal>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  List<Map<String, dynamic>> _scannedBatch = [];
  Map<String, dynamic>? _studentInfo;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 📷 HARDWARE TRIGGER: Opens the specialized window
  Future<void> _launchScanner() async {
    // Prevent multiple clicks
    if (_isProcessing) return;

    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    // THE FIX: simple_barcode_scanner already popped itself.
    // We must check if res is valid before proceeding.
    if (res is String && res != "-1") {
      setState(() => _isProcessing = true);

      // SAFETY DELAY: Gives Windows 500ms to refocus the main window
      // before we trigger a heavy database lookup.
      await Future.delayed(const Duration(milliseconds: 500));
      await _handleScanLookup(res);
    }
  }

  /// 🛰️ CLOUD LOOKUP: Resolves the QR Hash into the Batch of requested documents
  Future<void> _handleScanLookup(String hash) async {
    final client = SupabaseService().client;

    try {
      final List<dynamic> results = await client
          .from('office_requests')
          .select('*, profiles(fn, ln, user_id_number)')
          .eq('qr_hash', hash);

      if (!mounted) return;

      if (results.isEmpty) {
        _showToast("Invalid Ticket: Reference ID not found.", Colors.redAccent);
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _scannedBatch = List<Map<String, dynamic>>.from(results);
        _studentInfo = _scannedBatch.first['profiles'];
        _isProcessing = false;
      });

      HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast(
            "Sync Error: No data returned from Cloud.", Colors.redAccent);
      }
    }
  }

  /// ⚡ BATCH UPDATE: Processes payment or release
  Future<void> _processBatchUpdate() async {
    if (_scannedBatch.isEmpty) return;
    setState(() => _isProcessing = true);

    final client = SupabaseService().client;
    final String hash = _scannedBatch.first['qr_hash'];

    try {
      if (widget.mode == 'accounting') {
        await client.from('office_requests').update({
          'payment_status': 'Paid',
          'paid_at': DateTime.now().toIso8601String(),
        }).eq('qr_hash', hash);
        _showToast("Batch Payment Verified Successfully.", success);
      } else {
        bool allPaid =
            _scannedBatch.every((item) => item['payment_status'] == 'Paid');

        if (!allPaid) {
          _showToast("ACTION BLOCKED: Batch contains unpaid items.",
              Colors.orangeAccent);
        } else {
          await client.from('office_requests').update({
            'request_status': 'Ready for Pickup',
            'released_at': DateTime.now().toIso8601String(),
          }).eq('qr_hash', hash);
          _showToast("Batch set to READY FOR PICKUP.", success);
        }
      }
    } catch (e) {
      _showToast("Update Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _scannedBatch = [];
          _studentInfo = null;
        });
      }
    }
  }

  double _calculateBatchTotal() {
    return _scannedBatch.fold(
        0.0,
        (sum, item) =>
            sum + (double.tryParse(item['amount_due'].toString()) ?? 0.0));
  }

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F071D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("${widget.mode.toUpperCase()} TERMINAL",
            style: GoogleFonts.orbitron(letterSpacing: 2, fontSize: 14)),
        leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Row(
        children: [
          Expanded(flex: 5, child: _buildScannerLauncher()),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: _scannedBatch.isEmpty
                  ? _buildEmptyState()
                  : _buildBatchInfoCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerLauncher() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: aViolet.withOpacity(0.2), width: 3),
        boxShadow: [BoxShadow(color: aViolet.withOpacity(0.1), blurRadius: 60)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCorner(0, top: 40, left: 40),
          _buildCorner(1, top: 40, right: 40),
          _buildCorner(2, bottom: 40, right: 40),
          _buildCorner(3, bottom: 40, left: 40),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _pulseAnimation,
                child:
                    const Icon(LucideIcons.camera, color: aViolet, size: 120),
              ),
              const SizedBox(height: 32),
              Text("BIOMETRIC NODE ACTIVE",
                  style: GoogleFonts.orbitron(
                      color: aViolet,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontSize: 18)),
              const SizedBox(height: 40),
              if (_isProcessing)
                const CircularProgressIndicator(color: aViolet)
              else
                SizedBox(
                  width: 350,
                  height: 75,
                  child: ElevatedButton.icon(
                    onPressed: _launchScanner,
                    icon: const Icon(LucideIcons.maximize),
                    label: const Text("ACTIVATE SCANNER WINDOW",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.qrCode,
                color: Colors.white.withOpacity(0.03), size: 150),
            const SizedBox(height: 24),
            Text("WAITING FOR SCAN",
                style: GoogleFonts.inter(
                    color: Colors.white12,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    letterSpacing: 2)),
          ],
        ),
      );

  Widget _buildBatchInfoCard() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: aViolet.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("STUDENT IDENTITY",
              style: TextStyle(
                  color: aViolet,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 3)),
          const SizedBox(height: 12),
          Text("${_studentInfo?['fn']} ${_studentInfo?['ln']}",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          Text("ID: ${_studentInfo?['user_id_number']}",
              style: const TextStyle(color: Colors.white38)),
          const Divider(height: 60, color: Colors.white10),
          Text("BATCH ITEMS (${_scannedBatch.length})",
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _scannedBatch.length,
              itemBuilder: (context, i) {
                final item = _scannedBatch[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileText,
                          color: aViolet, size: 16),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(item['request_type'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600))),
                      Text("₱${item['amount_due']}",
                          style: const TextStyle(
                              color: success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 40, color: Colors.white10),
          _infoRow("Total Batch Assessment:", "₱${_calculateBatchTotal()}",
              color: success, isLarge: true),
          _infoRow("Payment Status:", _scannedBatch.first['payment_status'],
              color: _scannedBatch.first['payment_status'] == 'Paid'
                  ? success
                  : Colors.orangeAccent),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 75,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processBatchUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.mode == 'accounting'
                          ? "CONFIRM BATCH PAYMENT"
                          : "AUTHORIZE RELEASE",
                      style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

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
                        top: BorderSide(color: aViolet, width: 6),
                        left: BorderSide(color: aViolet, width: 6)))),
          ),
        ),
      );

  Widget _infoRow(String l, String v, {Color? color, bool isLarge = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(v,
              style: GoogleFonts.inter(
                  color: color ?? Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isLarge ? 22 : 16)),
        ]),
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
