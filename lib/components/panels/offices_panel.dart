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

  final List<String> _selectedDocs = [];
  bool _isSubmitting = false;

  // Visual Tokens
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

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
      final item = _catalog.firstWhere((c) => c['name'] == docName,
          orElse: () => {"price": 0.0});
      return sum + (item['price'] as double);
    });
  }

  /// 📧 SMTP ENGINE (Background Task)
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
      ..subject = 'UEMS Claim Ticket: ${docs.length} Documents'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 30px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 22px;'>OFFICIAL TICKET</h1>
            <p style='color: #a78bfa; font-size: 12px;'>Unified Education Management System</p>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>${widget.studentData['fn'] ?? 'Student'}</b>,</p>
            <p>Request confirmed. Present the QR code below at the Registrar window.</p>
            <ul style='color: #1e293b; font-weight: bold;'>$docListHtml</ul>
            <div style='text-align: center; margin: 30px 0;'>
              <img src='$qrUrl' width='200' height='200' style='border: 4px solid #f1f5f9; border-radius: 12px;' />
              <p style='color: #8B5CF6; font-weight: bold; font-family: monospace;'>REF: $hash</p>
            </div>
          </div>
        </div>
      """;

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  /// 🛰️ DATABASE ACTION
  Future<void> _submitOfficeRequest() async {
    if (_selectedDocs.isEmpty) return;
    setState(() => _isSubmitting = true);

    final client = SupabaseService().client;
    final String idNum = widget.studentData['user_id_number'] ?? "0000";
    final String qrHash =
        "BATCH-$idNum-${DateTime.now().millisecondsSinceEpoch}";

    try {
      final List<Map<String, dynamic>> batchData = _selectedDocs.map((docName) {
        final item = _catalog.firstWhere((c) => c['name'] == docName);
        return {
          'student_id': widget.studentData['id'],
          'request_type': docName,
          'qr_hash': qrHash,
          'amount_due': item['price'],
          'payment_status': 'Unpaid',
          'request_status': 'Submitted',
          'remarks': _remarksController.text,
        };
      }).toList();

      await client.from('office_requests').insert(batchData);

      final String personalEmail =
          widget.studentData['email'] ?? "angel.lustre2005@gmail.com";

      // Fire and forget email
      _sendBatchTicketEmail(personalEmail, qrHash, List.from(_selectedDocs));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedDocs.clear();
          _remarksController.clear();
        });
        _showSuccessDialog(qrHash);
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast("Cloud Sync Error: $e", Colors.redAccent);
      }
    }
  }

  /// 🎨 UI: Success Modal
  void _showSuccessDialog(String hash) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mailCheck, color: success, size: 56),
            const SizedBox(height: 20),
            const Text("REQUEST SUBMITTED",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Text("Ticket dispatched to your email.",
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 24),
            Container(
              width: 170,
              height: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: QrImageView(
                  data: hash,
                  version: QrVersions.auto,
                  size: 150.0,
                  gapless: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(c),
                  style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                  child: const Text("CLOSE")),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 UI: Ticket Viewer
  void _showTicketDialog(String hash, List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Batch Claim Ticket",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child:
                  QrImageView(data: hash, size: 200, version: QrVersions.auto),
            ),
            const SizedBox(height: 16),
            Text("REF: $hash",
                style: const TextStyle(
                    color: aViolet, fontFamily: 'monospace', fontSize: 10)),
            const Divider(height: 32, color: Colors.white10),
            ...items.map((i) => Text("• ${i['request_type']}",
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("DONE"))
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabBar(textColor),
        const SizedBox(height: 24),
        // FIX: Replaced Expanded with ConstrainedBox.
        // Dashboard SingleChildScrollView + Expanded = Unbounded height crash.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 500, maxHeight: 800),
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
                      if (val!) {
                        _selectedDocs.add(item['name']);
                      } else {
                        _selectedDocs.remove(item['name']);
                      }
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
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSubmitting || _selectedDocs.isEmpty
                  ? null
                  : _submitOfficeRequest,
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: aViolet));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No academic requests recorded."));
        }

        final Map<String, List<Map<String, dynamic>>> groups = {};
        for (var req in snapshot.data!) {
          final hash = req['qr_hash'] as String;
          groups.putIfAbsent(hash, () => []).add(req);
        }

        final sortedHashes = groups.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          shrinkWrap: true, // Necessary inside constrained container
          itemCount: sortedHashes.length,
          itemBuilder: (context, index) {
            final String hash = sortedHashes[index];
            final List<Map<String, dynamic>> items = groups[hash]!;
            final double total = items.fold(
                0.0,
                (sum, i) =>
                    sum + (double.tryParse(i['amount_due'].toString()) ?? 0.0));
            final String status = items.first['request_status'] ?? "Pending";

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CLAIM TICKET",
                              style: GoogleFonts.inter(
                                  color: aViolet,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 2)),
                          Text("${items.length} Documents Request",
                              style: TextStyle(
                                  color: text, fontWeight: FontWeight.bold)),
                          Text("Total: ₱${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
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
                      ElevatedButton.icon(
                        onPressed: () => _showTicketDialog(hash, items),
                        icon: const Icon(LucideIcons.qrCode, size: 14),
                        label: const Text("VIEW QR",
                            style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: aViolet.withOpacity(0.1),
                            foregroundColor: aViolet,
                            elevation: 0),
                      ),
                    ],
                  ),
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
    Color c = s == "Submitted" ? success : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }
}
