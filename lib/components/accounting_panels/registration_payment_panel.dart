import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';

class RegistrationPaymentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const RegistrationPaymentPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<RegistrationPaymentPanel> createState() =>
      _RegistrationPaymentPanelState();
}

class _RegistrationPaymentPanelState extends State<RegistrationPaymentPanel> {
  final SupabaseService _service = SupabaseService();

  // ==========================================
  // 🔑 PAYMONGO API CONFIGURATION
  // ==========================================
  static const String _paymongoSecretKey = 'sk_test_tHDd4rEX19bAfNmdz9WSC6Tj';
  static const String _successUrl = 'https://pay.paymongo.com/success';
  static const String _cancelUrl = 'https://pay.paymongo.com/cancel';

  String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_paymongoSecretKey:'))}';
  // ==========================================

  List<Map<String, dynamic>> _pendingRegistrations = [];
  bool _isLoading = true;

  // Status Tracking
  StreamSubscription? _paymentSubscription;
  Timer? _pollingTimer;
  String? _activeCheckoutSessionId;

  @override
  void initState() {
    super.initState();
    _fetchPendingPayments();
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// 🛰️ DATABASE: Fetch applicants released by Admissions
  Future<void> _fetchPendingPayments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('office_requests')
          .select('*')
          .eq('request_type', 'Registration Fee')
          .eq('status', 'Pending Payment')
          .order('date_applied', ascending: false);

      if (mounted) {
        setState(() {
          _pendingRegistrations = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Accounting Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 💵 PHYSICAL PAYMENT: Logic for handling cash transactions
  void _processCashPayment(Map<String, dynamic> request) {
    final TextEditingController cashController = TextEditingController();
    final double amountDue =
        double.tryParse(request['amount_due'].toString()) ?? 2000.0;
    final String applicantName = request['remarks'].toString().split('. ')[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        double cashReceived = double.tryParse(cashController.text) ?? 0.0;
        double change = cashReceived - amountDue;
        bool canProcess = cashReceived >= amountDue;

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(LucideIcons.banknote, color: Color(0xFF69F0AE)),
              const SizedBox(width: 12),
              Text("Cash Payment Entry",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Process physical payment for:",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text(applicantName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Divider(height: 32, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Amount Due:",
                      style: TextStyle(
                          color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  Text("₱${amountDue.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: cashController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                onChanged: (v) => setModalState(() {}),
                decoration: InputDecoration(
                  labelText: "Cash Received",
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  prefixText: "₱ ",
                  prefixStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (change >= 0 ? const Color(0xFF69F0AE) : Colors.redAccent)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        change >= 0
                            ? "Change to Return:"
                            : "Remaining Balance:",
                        style: TextStyle(
                            color: change >= 0
                                ? const Color(0xFF69F0AE)
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text("₱${change.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                            color: change >= 0
                                ? const Color(0xFF69F0AE)
                                : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
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
                  : () async {
                      Navigator.pop(context);
                      await _finalizeTransaction(request, method: 'Cash');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("CONFIRM & RELEASE",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  /// 🛰️ DATABASE: Shared logic to finalize the 'Paid' status and handover to Registrar
  Future<void> _finalizeTransaction(Map<String, dynamic> request,
      {required String method}) async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Financial Request
      await _service.client.from('office_requests').update({
        'status': 'Paid',
        'payment_status': 'Paid',
        'paid_at': DateTime.now().toIso8601String(),
        'remarks': "${request['remarks']} | Paid via $method",
      }).eq('id', request['id']);

      // 2. Link back to Applicants table
      final String refNo = request['qr_hash'].toString().split('-')[1];
      await _service.client.from('applicants').update(
          {'status': 'Ready for Registration'}).eq('application_no', refNo);

      await _fetchPendingPayments();
      _showSuccess(
          "Payment ($method) Verified! Applicant record released to Registrar.");
    } catch (e) {
      _showError("Finalization Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 💳 PAYMONGO API: Create a Checkout Session
  Future<void> _processOnlinePayment(Map<String, dynamic> request) async {
    final String remarks = request['remarks'].toString();
    final String applicantName = remarks.contains('for ')
        ? remarks.split('for ')[1].split('.')[0]
        : "Institutional Applicant";

    _showProcessingDialog();

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
              "show_line_items": true,
              "description": "UEMS Registration Payment",
              "line_items": [
                {
                  "currency": "PHP",
                  "amount": 200000,
                  "description": "Registration Fee for $applicantName",
                  "name": "Institutional Intake Fee",
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

        await _service.client
            .from('office_requests')
            .update({'status': 'Processing Payment'}).eq('id', request['id']);

        if (mounted) Navigator.pop(context);

        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
          _startHybridMonitoring(request);
        }
      } else {
        throw Exception("Gateway Error: ${result['errors'][0]['detail']}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Online Gateway Error: $e");
    }
  }

  /// 🛰️ MONITORING ENGINE: Webhook/Stream Listener + Active API Polling
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
              data.first['status'].toString().toLowerCase() == 'paid') {
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
          final String paymongoStatus =
              data['data']['attributes']['status'].toString().toLowerCase();
          final List payments = data['data']['attributes']['payments'] ?? [];

          if (paymongoStatus == 'paid' || payments.isNotEmpty) {
            _stopMonitoringAndFinalize(
                Map<String, dynamic>.from(request)..addAll({'status': 'Paid'}));
          }
        }
      } catch (e) {
        debugPrint("Polling Error: $e");
      }
    });
  }

  void _stopMonitoringAndFinalize(Map<String, dynamic> request) {
    if (_pollingTimer == null && _paymentSubscription == null) return;

    _paymentSubscription?.cancel();
    _pollingTimer?.cancel();
    _paymentSubscription = null;
    _pollingTimer = null;
    _activeCheckoutSessionId = null;

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _handleSuccessfulOnlinePayment(request);
    }
  }

  Future<void> _handleSuccessfulOnlinePayment(
      Map<String, dynamic> request) async {
    try {
      final String refNo = request['qr_hash'].toString().split('-')[1];
      await _service.client.from('applicants').update(
          {'status': 'Ready for Registration'}).eq('application_no', refNo);

      // Status update to 'Paid' for online is usually handled by the monitoring logic calling the DB
      _fetchPendingPayments();
      _showSuccess(
          "Online Payment Confirmed! Applicant released to Registrar.");
    } catch (e) {
      _showError("Post-Payment Sync Error: $e");
    }
  }

  void _showAwaitingPaymentDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF69F0AE)),
            const SizedBox(height: 32),
            Text("Monitoring Online Transaction",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
                "Pay in the browser window. This app will auto-close when the payment reflects.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _manualSyncCheck(request),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text("FORCE SYNC STATUS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _paymentSubscription?.cancel();
                _pollingTimer?.cancel();
                Navigator.pop(context);
              },
              child: const Text("CANCEL MONITORING",
                  style: TextStyle(color: Colors.redAccent, fontSize: 11)),
            )
          ],
        ),
      ),
    );
  }

  /// 🛰️ FALLBACK: Forced manual sync
  Future<void> _manualSyncCheck(Map<String, dynamic> request) async {
    if (_activeCheckoutSessionId == null) return;
    try {
      final response = await http.get(
          Uri.parse(
              'https://api.paymongo.com/v1/checkout_sessions/$_activeCheckoutSessionId'),
          headers: {'Authorization': _authHeader});
      final data = jsonDecode(response.body);
      final String currentStatus =
          data['data']['attributes']['status'].toString().toLowerCase();
      final List payments = data['data']['attributes']['payments'] ?? [];

      if (currentStatus == 'paid' || payments.isNotEmpty) {
        await _service.client.from('office_requests').update({
          'status': 'Paid',
          'payment_status': 'Paid',
          'paid_at': DateTime.now().toIso8601String(),
        }).eq('id', request['id']);

        _stopMonitoringAndFinalize(
            Map<String, dynamic>.from(request)..addAll({'status': 'Paid'}));
      } else {
        _showError(
            "Paymongo still reports this transaction as '${currentStatus.toUpperCase()}'.");
      }
    } catch (e) {
      _showError("Check failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Registration Collections",
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -1)),
                const Text(
                    "Automated Online Monitoring & Physical Cash Collection Workflow.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
              ],
            ),
            _statusBadge(
                "OMNICHANNEL PAYMENT ENABLED", const Color(0xFF69F0AE)),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              : _pendingRegistrations.isEmpty
                  ? _buildEmptyState(textColor)
                  : Container(
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _pendingRegistrations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (context, i) {
                          final req = _pendingRegistrations[i];
                          final String name =
                              req['remarks'].toString().split('. ')[0];
                          final String ref =
                              req['qr_hash'].toString().split('-')[1];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(LucideIcons.userPlus,
                                  color: Color(0xFF8B5CF6)),
                            ),
                            title: Text(name,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "REF: $ref • AMOUNT: ₱${req['amount_due']}",
                                style: const TextStyle(
                                    color: Colors.blueGrey, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _processCashPayment(req),
                                  icon: const Icon(LucideIcons.banknote,
                                      size: 16),
                                  label: const Text("CASH"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF69F0AE)
                                        .withOpacity(0.15),
                                    foregroundColor: const Color(0xFF69F0AE),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _processOnlinePayment(req),
                                  icon: const Icon(LucideIcons.creditCard,
                                      size: 16),
                                  label: const Text("ONLINE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color t) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox,
                size: 48,
                color: widget.isDarkMode
                    ? t.withOpacity(0.1)
                    : Colors.black
                        .withOpacity(0.1)), // Ensure visibility in light mode
            const SizedBox(height: 16),
            const Text("All registration fees processed.",
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );

  Widget _statusBadge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
      );

  void _showProcessingDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
            backgroundColor: Color(0xFF1E1B4B),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 20),
              Text("Launching Gateway...",
                  style: TextStyle(color: Colors.white))
            ])));
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.greenAccent));
}
