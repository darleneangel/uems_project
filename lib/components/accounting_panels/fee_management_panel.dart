import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';
import '../../widgets/windows_qr_scanner.dart';

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const FeeManagementPanel({super.key, required this.isDarkMode});

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel> {
  bool _isProcessing = false;

  // Standardized Tonal Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 📷 STEP 1: OPEN SCANNER (Webcam / Windows Hardware Bridge)
  void _openClaimScanner() {
    showDialog(
      context: context,
      builder: (cxt) => WindowsQRScanner(
        onScan: (code) {
          Navigator.pop(cxt);
          _handleScannedTicket(code);
        },
        onManualEntry: () {
          Navigator.pop(cxt);
          _showManualEntryDialog();
        },
      ),
    );
  }

  /// 🛰️ STEP 2: LOOKUP STUDENT DATA (With Robust Type Handling)
  Future<void> _handleScannedTicket(String hash) async {
    setState(() => _isProcessing = true);
    final client = SupabaseService().client;

    try {
      // Logic: Join request with profile and academic details
      final result = await client
          .from('office_requests')
          .select('*, profiles(*, student_details(*, courses(name)))')
          .eq('qr_hash', hash)
          .maybeSingle();

      if (mounted) setState(() => _isProcessing = false);

      if (result == null) {
        _showToast("Invalid Ticket: No matching record in cloud ledger.",
            Colors.redAccent);
        return;
      }

      _showPaymentPortal(result);
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _showToast("Sync Error: Check database columns or RLS settings.",
          Colors.redAccent);
    }
  }

  /// 💳 STEP 3: MOCK PAYMONGO PORTAL
  void _showPaymentPortal(Map<String, dynamic> req) {
    // ROBUST EXTRACTION: Fixes the 'Map vs List' error from your screenshot
    final profile = req['profiles'] as Map<String, dynamic>?;
    final dynamic detailsRaw = profile?['student_details'];
    Map<String, dynamic>? details;

    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw[0];
    } else if (detailsRaw is Map<String, dynamic>) {
      details = detailsRaw;
    }

    showDialog(
      context: context,
      builder: (cxt) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text("BILLING DOSSIER",
                    style: GoogleFonts.inter(
                        color: aViolet,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2))),
            const SizedBox(height: 32),
            _infoRow("Student Name:", "${profile?['fn']} ${profile?['ln']}"),
            _infoRow("Institutional ID:", profile?['user_id_number'] ?? "N/A"),
            _infoRow("Academic Program:",
                details?['courses']?['name'] ?? "BS Computer Science"),
            const Divider(height: 48, color: Colors.white10),
            _infoRow("DOCUMENT:", req['request_type'] ?? "Service"),
            _infoRow("FEES DUE:", "₱${req['amount_due']}", color: success),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _triggerPayMongoMock(req),
                icon: const Icon(LucideIcons.qrCode),
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

  /// 📲 STEP 4: GENERATE PAYMENT QR
  void _triggerPayMongoMock(Map<String, dynamic> req) {
    Navigator.pop(context);
    final String paymentPayload =
        "PAY-UEMS-${req['qr_hash']}-${Random().nextInt(999)}";
    final String payUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$paymentPayload";

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
            const SizedBox(height: 8),
            Text("AMOUNT: ₱${req['amount_due']}",
                style: const TextStyle(
                    color: Color(0xFF0055EE), fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(20)),
              child: Image.network(payUrl, height: 200, width: 200),
            ),
            const Divider(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  // Updates the cloud ledger - instantly reflects on other screens
                  await SupabaseService()
                      .client
                      .from('office_requests')
                      .update({'payment_status': 'Paid'}).eq('id', req['id']);
                  if (mounted) {
                    Navigator.pop(cxt);
                    _showToast(
                        "Payment Verified. Status updated to PAID.", success);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: success,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("SIMULATE PAYMENT SUCCESS (WEBHOOK)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⌨️ FALLBACK: Manual Ticket Entry
  void _showManualEntryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (cxt) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text("Manual Ticket Lookup",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "Enter Ref Hash (e.g. REQ-2031-...)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(cxt), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(cxt);
              _handleScannedTicket(ctrl.text.trim());
            },
            child: const Text("PROCEED"),
          )
        ],
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
        if (_isProcessing) const LinearProgressIndicator(color: aViolet),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10)),
            child: _buildTransactionFeed(textColor),
          ),
        )
      ],
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Financial Settlement Node",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            const Text(
                "Cloud-synchronized portal for real-time document fee verification.",
                style: TextStyle(color: Colors.blueGrey)),
          ]),
          ElevatedButton.icon(
            onPressed: _openClaimScanner,
            icon: const Icon(LucideIcons.scanLine),
            label: const Text("SCAN CLAIM TICKET"),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ],
      );

  Widget _buildTransactionFeed(Color text) {
    return Column(
      children: [
        Icon(LucideIcons.history, color: text.withOpacity(0.1), size: 64),
        const SizedBox(height: 20),
        Text("Waiting for Scanner Input",
            style: GoogleFonts.inter(
                color: text, fontWeight: FontWeight.bold, fontSize: 18)),
        const Text("Scan a student QR stub to initiate the PayMongo gateway.",
            style: TextStyle(color: Colors.blueGrey)),
      ],
    );
  }

  Widget _infoRow(String l, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(v,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
      );

  void _showToast(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}
