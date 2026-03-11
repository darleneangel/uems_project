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

  /// --- SMTP NOTIFICATION ENGINE ---
  /// Transmits a high-quality, real scannable QR ticket to the student's personal email.
  Future<void> _sendTicketToEmail(
      String recipientEmail, String hash, String docType) async {
    // --- CREDENTIAL CONFIGURATION ---
    // IMPORTANT: Use your 16-character App Password here
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    const String appPassword = 'jnea wnbk atjg gyqi';

    final smtpServer = gmail(senderEmail, appPassword);

    // We use the QR Server API to generate a high-contrast, scannable real image.
    // data=$hash is the payload the Registrar's webcam will read.
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$hash&margin=10&ecc=H";

    final message = Message()
      ..from = const Address(senderEmail, 'SSCR Registrar Office')
      ..recipients.add(recipientEmail)
      ..subject = 'UEMS Claim Ticket: $docType'
      ..html = """
        <div style='font-family: sans-serif; max-width: 550px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);'>
          <div style='background-color: #2E1065; padding: 40px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 24px; letter-spacing: 1px;'>OFFICIAL CLAIM TICKET</h1>
            <p style='color: #a78bfa; font-size: 12px; margin-top: 8px;'>San Sebastian College - Recoletos de Cavite</p>
          </div>
          <div style='padding: 40px; text-align: center; background-color: #ffffff;'>
            <p style='font-size: 16px; color: #1e293b;'>Hello <b>${widget.studentData['fn']}</b>,</p>
            <p style='color: #64748b; line-height: 1.6;'>Your request for <b>$docType</b> has been logged in the institutional ledger. Please present the QR code below at the Registrar window for verification and releasing.</p>
            
            <div style='margin: 40px 0;'>
              <div style='display: inline-block; padding: 15px; border: 2px solid #8B5CF6; border-radius: 20px;'>
                <img src='$qrUrl' width='200' height='200' style='display: block;' alt='QR Ticket' />
              </div>
              <p style='color: #8B5CF6; font-weight: bold; font-size: 13px; margin-top: 15px; font-family: monospace;'>REF: $hash</p>
            </div>

            <div style='background-color: #f8fafc; padding: 20px; border-radius: 12px; border: 1px dashed #cbd5e1; text-align: left;'>
              <p style='margin: 0; font-size: 11px; color: #475569;'><b>Instructions:</b></p>
              <ul style='margin: 10px 0 0 0; padding-left: 20px; font-size: 11px; color: #64748b;'>
                <li>Ensure payment is settled via the Accounting Office.</li>
                <li>Present this email (digital or printed) to the Registrar.</li>
                <li>Status will be updated to 'Released' upon scanning.</li>
              </ul>
            </div>
          </div>
          <div style='text-align: center; padding: 20px; background-color: #f1f5f9; color: #94a3b8; font-size: 10px;'>
            Automated Generation: Unified Education Management System Core
          </div>
        </div>
      """;

    try {
      await send(message, smtpServer);
      debugPrint('Ticket transmitted to $recipientEmail');
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  /// --- DATABASE ACTION ---
  /// Generates a unique hash, saves it to Supabase, and triggers the SMTP dispatch.
  Future<void> _submitOfficeRequest() async {
    if (_selectedDocType == null) return;
    setState(() => _isSubmitting = true);

    final client = SupabaseService().client;
    final String idNum = widget.studentData['user_id_number'];

    // Create a unique scannable hash: REQ + ID + Epoch
    final String qrHash = "REQ-$idNum-${DateTime.now().millisecondsSinceEpoch}";
    final double price = _catalog
        .firstWhere((item) => item['name'] == _selectedDocType)['price'];

    try {
      // 1. Insert Request into the cloud ledger (office_requests table)
      await client.from('office_requests').insert({
        'student_id': widget.studentData['id'],
        'request_type': _selectedDocType,
        'qr_hash': qrHash,
        'amount_due': price,
        'payment_status': 'Unpaid',
        'request_status': 'Submitted',
        'remarks': _remarksController.text,
      });

      // 2. Resolve target email (Priority: Database Email -> Default Fallback)
      final String personalEmail =
          widget.studentData['email'] ?? "angel.lustre2005@gmail.com";

      // 3. Dispatch the real image QR ticket via SMTP
      await _sendTicketToEmail(personalEmail, qrHash, _selectedDocType!);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(personalEmail, qrHash);
        _remarksController.clear();
        _tabController.animateTo(1); // Auto-navigate to history tab
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Cloud Sync Failure: $e"),
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
            const SizedBox(height: 24),
            const Text("TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Text("A high-resolution scannable ticket was sent to:",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(email,
                style: const TextStyle(
                    color: aViolet, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=$hash&margin=10",
                  height: 140,
                  width: 140),
            ),
            const SizedBox(height: 24),
            const Text("Present this ticket to the Registrar window.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
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
        Expanded(
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
          tabs: const [
            Tab(text: "REQUEST DOCUMENT"),
            Tab(text: "CLAIM TICKETS")
          ],
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
          _label("Institutional Document Catalog"),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: surfaceDark,
            style: TextStyle(color: text, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
            items: _catalog
                .map((c) => DropdownMenuItem(
                      value: c['name']?.toString() ?? '',
                      child: Text(
                          "${c['name'] ?? 'Unknown'} (₱${c['price'] ?? '0.00'})"),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedDocType = v),
          ),
          const SizedBox(height: 24),
          _label("Reason for Request"),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            style: TextStyle(color: text),
            maxLines: 3,
            decoration: InputDecoration(
                hintText: "e.g., For Scholarship Application...",
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 65,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOfficeRequest,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: aViolet.withOpacity(0.5)),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GENERATE & DISPATCH TICKET",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));
        final list = snapshot.data!;
        if (list.isEmpty)
          return Center(
              child: Text("No request history found in cloud.",
                  style: TextStyle(color: text.withOpacity(0.3))));

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
                  const Icon(LucideIcons.fileText, color: aViolet, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['request_type'],
                          style: TextStyle(
                              color: text, fontWeight: FontWeight.bold)),
                      Text("ID: ${req['qr_hash'].toString().split('-').last}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 10)),
                    ],
                  )),
                  _statusBadge(req['request_status']),
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
