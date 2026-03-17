import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../services/supabase_service.dart';

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const FeeManagementPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isProcessing = false;

  // ==========================================
  // 🔑 PAYMONGO API CONFIGURATION
  // ==========================================
  static const String _paymongoSecretKey = 'sk_test_tHDd4rEX19bAfNmdz9WSC6Tj';
  static const String _successUrl = 'https://pay.paymongo.com/success';
  static const String _cancelUrl = 'https://pay.paymongo.com/cancel';

  String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_paymongoSecretKey:'))}';
  // ==========================================

  // Status Tracking for Online Payments
  StreamSubscription? _paymentSubscription;
  Timer? _pollingTimer;
  String? _activeCheckoutSessionId;

  // Theme Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// 📷 STEP 1: OPEN SCANNER
  Future<void> _openClaimScanner() async {
    if (_isProcessing) return;

    var res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
    );

    if (res is String && res != "-1") {
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        await _handleScannedTicket(res);
      }
    }
  }

  /// 🛰️ STEP 2: CLOUD LOOKUP
  Future<void> _handleScannedTicket(String hash) async {
    try {
      final result = await _service.client
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

      if (result['payment_status'] == 'Paid') {
        _showToast("This request has already been paid.", Colors.orangeAccent);
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

  /// 💳 STEP 3: OMNICHANNEL PAYMENT PORTAL
  void _showPaymentPortal(Map<String, dynamic> req) {
    final profile = req['profiles'] as Map<String, dynamic>?;
    final double amount = double.tryParse(req['amount_due'].toString()) ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: true,
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
            _infoRow("Student Name:",
                "${profile?['fn'] ?? 'Unknown'} ${profile?['ln'] ?? ''}"),
            _infoRow("ID Number:", profile?['user_id_number'] ?? "N/A"),
            const Divider(height: 48, color: Colors.white10),
            _infoRow("Service:", req['request_type'] ?? "Document"),
            _infoRow("Amount:", "₱${amount.toStringAsFixed(2)}",
                color: success),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(cxt);
                      _processCashPayment(req);
                    },
                    icon: const Icon(LucideIcons.banknote),
                    label: const Text("CASH"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success.withOpacity(0.15),
                      foregroundColor: success,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(cxt);
                      _processOnlinePayment(req);
                    },
                    icon: const Icon(LucideIcons.creditCard),
                    label: const Text("ONLINE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 💵 FLOW: PHYSICAL CASH PAYMENT
  void _processCashPayment(Map<String, dynamic> request) {
    final TextEditingController cashController = TextEditingController();
    final double amountDue =
        double.tryParse(request['amount_due'].toString()) ?? 0.0;
    final String studentName =
        "${request['profiles']?['fn'] ?? 'Student'} ${request['profiles']?['ln'] ?? ''}";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        double cashReceived = double.tryParse(cashController.text) ?? 0.0;
        double change = cashReceived - amountDue;
        bool canProcess = cashReceived >= amountDue;

        return AlertDialog(
          backgroundColor: surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text("Cash Collection",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(studentName, style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 16),
              Text("Total Due: ₱${amountDue.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: success,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: cashController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                onChanged: (v) => setModalState(() {}),
                decoration: InputDecoration(
                  labelText: "Cash Received",
                  prefixText: "₱ ",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              if (cashReceived > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: (change >= 0 ? success : Colors.redAccent)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(change >= 0 ? "Change:" : "Insufficient:",
                          style: TextStyle(
                              color: change >= 0 ? success : Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                      Text("₱${change.abs().toStringAsFixed(2)}",
                          style: TextStyle(
                              color: change >= 0 ? success : Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: !canProcess
                  ? null
                  : () => _finalizeTransaction(request, method: 'Cash'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: success, foregroundColor: Colors.black),
              child: const Text("COMPLETE PAYMENT"),
            ),
          ],
        );
      }),
    );
  }

  /// 💳 FLOW: ONLINE PAYMONGO GATEWAY
  Future<void> _processOnlinePayment(Map<String, dynamic> request) async {
    final String studentName =
        "${request['profiles']?['fn'] ?? 'Student'} ${request['profiles']?['ln'] ?? ''}";
    final double amountDue =
        double.tryParse(request['amount_due'].toString()) ?? 0.0;

    _showProcessingOverlay();

    try {
      final response = await http.post(
        Uri.parse('https://api.paymongo.com/v1/checkout_sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader
        },
        body: jsonEncode({
          "data": {
            "attributes": {
              "send_email_receipt": true,
              "show_description": true,
              "description": "UEMS Document Request Fee",
              "line_items": [
                {
                  "currency": "PHP",
                  "amount": (amountDue * 100).toInt(),
                  "description": "Request: ${request['request_type']}",
                  "name": "Document Fee - $studentName",
                  "quantity": 1
                }
              ],
              "payment_method_types": ["gcash", "paymaya", "card"],
              "success_url": _successUrl,
              "cancel_url": _cancelUrl
            }
          }
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _activeCheckoutSessionId = result['data']['id'];
        final String checkoutUrl = result['data']['attributes']['checkout_url'];

        // Mark status in DB to Processing
        await _service.client
            .from('office_requests')
            .update({'status': 'Processing Payment'})
            .eq('id', request['id'])
            .select();

        if (mounted) Navigator.pop(context); // Close processing overlay

        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
          _startHybridMonitoring(request);
        }
      } else {
        throw Exception(result['errors'][0]['detail']);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showToast("Gateway Error: $e", Colors.redAccent);
    }
  }

  void _startHybridMonitoring(Map<String, dynamic> request) {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    _showAwaitingPaymentDialog(request);

    _paymentSubscription = _service.client
        .from('office_requests')
        .stream(primaryKey: ['id'])
        .eq('id', request['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty &&
              data.first['payment_status'].toString().toLowerCase() == 'paid') {
            _stopMonitoringAndFinalize(data.first);
          }
        });

    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_activeCheckoutSessionId == null) return;
      try {
        final checkUrl =
            'https://api.paymongo.com/v1/checkout_sessions/$_activeCheckoutSessionId';
        final response = await http
            .get(Uri.parse(checkUrl), headers: {'Authorization': _authHeader});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String status =
              data['data']['attributes']['status'].toString().toLowerCase();
          final List payments = data['data']['attributes']['payments'] ?? [];

          if (status == 'paid' || payments.isNotEmpty) {
            _stopMonitoringAndFinalize(Map<String, dynamic>.from(request)
              ..addAll({'payment_status': 'Paid'}));
          }
        }
      } catch (e) {
        debugPrint("Polling Error: $e");
      }
    });
  }

  void _stopMonitoringAndFinalize(Map<String, dynamic> request) {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    _activeCheckoutSessionId = null;

    // Safety check to prevent popping the main view and causing a black screen
    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pop(); // Close the "Awaiting Payment" dialog specifically
      _finalizeTransaction(request, method: 'Online');
    }
  }

  /// 🛰️ FINALIZATION: SHARED DATABASE UPDATE
  Future<void> _finalizeTransaction(Map<String, dynamic> request,
      {required String method}) async {
    // DO NOT POP HERE. Pop the source dialogs before calling this if possible.

    setState(() => _isProcessing = true);
    try {
      // 1. Database Update
      await _service.client
          .from('office_requests')
          .update({
            'payment_status': 'Paid',
            'status': 'Processing Request',
            'paid_at': DateTime.now().toIso8601String(),
            'remarks':
                "${request['remarks'] ?? ''} | Paid via $method | Verified by ${widget.userData['ln']}",
          })
          .eq('id', request['id'])
          .select();

      if (mounted) {
        setState(() => _isProcessing = false);
        // 2. Success Feedback UI (The Fix for the Black Screen)
        _showSuccessDialog(request, method);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Sync Error: $e", Colors.redAccent);
      }
    }
  }

  // --- UI COMPLETION DIALOG ---

  void _showSuccessDialog(Map<String, dynamic> request, String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: success.withOpacity(0.1), shape: BoxShape.circle),
              child:
                  const Icon(LucideIcons.checkCircle, color: success, size: 64),
            ),
            const SizedBox(height: 24),
            Text("Payment Verified",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              "The transaction has been recorded via $method.\n\n"
              "Reference: ${request['qr_hash']}\n"
              "Status: RELEASE PENDING",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Divider(height: 48, color: Colors.white10),
            const Text(
              "Academic records have been updated. The student is now cleared for Registrar release.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Text("CLOSE TERMINAL",
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                      "Scan a request QR to process payment and release documents.",
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
            Text("Document Collections Node",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            const Text(
                "Integrated with PayMongo Gateway and Physical Cash Ledger.",
                style: TextStyle(color: Colors.blueGrey)),
          ]),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _openClaimScanner,
            icon: const Icon(LucideIcons.scanLine),
            label: const Text("ACTIVATE SCANNER"),
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

  void _showAwaitingPaymentDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: success),
            const SizedBox(height: 32),
            const Text("Monitoring Transaction",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Text("Online payment session active in browser.",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _manualCheck(request),
              style: ElevatedButton.styleFrom(backgroundColor: aViolet),
              child: const Text("FORCE SYNC"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manualCheck(Map<String, dynamic> request) async {
    if (_activeCheckoutSessionId == null) return;
    try {
      final res = await http.get(
          Uri.parse(
              'https://api.paymongo.com/v1/checkout_sessions/$_activeCheckoutSessionId'),
          headers: {'Authorization': _authHeader});
      final data = jsonDecode(res.body);
      if (data['data']['attributes']['status'] == 'paid') {
        _stopMonitoringAndFinalize(request);
      } else {
        _showToast(
            "Payment not yet confirmed by gateway.", Colors.orangeAccent);
      }
    } catch (e) {
      _showToast("Check failed: $e", Colors.redAccent);
    }
  }

  void _showProcessingOverlay() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) =>
            const Center(child: CircularProgressIndicator(color: aViolet)));
  }

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
