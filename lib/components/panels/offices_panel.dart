import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../services/supabase_service.dart';

class OfficesPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const OfficesPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<OfficesPanel> createState() => _OfficesPanelState();
}

class _OfficesPanelState extends State<OfficesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _remarksController = TextEditingController();
  String? _selectedDocType;
  bool _isSubmitting = false;

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // Registrar Catalog
  final List<Map<String, dynamic>> _catalog = [
    {"name": "Official Transcript (TOR)", "price": 250.0},
    {"name": "Form 138 (Report Card)", "price": 150.0},
    {"name": "Certificate of Enrollment", "price": 100.0},
    {"name": "Diploma Request", "price": 500.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// --- SMTP NOTIFICATION ENGINE ---
  /// Sends a real scannable QR image ticket to the student's personal email
  Future<void> _sendTicketToEmail(
      String recipientEmail, String hash, String docType) async {
    // --- CREDENTIAL CONFIGURATION ---
    // Replace with your actual SSCR/Personal Gmail
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    // PASTE YOUR 16-CHARACTER APP PASSWORD HERE
    const String appPassword = 'jnea wnbk atjg gyqi';

    final smtpServer = gmail(senderEmail, appPassword);

    // Scannable Real Image URL (Using high-quality QR API)
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$hash&margin=10&ecc=H";

    final message = Message()
      ..from = const Address(senderEmail, 'SSCR Registrar Office')
      ..recipients.add(recipientEmail)
      ..subject = 'UEMS Claim Ticket: $docType'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);'>
          <div style='background-color: #2E1065; padding: 30px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 22px; letter-spacing: 1px;'>OFFICIAL CLAIM TICKET</h1>
            <p style='color: #a78bfa; font-size: 12px; margin-top: 5px;'>Unified Education Management System</p>
          </div>
          <div style='padding: 30px; text-align: center; background-color: #ffffff;'>
            <p style='color: #1e293b; font-size: 16px;'>Hello <b>${widget.studentData['fn'] ?? 'Student'}</b>,</p>
            <p style='color: #64748b; line-height: 1.5;'>Your request for <b>$docType</b> has been logged. Please present the QR code below at the Registrar window for releasing.</p>
            <div style='margin: 30px 0;'>
              <img src='$qrUrl' width='180' height='180' alt='QR Ticket' style='border: 4px solid #f1f5f9; border-radius: 12px;' />
              <p style='color: #8B5CF6; font-weight: bold; font-size: 11px; margin-top: 10px; font-family: monospace;'>REF: $hash</p>
            </div>
            <div style='background-color: #f8fafc; padding: 15px; border-radius: 12px; border: 1px dashed #cbd5e1; text-align: left;'>
              <p style='margin: 0; font-size: 11px; color: #475569;'><b>Note:</b> Access will be granted in the portal once the Registrar validates this stub.</p>
            </div>
          </div>
          <div style='text-align: center; padding: 20px; background-color: #f1f5f9; color: #94a3b8; font-size: 10px;'>
            Generated via UEMSSP Intelligent Core | SSCR-Cavite
          </div>
        </div>
      """;

    try {
      await send(message, smtpServer);
      debugPrint('SMTP: Ticket successfully transmitted to $recipientEmail');
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  Future<void> _submitOfficeRequest() async {
    if (_selectedDocType == null) return;
    setState(() => _isSubmitting = true);

    final client = SupabaseService().client;
    final String idNum = widget.studentData['user_id_number'] ?? "0000";
    final String qrHash = "REQ-$idNum-${DateTime.now().millisecondsSinceEpoch}";
    final double price = _catalog
        .firstWhere((item) => item['name'] == _selectedDocType)['price'];

    try {
      // 1. Insert into Ledger
      await client.from('office_requests').insert({
        'student_id': widget.studentData['id'],
        'request_type': _selectedDocType,
        'qr_hash': qrHash,
        'amount_due': price,
        'payment_status': 'Unpaid',
        'request_status': 'Submitted',
        'remarks': _remarksController.text,
      });

      // 2. Dispatch Email
      final String personalEmail =
          widget.studentData['email'] ?? "angel.lustre2005@gmail.com";
      await _sendTicketToEmail(personalEmail, qrHash, _selectedDocType!);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(personalEmail, qrHash);
        _remarksController.clear();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        debugPrint("Insertion Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Cloud Error: ${e.toString().contains('42501') ? 'Disable RLS in Supabase SQL Editor' : e}"),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showSuccessDialog(String email, String hash) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mailCheck, color: success, size: 56),
            const SizedBox(height: 20),
            const Text("TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: aViolet, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$hash",
                  height: 120),
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
        _buildTabBar(textColor),
        const SizedBox(height: 24),
        // Layout Fix: Wrapped in constrained SizedBox
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestForm(cardColor, textColor),
              _buildHistoryQueue(cardColor, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(Color t) => Container(
        height: 50,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
              color: aViolet, borderRadius: BorderRadius.circular(10)),
          labelColor: Colors.white,
          unselectedLabelColor: t.withOpacity(0.4),
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [Tab(text: "NEW REQUEST"), Tab(text: "TRACKING")],
        ),
      );

  Widget _buildRequestForm(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Document Type"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: surfaceDark,
            style: TextStyle(color: text, fontWeight: FontWeight.bold),
            items: _catalog
                .map((c) => DropdownMenuItem<String>(
                    value: c['name'],
                    child: Text("${c['name']} (₱${c['price']})")))
                .toList(),
            onChanged: (v) => setState(() => _selectedDocType = v),
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 24),
          _label("Remarks"),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            style: TextStyle(color: text),
            maxLines: 3,
            decoration: InputDecoration(
                hintText: "Enter purpose of request...",
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOfficeRequest,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SUBMIT & SEND TICKET",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryQueue(Color bg, Color text) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().client.from('office_requests').stream(
          primaryKey: ['id']).eq('student_id', widget.studentData['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
              child: Text("Sync Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent)));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));

        final list = snapshot.data!;
        if (list.isEmpty)
          return const Center(child: Text("No previous requests found."));

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final req = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  const Icon(LucideIcons.fileText, color: aViolet),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['request_type'] ?? "Document",
                          style: TextStyle(
                              color: text, fontWeight: FontWeight.bold)),
                      Text("Ref: ${req['qr_hash'].toString().split('-').last}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 11)),
                    ],
                  )),
                  _statusBadge(req['request_status'] ?? "Pending"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey,
          letterSpacing: 1.5));

  Widget _statusBadge(String s) {
    Color c = s == 'Released' ? success : Colors.orangeAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(s.toUpperCase(),
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
  }
}
