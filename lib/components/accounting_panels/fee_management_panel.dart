import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../services/supabase_service.dart';

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const FeeManagementPanel({super.key, required this.isDarkMode});

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel> {
  bool _isProcessing = false;

  // Theme Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 📷 STEP 1: OPEN SCANNER (Using the working simple_barcode_scanner engine)
  Future<void> _openClaimScanner() async {
    if (_isProcessing) return;

    // Use simple_barcode_scanner as it is the only one working on your Acer hardware
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    // THE FIX: simple_barcode_scanner automatically pops its own window.
    // We do NOT call Navigator.pop() here.
    if (res is String && res != "-1") {
      setState(() => _isProcessing = true);

      // SAFETY DELAY: Gives Windows 600ms to refocus the main window
      // and stabilize the context before triggering the database lookup.
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        await _handleScannedTicket(res);
      }
    }
  }

  /// 🛰️ STEP 2: CLOUD LOOKUP (The Real Logic)
  Future<void> _handleScannedTicket(String hash) async {
    final client = SupabaseService().client;

    try {
      // Lookup the request and join with student profile details
      final result = await client
          .from('office_requests')
          .select('*, profiles(*, student_details(*, courses(name)))')
          .eq('qr_hash', hash)
          .maybeSingle();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result == null) {
        _showToast("Reference ID not found in institutional ledger.",
            Colors.redAccent);
        return;
      }

      _showPaymentPortal(result);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Database Sync Error. Please retry.", Colors.redAccent);
      }
    }
  }

  /// 💳 STEP 3: BILLING SUMMARY & PAYMONGO SIMULATION
  void _showPaymentPortal(Map<String, dynamic> req) {
    final profile = req['profiles'] as Map<String, dynamic>?;
    final dynamic detailsRaw = profile?['student_details'];
    Map<String, dynamic>? details;

    if (detailsRaw is List && detailsRaw.isNotEmpty)
      details = detailsRaw[0];
    else if (detailsRaw is Map<String, dynamic>) details = detailsRaw;

    showDialog(
      context: context,
      builder: (cxt) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: Text("OFFICIAL BILLING",
                    style: TextStyle(
                        color: aViolet,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 2))),
            const SizedBox(height: 24),
            _infoRow("Student Name:", "${profile?['fn']} ${profile?['ln']}"),
            _infoRow("ID Number:", profile?['user_id_number'] ?? "N/A"),
            _infoRow("Course:",
                details?['courses']?['name'] ?? "BS Computer Science"),
            const Divider(height: 48, color: Colors.white10),
            _infoRow("Service:", req['request_type'] ?? "Document"),
            _infoRow("Amount:", "₱${req['amount_due']}", color: success),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                onPressed: () => _triggerPayMongoMock(req),
                icon: const Icon(LucideIcons.creditCard),
                label: const Text("PROCEED TO PAYMONGO (GCASH)"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0055EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📲 STEP 4: MOCK PAYMONGO / GCASH
  void _triggerPayMongoMock(Map<String, dynamic> req) {
    Navigator.pop(context); // Close billing summary

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (cxt) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
                "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Paymongo_Logo.png/640px-Paymongo_Logo.png",
                height: 25),
            const SizedBox(height: 32),
            const Text("SCAN TO PAY VIA GCASH",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 32),
            Image.network(
                "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=PAY-${req['qr_hash']}",
                height: 200,
                width: 200),
            const SizedBox(height: 24),
            const Text(
                "Student: Authenticate the transaction on your mobile device.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 11)),
            const Divider(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await SupabaseService()
                      .client
                      .from('office_requests')
                      .update({
                    'payment_status': 'Paid',
                    'paid_at': DateTime.now().toIso8601String(),
                  }).eq('id', req['id']);
                  if (mounted) {
                    Navigator.pop(cxt);
                    _showToast(
                        "Payment Verified. Institutional record updated.",
                        success);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: success, foregroundColor: Colors.black),
                child: const Text("SIMULATE SUCCESS"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Column(
      children: [
        _buildHeader(textColor),
        const SizedBox(height: 32),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(color: aViolet)
                else ...[
                  Icon(LucideIcons.landmark,
                      color: textColor.withOpacity(0.05), size: 120),
                  const SizedBox(height: 24),
                  Text("Finance Terminal Active",
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1)),
                  const Text(
                      "Launch the scanner to authorize document releasing.",
                      style: TextStyle(color: Colors.blueGrey)),
                ],
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Billing & Collections Node",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            const Text(
                "Cloud-synchronized portal for real-time fee verification.",
                style: TextStyle(color: Colors.blueGrey)),
          ]),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _openClaimScanner,
            icon: const Icon(LucideIcons.scanLine),
            label: const Text("ACTIVATE SCANNER WINDOW"),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );

  Widget _infoRow(String l, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(v,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
        ]),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
