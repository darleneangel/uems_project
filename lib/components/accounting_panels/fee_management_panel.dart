import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../services/supabase_service.dart';

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const FeeManagementPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isProcessing = false;

  // ─── PayMongo Configuration ───────────────
  static const String _paymongoSecretKey = 'sk_test_tHDd4rEX19bAfNmdz9WSC6Tj';
  static const String _successUrl = 'https://pay.paymongo.com/success';
  static const String _cancelUrl = 'https://pay.paymongo.com/cancel';

  String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_paymongoSecretKey:'))}';

  // ─── Payment Session Tracking ─────────────
  StreamSubscription? _paymentSubscription;
  Timer? _pollingTimer;
  String? _activeCheckoutSessionId;
  bool _isPollingDialogOpen = false;

  // ─── Theme ────────────────────────────────
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STEP 1: SCANNER — wrapped in a custom Scaffold
  // so the user always has a back button to return
  // ─────────────────────────────────────────────
  Future<void> _openClaimScanner() async {
    if (_isProcessing) return;

    // Push a custom wrapper page so we control the AppBar
    // and can always navigate back to the system.
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _ScannerPage(isDarkMode: widget.isDarkMode),
      ),
    );

    // result is null when the user pressed Back without scanning
    if (result == null || result == '-1' || result.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) await _handleScannedTicket(result.trim());
  }

  // ─────────────────────────────────────────────
  // STEP 2: CLOUD LOOKUP
  // ─────────────────────────────────────────────
  Future<void> _handleScannedTicket(String hash) async {
    try {
      final result = await _service.client.from('office_requests').select('''
            *,
            profiles!office_requests_student_id_fkey(
              *,
              student_details(
                *,
                courses(name),
                year_levels(definition)
              )
            )
          ''').eq('qr_hash', hash).maybeSingle();

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
      debugPrint("Fee Management Sync Error: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Database Sync Error. Please retry.", Colors.redAccent);
      }
    }
  }

  // ─────────────────────────────────────────────
  // STEP 3: PAYMENT PORTAL DIALOG
  // ─────────────────────────────────────────────
  void _showPaymentPortal(Map<String, dynamic> req) {
    final profile = req['profiles'] as Map<String, dynamic>?;
    final details = profile?['student_details'] as Map<String, dynamic>?;
    final double amount =
        double.tryParse(req['amount_due']?.toString() ?? "0.0") ?? 0.0;

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
            _infoRow("Student:",
                "${profile?['fn'] ?? 'Unknown'} ${profile?['ln'] ?? ''}"),
            _infoRow("ID Number:", profile?['user_id_number'] ?? "N/A"),
            _infoRow("Course:",
                "${details?['courses']?['name'] ?? 'N/A'} — ${details?['year_levels']?['definition'] ?? 'N/A'}"),
            const Divider(height: 36, color: Colors.white10),
            _infoRow("Document:", req['request_type'] ?? "Document"),
            _infoRow("Amount Due:", "₱${amount.toStringAsFixed(2)}",
                color: success),
            const SizedBox(height: 32),
            Row(children: [
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
            ]),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CASH PAYMENT FLOW
  // ─────────────────────────────────────────────
  void _processCashPayment(Map<String, dynamic> request) {
    final TextEditingController cashController = TextEditingController();
    final double amountDue =
        double.tryParse(request['amount_due']?.toString() ?? "0.0") ?? 0.0;
    final String studentName =
        "${request['profiles']?['fn'] ?? 'Student'} ${request['profiles']?['ln'] ?? ''}";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double cashReceived = double.tryParse(cashController.text) ?? 0.0;
          double change = cashReceived - amountDue;
          bool canProcess = cashReceived >= amountDue;

          return AlertDialog(
            backgroundColor: surfaceDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text("Cash Collection",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(studentName,
                    style: const TextStyle(color: Colors.blueGrey)),
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
                    labelStyle: const TextStyle(color: Colors.blueGrey),
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
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.blueGrey))),
              ElevatedButton(
                onPressed: !canProcess
                    ? null
                    : () {
                        Navigator.pop(context);
                        _finalizeTransaction(request, method: 'Cash');
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: success, foregroundColor: Colors.black),
                child: const Text("COMPLETE PAYMENT",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ONLINE PAYMENT — PAYMONGO
  // ─────────────────────────────────────────────
  Future<void> _processOnlinePayment(Map<String, dynamic> request) async {
    final profile = request['profiles'] as Map<String, dynamic>?;
    final String studentName =
        "${profile?['fn'] ?? 'Student'} ${profile?['ln'] ?? ''}";
    final String studentId = profile?['user_id_number'] ?? 'N/A';
    final double amountDue =
        double.tryParse(request['amount_due']?.toString() ?? "0.0") ?? 0.0;
    final String docType = request['request_type'] ?? 'Document';

    _showProcessingOverlay();

    try {
      final response = await http.post(
        Uri.parse('https://api.paymongo.com/v1/checkout_sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode({
          "data": {
            "attributes": {
              "send_email_receipt": true,
              "show_description": true,
              "description": "Document Request Fee — $studentName ($studentId)",
              "line_items": [
                {
                  "currency": "PHP",
                  "amount": (amountDue * 100).toInt(),
                  "description": "$docType — $studentName (ID: $studentId)",
                  "name": "Document Fee",
                  "quantity": 1,
                }
              ],
              "payment_method_types": ["gcash", "paymaya", "card"],
              "success_url": _successUrl,
              "cancel_url": _cancelUrl,
            }
          }
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _activeCheckoutSessionId = result['data']['id'];
        final String checkoutUrl = result['data']['attributes']['checkout_url'];

        await _service.client
            .from('office_requests')
            .update({'status': 'Processing Payment'}).eq('id', request['id']);

        if (mounted) Navigator.pop(context); // close processing overlay

        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
          _startHybridMonitoring(request);
        }
      } else {
        throw Exception(
            result['errors']?[0]['detail'] ?? "Payment session failed.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showToast("Gateway Error: $e", Colors.redAccent);
    }
  }

  // ─────────────────────────────────────────────
  // HYBRID MONITORING — Supabase stream + polling
  // ─────────────────────────────────────────────
  void _startHybridMonitoring(Map<String, dynamic> request) {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    _showAwaitingPaymentDialog(request);

    // Realtime stream from Supabase
    _paymentSubscription = _service.client
        .from('office_requests')
        .stream(primaryKey: ['id'])
        .eq('id', request['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty &&
              data.first['payment_status']?.toString().toLowerCase() ==
                  'paid') {
            _stopMonitoringAndFinalize(data.first);
          }
        });

    // Fallback: poll PayMongo directly every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_activeCheckoutSessionId == null) return;
      try {
        final res = await http.get(
            Uri.parse(
                'https://api.paymongo.com/v1/checkout_sessions/$_activeCheckoutSessionId'),
            headers: {'Authorization': _authHeader});

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final String status =
              data['data']['attributes']['status'].toString().toLowerCase();
          final List payments = data['data']['attributes']['payments'] ?? [];

          if (status == 'paid' || payments.isNotEmpty) {
            timer.cancel();
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

    if (mounted) {
      if (_isPollingDialogOpen) {
        _isPollingDialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      _finalizeTransaction(request, method: 'Online (Paymongo)');
    }
  }

  // ─────────────────────────────────────────────
  // FINALIZE TRANSACTION
  // Updates DB, generates receipt PDF, shows modal
  // ─────────────────────────────────────────────
  Future<void> _finalizeTransaction(Map<String, dynamic> request,
      {required String method}) async {
    setState(() => _isProcessing = true);
    try {
      final String refNo = 'OR-${DateTime.now().millisecondsSinceEpoch}';

      await _service.client.from('office_requests').update({
        'payment_status': 'Paid',
        'status': 'Processing Request',
        'paid_at': DateTime.now().toIso8601String(),
        'remarks':
            "${request['remarks'] ?? ''} | Paid via $method | Verified by ${widget.userData['ln']} | Ref: $refNo",
      }).eq('id', request['id']);

      // Generate and open PDF receipt
      await _generateReceiptPDF(request, method, refNo);

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(request, method, refNo);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Sync Error: $e", Colors.redAccent);
      }
    }
  }

  // ─────────────────────────────────────────────
  // GENERATE RECEIPT PDF
  // Includes: student name, ID, course, date,
  // document requested, payment method, amount
  // ─────────────────────────────────────────────
  Future<void> _generateReceiptPDF(
      Map<String, dynamic> request, String method, String refNo) async {
    final pdf = pw.Document();
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();

    // Safely pull student data
    final profile = request['profiles'] as Map<String, dynamic>?;
    final details = profile?['student_details'] as Map<String, dynamic>?;

    final String studentName =
        "${(profile?['fn'] ?? '').toString().toUpperCase()} ${(profile?['ln'] ?? '').toString().toUpperCase()}";
    final String studentId = profile?['user_id_number'] ?? 'N/A';
    final String course = details?['courses']?['name'] ?? 'N/A';
    final String yearLevel = details?['year_levels']?['definition'] ?? 'N/A';
    final String docType = request['request_type'] ?? 'Document Request';
    final double amountDue =
        double.tryParse(request['amount_due']?.toString() ?? "0.0") ?? 0.0;
    final String dateStr =
        DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now());
    final String verifiedBy =
        "${widget.userData['fn'] ?? ''} ${widget.userData['ln'] ?? ''}"
            .toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(28),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              pw.Center(
                  child: pw.Text("BRIGHT FUTURE ACADEMY",
                      style: pw.TextStyle(font: monoBold, fontSize: 13))),
              pw.Center(
                  child: pw.Text("OFFICIAL RECEIPT — DOCUMENT COLLECTION",
                      style: pw.TextStyle(font: mono, fontSize: 8))),
              pw.Center(
                  child: pw.Text("Office of the Registrar / Cashier",
                      style: pw.TextStyle(font: mono, fontSize: 8))),
              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              // ── OR No. & Date ────────────────────────
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("OR NO: $refNo",
                        style: pw.TextStyle(font: monoBold, fontSize: 9)),
                    pw.Text("DATE: $dateStr",
                        style: pw.TextStyle(font: mono, fontSize: 8)),
                  ]),
              pw.SizedBox(height: 10),

              // ── Student Info Block ───────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        width: 0.5, style: pw.BorderStyle.dashed)),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow("STUDENT NAME", studentName, mono, monoBold),
                      pw.SizedBox(height: 3),
                      _pdfInfoRow("STUDENT ID", studentId, mono, monoBold),
                      pw.SizedBox(height: 3),
                      _pdfInfoRow(
                          "COURSE & YEAR", "$course — $yearLevel", mono, mono),
                    ]),
              ),
              pw.SizedBox(height: 8),

              // ── Transaction Details Block ────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        width: 0.5, style: pw.BorderStyle.dashed)),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow(
                          "DOCUMENT REQUESTED", docType, mono, monoBold),
                      pw.SizedBox(height: 3),
                      _pdfInfoRow("PAYMENT METHOD", method, mono, mono),
                      pw.SizedBox(height: 3),
                      _pdfInfoRow("QR REFERENCE", request['qr_hash'] ?? 'N/A',
                          mono, mono),
                    ]),
              ),
              pw.SizedBox(height: 12),

              // ── Amount Lines ─────────────────────────
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _pdfAmountRow("DOCUMENT FEE", amountDue, mono),
              pw.Divider(thickness: 0.5),
              _pdfAmountRow("TOTAL AMOUNT PAID", amountDue, monoBold),
              pw.SizedBox(height: 12),

              // ── Status Box ───────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
                child: pw.Center(
                    child: pw.Text("STATUS: PAID — CLEARED FOR RELEASE",
                        style: pw.TextStyle(font: monoBold, fontSize: 9))),
              ),
              pw.Spacer(),

              // ── Footer ───────────────────────────────
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Verified by: $verifiedBy",
                        style: pw.TextStyle(font: mono, fontSize: 7)),
                    pw.Text("Cashier / Finance Officer",
                        style: pw.TextStyle(font: monoBold, fontSize: 8)),
                  ]),
              pw.SizedBox(height: 4),
              pw.Center(
                  child: pw.Text(
                      "This is an official receipt. Keep this for your records.",
                      style: pw.TextStyle(font: mono, fontSize: 7))),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/Receipt_$refNo.pdf";
    await File(path).writeAsBytes(bytes);
    await OpenFile.open(path);
  }

  /// Two-column label → value row for PDF
  pw.Widget _pdfInfoRow(
          String label, String value, pw.Font labelFont, pw.Font valueFont) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("$label:", style: pw.TextStyle(font: labelFont, fontSize: 8)),
        pw.Flexible(
            child: pw.Text(value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: valueFont, fontSize: 8))),
      ]);

  /// Amount line for PDF
  pw.Widget _pdfAmountRow(String label, double value, pw.Font f) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(font: f, fontSize: 8)),
            pw.Text(NumberFormat('#,###.00').format(value),
                style: pw.TextStyle(font: f, fontSize: 8)),
          ]));

  // ─────────────────────────────────────────────
  // SUCCESS DIALOG
  // ─────────────────────────────────────────────
  void _showSuccessDialog(
      Map<String, dynamic> request, String method, String refNo) {
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
              "Transaction recorded via $method.\n\n"
              "Reference: $refNo\n"
              "QR Hash: ${request['qr_hash'] ?? 'N/A'}\n"
              "Status: CLEARED FOR RELEASE",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Divider(height: 48, color: Colors.white10),
            const Text(
              "Receipt PDF has been generated and opened. The student is now cleared for Registrar release.",
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
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Text("DONE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
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
                  const Column(children: [
                    CircularProgressIndicator(color: aViolet),
                    SizedBox(height: 16),
                    Text("Processing...",
                        style: TextStyle(color: Colors.blueGrey)),
                  ])
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
                  const SizedBox(height: 8),
                  const Text(
                      "Scan a request QR to process payment and release documents.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey)),
                ],
              ],
            ),
          ),
        ),
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
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ),
        ]),
      );

  void _showAwaitingPaymentDialog(Map<String, dynamic> request) {
    _isPollingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _manualCheck(request),
                    style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                    child: const Text("FORCE SYNC"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _paymentSubscription?.cancel();
                      _pollingTimer?.cancel();
                      _activeCheckoutSessionId = null;
                      if (_isPollingDialogOpen) {
                        _isPollingDialogOpen = false;
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10),
                    child: const Text("CANCEL"),
                  ),
                ),
              ],
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
      _showToast("Sync check failed: $e", Colors.redAccent);
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

// ─────────────────────────────────────────────
// SCANNER PAGE WRAPPER
// Wraps SimpleBarcodeScannerPage in a custom
// Scaffold so the user always has a back button
// to return to the system without scanning.
// ─────────────────────────────────────────────
// SimpleBarcodeScannerPage pops itself with the scanned string via its
// own internal Navigator.pop call. We cannot intercept it with a callback,
// so instead we push it as a nested route from inside _ScannerPage and
// relay whatever it returns back up to FeeManagementPanel._openClaimScanner.
class _ScannerPage extends StatefulWidget {
  final bool isDarkMode;
  const _ScannerPage({required this.isDarkMode});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame so the Scaffold is fully built before we push
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchScanner());
  }

  Future<void> _launchScanner() async {
    if (_launched) return;
    _launched = true;

    // Push the real scanner as a sub-route. It calls Navigator.pop(ctx, value)
    // internally when it scans, which returns here as `result`.
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (!mounted) return;

    // Relay the result (scanned string or null/-1 for back) up to the caller
    Navigator.of(context).pop(result is String ? result : null);
  }

  @override
  Widget build(BuildContext context) {
    // This scaffold is shown only for the brief moment before the scanner
    // sub-route pushes on top. It provides the back button at all times.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        title: const Text(
          "Scan QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: "Back to System",
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Point camera at QR",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 16),
            Text("Opening camera...", style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
