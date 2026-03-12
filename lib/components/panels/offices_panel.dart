import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  // MULTI-SELECT STATE
  final List<String> _selectedDocs = [];
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
    {"name": "Honorable Dismissal", "price": 300.0},
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

  double _calculateTotal() {
    return _selectedDocs.fold(0, (sum, docName) {
      final item = _catalog.firstWhere((c) => c['name'] == docName);
      return sum + (item['price'] as double);
    });
  }

  /// --- SMTP NOTIFICATION ENGINE ---
  Future<void> _sendBatchTicketEmail(
      String recipientEmail, String hash, List<String> docs) async {
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    const String appPassword = 'jnea wnbk atjg gyqi';

    final smtpServer = gmail(senderEmail, appPassword);
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$hash&margin=10&ecc=H";
    final String docListHtml = docs.map((d) => "<li>$d</li>").join("");

    final message = Message()
      ..from = const Address(senderEmail, 'SSCR Registrar Office')
      ..recipients.add(recipientEmail)
      ..subject = 'UEMS Batch Claim Ticket: ${docs.length} Documents'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 30px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 22px;'>OFFICIAL TICKET</h1>
            <p style='color: #a78bfa; font-size: 12px;'>Unified Education Management System</p>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>${widget.studentData['fn'] ?? 'Student'}</b>,</p>
            <p>You have requested the following documents:</p>
            <ul style='color: #1e293b; font-weight: bold;'>$docListHtml</ul>
            
            <div style='text-align: center; margin: 30px 0;'>
              <img src='$qrUrl' width='200' height='200' style='border: 4px solid #f1f5f9; border-radius: 12px;' />
              <p style='color: #8B5CF6; font-weight: bold; font-family: monospace;'>REF: $hash</p>
            </div>
            <p style='font-size: 11px; color: #64748b;'>Scan this at the Registrar window after payment.</p>
          </div>
        </div>
      """;

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  Future<void> _submitOfficeRequest() async {
    if (_selectedDocs.isEmpty) return;
    setState(() => _isSubmitting = true);

    final client = SupabaseService().client;
    final String idNum = widget.studentData['user_id_number'] ?? "0000";

    // ONE HASH FOR ALL DOCUMENTS IN THIS REQUEST
    final String qrHash =
        "BATCH-$idNum-${DateTime.now().millisecondsSinceEpoch}";

    try {
      // Create a list of insertions
      final List<Map<String, dynamic>> batchData = _selectedDocs.map((docName) {
        final price = _catalog.firstWhere((c) => c['name'] == docName)['price'];
        return {
          'student_id': widget.studentData['id'],
          'request_type': docName,
          'qr_hash': qrHash, // Shared key
          'amount_due': price,
          'payment_status': 'Unpaid',
          'request_status': 'Submitted',
          'remarks': _remarksController.text,
        };
      }).toList();

      // 1. Bulk Insert into Supabase
      await client.from('office_requests').insert(batchData);

      // 2. Dispatch Email with the list of docs
      final String personalEmail =
          widget.studentData['email'] ?? "angel.lustre2005@gmail.com";
      await _sendBatchTicketEmail(personalEmail, qrHash, _selectedDocs);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedDocs.clear();
          _remarksController.clear();
        });
        _showSuccessDialog(personalEmail, qrHash);
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Cloud Sync Error: $e"),
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
            const Text("BATCH TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: aViolet, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: hash, size: 150),
            ),
            const SizedBox(height: 12),
            const Text("This QR code represents your entire request.",
                style: TextStyle(color: Colors.white24, fontSize: 10)),
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
        SizedBox(
          height: 700,
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
            Tab(text: "SELECT DOCUMENTS"),
            Tab(text: "TICKET TRACKING")
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _catalog.length,
              itemBuilder: (context, i) {
                final item = _catalog[i];
                bool isSelected = _selectedDocs.contains(item['name']);
                return CheckboxListTile(
                  title: Text(item['name'],
                      style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  subtitle: Text("₱${item['price']}",
                      style: const TextStyle(color: aViolet, fontSize: 12)),
                  value: isSelected,
                  activeColor: aViolet,
                  onChanged: (val) {
                    setState(() {
                      if (val!)
                        _selectedDocs.add(item['name']);
                      else
                        _selectedDocs.remove(item['name']);
                    });
                  },
                );
              },
            ),
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label("Total Assessment:"),
              Text("₱${_calculateTotal()}",
                  style: GoogleFonts.orbitron(
                      color: success,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          _label("Purpose / Remarks"),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            style: TextStyle(color: text),
            decoration: InputDecoration(
                hintText: "Enter purpose of request...",
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 65,
            child: ElevatedButton(
              onPressed: _isSubmitting || _selectedDocs.isEmpty
                  ? null
                  : _submitOfficeRequest,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SUBMIT BATCH REQUEST",
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));

        // GROUPING LOGIC: Combine rows with same QR hash into one card
        final Map<String, List<Map<String, dynamic>>> groups = {};
        for (var req in snapshot.data!) {
          final hash = req['qr_hash'] as String;
          groups.putIfAbsent(hash, () => []).add(req);
        }

        if (groups.isEmpty)
          return const Center(child: Text("No requests found."));

        return ListView(
          children: groups.entries.map((entry) {
            final String hash = entry.key;
            final List<Map<String, dynamic>> items = entry.value;
            final double total =
                items.fold(0.0, (sum, i) => sum + (i['amount_due'] as double));
            final String status = items.first['request_status'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("BATCH TICKET",
                                style: GoogleFonts.inter(
                                    color: aViolet,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 2)),
                            const SizedBox(height: 4),
                            Text("${items.length} Documents Requested",
                                style: TextStyle(
                                    color: text, fontWeight: FontWeight.bold)),
                            Text("Total: ₱$total",
                                style: const TextStyle(
                                    color: success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const Divider(height: 32, color: Colors.white10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map((i) => Text("• ${i['request_type']}",
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)))
                              .toList(),
                        ),
                      ),
                      // THE QR CODE FOR THE BATCH
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: QrImageView(data: hash, size: 80),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
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
  Widget _statusBadge(String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style: const TextStyle(
              color: success, fontSize: 9, fontWeight: FontWeight.bold)));
}
