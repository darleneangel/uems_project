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
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../services/supabase_service.dart';

/// CUSTOM CONVERTER CLASS
class ListToCsvConverter {
  const ListToCsvConverter();
  String convert(List<List<dynamic>> rows) {
    if (rows.isEmpty) return "";
    return rows.map((row) {
      return row.map((item) {
        String value = item?.toString() ?? "";
        if (value.contains(',') ||
            value.contains('\n') ||
            value.contains('"')) {
          value = '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(',');
    }).join('\n');
  }
}

class StudentPaymentPortal extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const StudentPaymentPortal({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<StudentPaymentPortal> createState() => _StudentPaymentPortalState();
}

class _StudentPaymentPortalState extends State<StudentPaymentPortal> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cashReceivedController = TextEditingController();
  final TextEditingController _parentNameController =
      TextEditingController(); // New
  final TextEditingController _notesController = TextEditingController(); // New

  bool _isLoading = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _activeStudent;
  Map<String, dynamic>? _billingBreakdown;
  List<Map<String, dynamic>> _ledgerEntries = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF0F071D);
  // ==========================================
  // 🔑 API & SMTP CONFIGURATION
  // ==========================================
  static const String _paymongoSecretKey = 'sk_test_tHDd4rEX19bAfNmdz9WSC6Tj';
  static const String _successUrl = 'https://pay.paymongo.com/success';
  static const String _cancelUrl = 'https://pay.paymongo.com/cancel';
  static const String _senderEmail = 'bright.future.academyUEMSSP@gmail.com';
  static const String _appPassword = 'jnea wnbk atjg gyqi';

  String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_paymongoSecretKey:'))}';
  // ==========================================

  final String _selectedSemester = '2nd Semester 2025-2026';
  String _paymentPlan = 'Installment';
  String _paymentMethod = 'Cash';
  double _lateSurcharge = 0.0;
  double _officialAssessmentTotal = 0.0;
  double _scholarshipDiscount = 0.0;
  DateTime? _promissoryDueDate; // New

  String? _activeCheckoutSessionId;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    _amountController.dispose();
    _cashReceivedController.dispose();
    _parentNameController.dispose(); // New
    _notesController.dispose(); // New
    super.dispose();
  }

  void _updateCalculatedAmount() {
    if (_activeStudent == null || _paymentPlan == 'Promissory Note') {
      return; // Added condition
    }
    final double balance = double.tryParse(_activeStudent!['student_details']
                    ?['account_balance']
                ?.toString() ??
            "0") ??
        0.0;
    double targetAmount = 0.0;
    _lateSurcharge = 0.0;

    if (_paymentPlan == 'Full Payment') {
      targetAmount = balance;
    } else if (_paymentPlan == 'Installment') {
      // Assuming _officialAssessmentTotal and _scholarshipDiscount are correctly set
      // from the student's assessment record.
      double baseTranche =
          (_officialAssessmentTotal - _scholarshipDiscount) / 4;
      targetAmount = baseTranche;
    } else {
      return;
    }
    setState(() {
      _amountController.text = targetAmount.toStringAsFixed(2);
    });
  }

  Future<void> _fetchStudentLedger() async {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final student = await _service.client
          .from('profiles')
          .select(
              '*, student_details(*, courses(name), year_levels(definition))') // Added year_levels(definition)
          .eq('role', 'student')
          .ilike('user_id_number', term)
          .maybeSingle();
      if (student == null) {
        _showToast("Student not found.", Colors.orangeAccent);
        setState(() => _isLoading = false);
        return;
      }
      final assessmentRecord = await _service.client
          .from('payments')
          .select()
          .eq('student_id', student['id'])
          .eq('payment_type', 'Enrollment Assessment')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final paymentsRes = await _service.client
          .from('payments')
          .select('*')
          .eq('student_id', student['id'])
          .order('created_at', ascending: false);
      final details = student['student_details'];
      double officialTotal = double.tryParse(
              details?['total_assessment']?.toString() ?? "35000") ??
          35000.0;
      double discount = double.tryParse(
              details?['scholarship_discount']?.toString() ?? "0") ??
          0.0;
      Map<String, dynamic>? decodedBreakdown;
      if (assessmentRecord != null && assessmentRecord['remarks'] != null) {
        try {
          decodedBreakdown = jsonDecode(assessmentRecord['remarks']);
        } catch (e) {
          debugPrint("JSON Decode Error");
        }
      }
      setState(() {
        _activeStudent = student;
        _billingBreakdown = decodedBreakdown;
        _officialAssessmentTotal = officialTotal;
        _scholarshipDiscount = discount;
        _ledgerEntries = List<Map<String, dynamic>>.from(paymentsRes);
        _isLoading = false;
      });
      _updateCalculatedAmount();
    } catch (e) {
      _showToast("Sync Error: Check your database schema.", Colors.redAccent);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ FUNCTION: Grant Institutional Financial Clearance
  Future<void> _grantClearance() async {
    if (_activeStudent == null) return;
    setState(() => _isProcessing = true);
    try {
      await _service.client.from('student_details').update({
        'enrollment_status': 'Cleared',
        'accounting_clearance_date': DateTime.now().toIso8601String(),
        'accounting_cleared_by': widget.userData['id']
      }).eq('profile_id', _activeStudent!['id']);

      _showToast("Student successfully cleared for institutional activities.",
          success);
      _fetchStudentLedger();
    } catch (e) {
      _showToast("Clearance Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// 🛰️ FUNCTION: Generate professional Statement of Account (SOA)
  Future<void> _generateSOA() async {
    if (_activeStudent == null) return;
    final pdf = pw.Document();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final balance = double.tryParse(_activeStudent!['student_details']
                    ?['account_balance']
                ?.toString() ??
            "0") ??
        0.0;

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                      child: pw.Text("BRIGHT FUTURE ACADEMY",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 18))),
                  pw.Center(
                      child: pw.Text("STATEMENT OF ACCOUNT",
                          style: const pw.TextStyle(fontSize: 12))),
                  pw.SizedBox(height: 30),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  "STUDENT: ${_activeStudent!['fn']} ${_activeStudent!['ln']}"
                                      .toUpperCase(),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  "ID NO: ${_activeStudent!['user_id_number']}"),
                              pw.Text(
                                  "COURSE: ${_activeStudent!['student_details']?['courses']?['name'] ?? 'N/A'}"),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("DATE: $date"),
                              pw.Text("TERM: $_selectedSemester"),
                            ])
                      ]),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text("ASSESSMENT BREAKDOWN",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 10),
                  _soaRow("Tuition Fee", _billingBreakdown?['tuition'] ?? 0.0),
                  _soaRow(
                      "Laboratory Fee", _billingBreakdown?['lab_fee'] ?? 0.0),
                  _soaRow("Scholarship/Discounts", -_scholarshipDiscount),
                  pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  _soaRow("TOTAL ASSESSMENT",
                      _officialAssessmentTotal - _scholarshipDiscount,
                      isBold: true),
                  pw.SizedBox(height: 20),
                  pw.Text("PAYMENT HISTORY",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 10),
                  ..._ledgerEntries.take(10).map((e) => _soaRow(
                      DateFormat('MM/dd/yyyy')
                          .format(DateTime.parse(e['created_at'])),
                      -(double.tryParse((e['amount_paid'] ?? e['amount'] ?? "0")
                              .toString()) ??
                          0.0))),
                  pw.Spacer(),
                  pw.Divider(),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("TOTAL REMAINING BALANCE:",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text(
                            "PHP ${NumberFormat('#,###.00').format(balance)}",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ]),
                ]))));

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/SOA_${_activeStudent!['user_id_number']}.pdf";
    final file = File(path);
    await file.writeAsBytes(bytes);
    await OpenFile.open(path);
  }

  pw.Widget _soaRow(String label, dynamic val, {bool isBold = false}) =>
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: isBold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
                pw.Text(
                    NumberFormat('#,###.00').format(double.tryParse(val.toString()) ?? 0.0),
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: isBold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
              ]));

  Future<void> _processOnlinePayment() async {
    if (_activeStudent == null) return;
    final double payAmount = double.tryParse(_amountController.text) ?? 0;
    if (payAmount < 100) {
      _showToast("Minimum ₱100.00 for online.", Colors.orangeAccent);
      return;
    }
    _showLoadingGateway();
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
              "description": "Tuition ($_paymentPlan) - Institutional Payment",
              "line_items": [
                {
                  "currency": "PHP",
                  "amount": (payAmount * 100).toInt(),
                  "description":
                      "Tuition for ${_activeStudent!['fn'] ?? ''} ${_activeStudent!['ln'] ?? ''}",
                  "name": "BFA Academic Fees",
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
        if (mounted) Navigator.pop(context);
        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
          _startPaymentPolling(payAmount);
        }
      } else {
        throw Exception(result['errors']?[0]['detail'] ?? "Payment Failure");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showToast("Gateway Error: $e", Colors.redAccent);
    }
  }

  void _startPaymentPolling(double amount) {
    _pollingTimer?.cancel();
    _showPollingDialog();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_activeCheckoutSessionId == null) return;
      try {
        final response = await http.get(
            Uri.parse(
                'https://api.paymongo.com/v1/checkout_sessions/$_activeCheckoutSessionId'),
            headers: {'Authorization': _authHeader});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String sessionStatus = data['data']['attributes']['status'];
          final List payments = data['data']['attributes']['payments'] ?? [];

          if (sessionStatus == 'paid' || payments.isNotEmpty) {
            timer.cancel();
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pop();
              await _finalizeTransaction(amount, method: 'Online (Paymongo)');
            }
          }
        }
      } catch (e) {
        debugPrint("Polling Sync Error: $e");
      }
    });
  }

  Future<void> _processCashDisbursement() async {
    final double payAmount = double.tryParse(_amountController.text) ?? 0;
    final double received = double.tryParse(_cashReceivedController.text) ?? 0;
    if (payAmount <= 0) return;
    if (received < payAmount) {
      _showToast("Insufficient cash.", Colors.orangeAccent);
      return;
    }
    final double change = received - payAmount;
    _showCashSummary(payAmount, received, change);
  }

  Future<void> _finalizeTransaction(double payAmount,
      {required String method}) async {
    setState(() => _isProcessing = true);
    try {
      final double currentBal = double.tryParse(
              _activeStudent!['student_details']?['account_balance']
                      ?.toString() ??
                  "0") ??
          0.0;
      final double newBalance = currentBal - payAmount;

      final txRes = await _service.client
          .from('payments')
          .insert({
            'student_id': _activeStudent!['id'],
            'amount': payAmount,
            'amount_paid': payAmount,
            'payment_method': method,
            'status': 'Success',
            'reference_no': 'OR-${DateTime.now().millisecondsSinceEpoch}',
            'remarks': "Plan: $_paymentPlan | Sem: $_selectedSemester"
          })
          .select()
          .single();

      await _service.updateAccountBalance(_activeStudent!['id'], newBalance);
      await _generateOR(txRes, payAmount, newBalance);
      await _sendEReceiptEmail(
        recipientEmail: _activeStudent!['email'],
        studentName: "${_activeStudent!['fn']} ${_activeStudent!['ln']}",
        referenceNo: txRes['reference_no'],
        amount: payAmount,
        newBalance: newBalance,
      );

      if (mounted) {
        _showSuccessModal(txRes['reference_no'], payAmount, method);
      }
      _clearPromissoryNoteForm(); // Clear promissory note fields if they were used

      _amountController.clear();
      _cashReceivedController.clear();
      _fetchStudentLedger();
    } catch (e) {
      _showToast("Database Reconcile Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessModal(String ref, double amount, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2,
                color: Color(0xFF69F0AE), size: 64),
            const SizedBox(height: 24),
            Text("Payment Successful",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text("Reference: $ref",
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const Divider(height: 32, color: Colors.white10),
            Text("₱${NumberFormat('#,###.00').format(amount)}",
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            Text("Posted via $method",
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6)),
                child: const Text("RETURN TO LEDGER"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _sendEReceiptEmail(
      {required String recipientEmail,
      required String studentName,
      required String referenceNo,
      required double amount,
      required double newBalance}) async {
    final smtpServer = gmail(_senderEmail, _appPassword);
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$referenceNo&margin=10&ecc=H";
    final message = Message()
      ..from = const Address(_senderEmail, 'SSCR Accounting Office')
      ..recipients.add(recipientEmail)
      ..subject = 'Institutional E-Receipt: Tuition Payment Verified'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 40px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 22px;'>OFFICIAL E-RECEIPT</h1>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>$studentName</b>,</p>
            <p>Your payment of <b>PHP ${NumberFormat('#,###.00').format(amount)}</b> has been successfully posted.</p>
            <div style='text-align: center; margin: 30px 0;'>
              <img src='$qrUrl' width='180' height='180' style='border: 4px solid #f1f5f9; border-radius: 12px;' />
              <p style='color: #8B5CF6; font-weight: bold;'>REF: $referenceNo</p>
            </div>
            <p style='font-size: 11px; color: #94a3b8; text-align: center;'>New Balance: PHP ${NumberFormat('#,###.00').format(newBalance)}</p>
          </div>
        </div>
      """;
    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  Future<void> _generateOR(
      Map<String, dynamic> tx, double paid, double remaining) async {
    final pdf = pw.Document();
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();
    final date = DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now());
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                      child: pw.Text("BRIGHT FUTURE ACADEMY",
                          style: pw.TextStyle(font: monoBold, fontSize: 13))),
                  pw.Center(
                      child: pw.Text("OFFICIAL RECEIPT - STUDENT ACCOUNTS",
                          style: pw.TextStyle(font: mono, fontSize: 9))),
                  pw.SizedBox(height: 15),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("OR NO: ${tx['reference_no'] ?? 'N/A'}",
                                  style: pw.TextStyle(font: mono, fontSize: 9)),
                              pw.Text(
                                  "STUDENT: ${(_activeStudent!['fn'] ?? '').toUpperCase()} ${(_activeStudent!['ln'] ?? '').toUpperCase()}",
                                  style: pw.TextStyle(
                                      font: monoBold, fontSize: 9)),
                              pw.Text("PLAN: $_paymentPlan",
                                  style: pw.TextStyle(font: mono, fontSize: 8)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("DATE: $date",
                                  style: pw.TextStyle(font: mono, fontSize: 8)),
                              pw.Text("TERM: $_selectedSemester",
                                  style: pw.TextStyle(font: mono, fontSize: 8)),
                            ])
                      ]),
                  pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  pw.SizedBox(height: 10),
                  _receiptLine("TUITION / ACCOUNTS", paid, mono),
                  pw.Divider(thickness: 0.5),
                  _receiptLine("TOTAL AMOUNT PAID", paid, monoBold),
                  pw.SizedBox(height: 15),
                  pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              width: 0.5, style: pw.BorderStyle.dashed)),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("REMAINING BALANCE:",
                                style:
                                    pw.TextStyle(font: monoBold, fontSize: 9)),
                            pw.Text(
                                "PHP ${NumberFormat('#,###.00').format(remaining)}",
                                style:
                                    pw.TextStyle(font: monoBold, fontSize: 9)),
                          ])),
                  pw.Spacer(),
                  pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text("Finance Officer",
                          style: pw.TextStyle(font: mono, fontSize: 8))),
                ]))));
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/OR_${tx['reference_no'] ?? 'TEMP'}.pdf";
    final file = File(path);
    await file.writeAsBytes(bytes);
    await OpenFile.open(path);
  }

  pw.Widget _receiptLine(String l, double v, pw.Font f) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(l, style: pw.TextStyle(font: f, fontSize: 8)),
            pw.Text(NumberFormat('#,###.00').format(v),
                style: pw.TextStyle(font: f, fontSize: 8))
          ]));

  // New function for Promissory Note PDF generation, adapted from promissory_note_panel.dart
  Future<void> _generatePromissoryNotePDF(
      String refNo, double amountDue) async {
    final pdf = pw.Document();
    final dateIssued = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final dueDateStr = DateFormat('MMMM dd, yyyy').format(_promissoryDueDate!);
    final adminName =
        "${widget.userData['fn']} ${widget.userData['ln']}".toUpperCase();

    final studentName =
        "${_activeStudent!['fn']} ${_activeStudent!['ln']}".toUpperCase();
    final studentIdNumber = _activeStudent!['user_id_number'] ?? 'N/A';
    final courseYear =
        "${_activeStudent!['student_details']?['courses']?['name'] ?? 'N/A'} - ${_activeStudent!['student_details']?['year_levels']?['definition'] ?? 'N/A'}";

    String amountInWords = '';
    try {
      int whole = amountDue.toInt();
      int cents = ((amountDue - whole) * 100).toInt();
      amountInWords = "${whole.toString()} Pesos and $cents/100 Only";
    } catch (e) {
      amountInWords = 'Amount in words conversion error';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text('BRIGHT FUTURE ACADEMY',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900))),
              pw.Center(
                  child: pw.Text('OFFICE OF THE ACCOUNTING',
                      style:
                          const pw.TextStyle(fontSize: 10, letterSpacing: 1))),
              pw.SizedBox(height: 12),
              pw.Center(
                  child: pw.Text('PROMISSORY NOTE',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline))),
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Note Ref No.: $refNo",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text("Date Issued: $dateIssued",
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, height: 1.5),
                  children: [
                    const pw.TextSpan(text: "I, "),
                    pw.TextSpan(
                        text: studentName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                        text:
                            ", a student of Bright Future Academy with Student ID No. "),
                    pw.TextSpan(
                        text: studentIdNumber,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(text: ", currently enrolled in "),
                    pw.TextSpan(
                        text: courseYear,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                        text:
                            ", hereby promise to pay to the order of the Office of the Comptroller the total amount of:"),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                child: pw.Column(
                  children: [
                    pw.Text("PHP ${amountDue.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text("($amountInWords)",
                        style: pw.TextStyle(
                            fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text("Payment Terms:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text(
                  "I agree to settle the above amount on or before $dueDateStr.",
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
              pw.Text("Failure to pay within the agreed period may result in:",
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Bullet(
                  text: "Suspension of clearance processing",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Bullet(
                  text:
                      "Withholding of academic records (TOR, Diploma, Certifications)",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Bullet(
                  text: "Additional penalties as determined by the institution",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 24),
              pw.Text(
                "I hereby acknowledge my obligation and voluntarily commit to pay the stated amount under the terms and conditions set by Bright Future Academy.",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: pw.TextAlign.justify,
              ),
              pw.Spacer(),
              pw.Text("Signed:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(width: 1)))),
                      pw.Text("Student Name: $studentName",
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date Signed: _________________",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(width: 1)))),
                      pw.Text("Parent/Guardian: ${_parentNameController.text}",
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date Signed: _________________",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                      width: 250,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)))),
                  pw.Text("Authorized Representative: $adminName",
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Office: Office of the Comptroller",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text("Date: $dateIssued",
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Promissory_Note_$refNo.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  // New function to handle promissory note issuance
  Future<void> _issuePromissoryNote() async {
    if (_activeStudent == null || _promissoryDueDate == null) {
      _showToast(
          "Please select a student and a due date.", Colors.orangeAccent);
      return;
    }
    if (_parentNameController.text.trim().isEmpty) {
      _showToast("Parent/Guardian Name is required for Promissory Note.",
          Colors.orangeAccent);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final String refNo =
          "PN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      final double currentBalance = double.tryParse(
              _activeStudent!['student_details']?['account_balance']
                      ?.toString() ??
                  "0.0") ??
          0.0;

      await _service.client.from('office_requests').insert({
        'student_id': _activeStudent!['id'],
        'request_type': 'Promissory Note',
        'request_status': 'Approved', // Directly approved by accounting staff
        'amount_due': currentBalance,
        'due_date': _promissoryDueDate?.toIso8601String(),
        'qr_hash': refNo,
        'processed_by': widget.userData['id'],
        'remarks':
            'Issued Grace Period until ${DateFormat('MMMM dd, yyyy').format(_promissoryDueDate!)}. Parent: ${_parentNameController.text.trim()}. ${_notesController.text.trim()}',
      });

      await _generatePromissoryNotePDF(refNo, currentBalance);

      _showToast("Promissory Note Issued & PDF Generated.", success);
      _clearPromissoryNoteForm();
      _fetchStudentLedger(); // Refresh ledger to show new request
    } catch (e) {
      _showToast("Promissory Note Issuance Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _clearPromissoryNoteForm() {
    setState(() {
      _parentNameController.clear();
      _notesController.clear();
      _promissoryDueDate = DateTime.now().add(const Duration(days: 30));
      _paymentPlan = 'Full Payment'; // Reset to a default payment plan
    });
  }

  void _pickPromissoryDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _promissoryDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now()
          .add(const Duration(days: 365 * 2)), // Up to 2 years from now
      builder: (context, child) => Theme(
        data: widget.isDarkMode
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: aViolet,
                    onPrimary: Colors.white,
                    surface: surfaceDark,
                    onSurface: Colors.white),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: aViolet),
              ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _promissoryDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF1E1B4B);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildSearchField(cardColor, textColor),
          const SizedBox(height: 24),
          if (_activeStudent != null)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildLedgerView(cardColor, textColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 2, child: _buildIntelligentForm(cardColor, textColor)),
            ])
          else
            _buildEmptyState(textColor),
        ]));
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Tuition Payment Terminal",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: t,
                    letterSpacing: -1)),
            const Text(
                "Official assessment mirror with automated SMTP E-Receipt dispatch.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ]),
          if (_activeStudent != null)
            Row(children: [
              _actionTool(
                  "GENERATE STATEMENT", LucideIcons.fileText, _generateSOA),
              const SizedBox(width: 12),
              _actionTool("FINANCIAL CLEARANCE", LucideIcons.shieldCheck,
                  _grantClearance,
                  color: success),
            ])
        ],
      );

  Widget _actionTool(String l, IconData i, VoidCallback onTap,
          {Color color = aViolet}) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(i, size: 16),
        label: Text(l,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0),
      );

  Widget _buildSearchField(Color c, Color t) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Row(children: [
        const SizedBox(width: 16),
        const Icon(LucideIcons.search, color: aViolet, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchStudentLedger(),
                style: TextStyle(color: t, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                    hintText: "Search Student ID...",
                    border: InputBorder.none))),
        ElevatedButton(
            onPressed: _fetchStudentLedger,
            style: ElevatedButton.styleFrom(backgroundColor: aViolet),
            child: const Text("PULL ACCOUNT")),
      ]));

  Widget _buildLedgerView(Color c, Color t) {
    final details = _activeStudent!['student_details'];
    final double balance =
        double.tryParse(details?['account_balance']?.toString() ?? "0") ?? 0.0;
    return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: aViolet.withOpacity(0.1),
                radius: 24,
                child: Text((_activeStudent!['ln'] ?? 'U')[0],
                    style: const TextStyle(
                        color: aViolet, fontWeight: FontWeight.bold))),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  "${_activeStudent!['fn'] ?? ''} ${_activeStudent!['ln'] ?? ''}"
                      .toUpperCase(),
                  style:
                      GoogleFonts.inter(fontWeight: FontWeight.w900, color: t)),
              Text(details?['courses']?['name'] ?? 'College Department',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ]),
            const Spacer(),
            _balanceChip(balance),
          ]),
          const Divider(height: 60, color: Colors.white10),
          Text("FINANCIAL STANDING",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 20),
          _summaryRow("Institutional Gross Assessment",
              _officialAssessmentTotal, Colors.blueGrey),
          _summaryRow(
              "Scholarships / Discounts", -_scholarshipDiscount, success),
          const Divider(color: Colors.white10),
          _summaryRow("REMAINING ACCOUNTABILITY", balance, t, isTotal: true),
          const SizedBox(height: 40),
          Text("TRANSACTION HISTORY",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _ledgerEntries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No transactions recorded.",
                      style: TextStyle(color: Colors.blueGrey)))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ledgerEntries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, i) {
                    final entry = _ledgerEntries[i];
                    final String ref =
                        entry['reference_no']?.toString() ?? "REF-N/A";
                    final String rawDate = entry['created_at']?.toString() ??
                        DateTime.now().toIso8601String();
                    final double amt = double.tryParse(
                            (entry['amount_paid'] ?? entry['amount'] ?? "0")
                                .toString()) ??
                        0.0;
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.receipt,
                            size: 18, color: Colors.blueGrey),
                        title: Text(ref,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                            DateFormat('MMM dd, yyyy')
                                .format(DateTime.parse(rawDate)),
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                            "₱${NumberFormat('#,###.00').format(amt)}",
                            style: GoogleFonts.orbitron(
                                color: success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)));
                  }),
        ]));
  }

  Widget _buildIntelligentForm(Color c, Color t) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: aViolet.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Payment Processing",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: t)),
        const SizedBox(height: 24),
        _inputLabel("CHOOSE PLAN"),
        _buildDropdown(_paymentPlan, [
          'Full Payment',
          'Installment',
          'Custom Amount',
          'Promissory Note'
        ], (v) {
          setState(() => _paymentPlan = v!);
          _updateCalculatedAmount();
        }),
        const SizedBox(height: 16),
        if (_paymentPlan != 'Promissory Note') ...[
          _inputLabel("CHANNEL"),
          _buildDropdown(_paymentMethod, ['Cash', 'Online (Paymongo)'], (v) {
            setState(() => _paymentMethod = v!);
            _updateCalculatedAmount();
          }),
          const SizedBox(height: 24),
          _inputLabel(_paymentPlan == 'Custom Amount'
              ? "ENTER CUSTOM AMOUNT"
              : "DUE FOR POSTING"),
          TextField(
              controller: _amountController,
              enabled:
                  _paymentPlan == 'Custom Amount' || _paymentMethod == 'Cash',
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: (_paymentPlan == 'Custom Amount' ||
                          _paymentMethod == 'Cash')
                      ? t
                      : aViolet,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              decoration: _fieldStyle("0.00", prefix: "₱ "),
              onChanged: (_) => setState(() {})),
          if (_paymentMethod == 'Cash') ...[
            const SizedBox(height: 16),
            _inputLabel("TENDERED CASH"),
            TextField(
                controller: _cashReceivedController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: success, fontWeight: FontWeight.bold, fontSize: 20),
                decoration: _fieldStyle("Enter Amount Received", prefix: "₱ "))
          ],
        ] else ...[
          const SizedBox(height: 24),
          _inputLabel("PARENT/GUARDIAN NAME"),
          TextField(
            controller: _parentNameController,
            style: TextStyle(color: t),
            decoration: _fieldStyle("Full Name"),
          ),
          const SizedBox(height: 16),
          _inputLabel("PROMISSORY DUE DATE"),
          InkWell(
            onTap: _pickPromissoryDueDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _containerStyle(),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 18, color: aViolet),
                  const SizedBox(width: 12),
                  Text(
                    _promissoryDueDate == null
                        ? "Select Due Date"
                        : DateFormat('MMMM dd, yyyy')
                            .format(_promissoryDueDate!),
                    style: TextStyle(
                        color: _promissoryDueDate == null ? Colors.blueGrey : t,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _inputLabel("REMARKS (Optional)"),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(color: t),
            decoration: _fieldStyle("Additional notes..."),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : (_paymentPlan == 'Promissory Note'
                        ? _issuePromissoryNote
                        : (_paymentMethod == 'Cash'
                            ? _processCashDisbursement
                            : _processOnlinePayment)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text(
                    _paymentPlan == 'Promissory Note'
                        ? "ISSUE PROMISSORY NOTE"
                        : (_paymentMethod == 'Cash'
                            ? "VALIDATE CASH"
                            : "LAUNCH GATEWAY"),
                    style: const TextStyle(fontWeight: FontWeight.w900)))),
      ]));

  Widget _buildDropdown(String v, List<String> i, ValueChanged<String?> o) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _containerStyle(),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: v,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1B4B),
                  style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 13), // Ensure text is visible in light mode
                  items: i
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: o)));

  void _showCashSummary(double p, double r, double c) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF0F071D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text("Confirm Entry",
                    style: TextStyle(color: Colors.white)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  _summaryRow("Amount Due:", p, Colors.white),
                  _summaryRow("Cash Tendered:", r, Colors.white),
                  const Divider(color: Colors.white10),
                  _summaryRow("Change:", c, success, isTotal: true)
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL")),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _finalizeTransaction(p, method: 'Cash');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: success,
                          foregroundColor: Colors.black),
                      child: const Text("PROCESS & PRINT"))
                ]));
  }

  Widget _summaryRow(String l, double v, Color c,
          {bool isTotal = false, String? customLabel}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            Text(customLabel ?? "₱${NumberFormat('#,###.00').format(v)}",
                style: GoogleFonts.orbitron(
                    color: c,
                    fontSize: isTotal ? 16 : 12,
                    fontWeight: FontWeight.bold))
          ]));

  Widget _balanceChip(double b) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: b > 0
              ? Colors.redAccent.withOpacity(0.1)
              : success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text("₱${NumberFormat('#,###.00').format(b)}",
          style: GoogleFonts.orbitron(
              color: b > 0 ? Colors.redAccent : success,
              fontSize: 14,
              fontWeight: FontWeight.bold)));

  Widget _inputLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(t,
          style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)));

  InputDecoration _fieldStyle(String h, {String? prefix}) => InputDecoration(
      hintText: h,
      prefixText: prefix,
      filled: true,
      fillColor: widget.isDarkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.02),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none));

  BoxDecoration _containerStyle() => BoxDecoration(
      color: widget.isDarkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.grey
              .shade200, // Use a solid light grey for better visibility in light mode
      borderRadius: BorderRadius.circular(12));

  Widget _buildEmptyState(Color t) => Center(
          child: Column(children: [
        const SizedBox(height: 100), // Keep spacing
        Icon(LucideIcons.landmark,
            size: 64, color: Colors.blueGrey.withOpacity(0.1)),
        const SizedBox(height: 24),
        Text("Accounting Terminal Idle",
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey))
      ]));

  void _showLoadingGateway() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
            backgroundColor: Color(0xFF1E1B4B),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: aViolet),
              SizedBox(height: 20),
              Text("Launching Gateway...",
                  style: TextStyle(color: Colors.white))
            ])));
  }

  void _showPollingDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1B4B),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: success),
              const SizedBox(height: 24),
              Text("Monitoring Transaction",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Your payment is being verified in real-time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("CLOSE"))
            ])));
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
