import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  // --- FORM STATE ---
  String? _selectedRequestType;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  // Standardized Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // Registrar Services Catalog
  final List<Map<String, dynamic>> _serviceCatalog = [
    {"name": "Official Transcript of Records (TOR)", "price": 250.0},
    {"name": "Form 138 (Report Card)", "price": 150.0},
    {"name": "Certificate of Enrollment", "price": 100.0},
    {"name": "Diploma Request", "price": 500.0},
    {"name": "Honorable Dismissal", "price": 200.0},
    {"name": "Registration Form (Copy)", "price": 50.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// DATABASE ACTION: Creates a real record in Supabase and triggers Gmail simulation
  Future<void> _submitRequest() async {
    if (_selectedRequestType == null) return;

    setState(() => _isSubmitting = true);
    final client = SupabaseService().client;

    // Find price from catalog
    final double price = _serviceCatalog
        .firstWhere((s) => s['name'] == _selectedRequestType)['price'];

    // Generate unique hash for the QR ticket
    final String hash =
        "REQ-${widget.studentData['user_id_number']}-${DateTime.now().millisecondsSinceEpoch}";

    try {
      // 1. Insert into cloud database
      await client.from('office_requests').insert({
        'student_id': widget.studentData['id'],
        'request_type': _selectedRequestType,
        'amount_due': price,
        'qr_hash': hash,
        'payment_status': 'Unpaid',
        'request_status': 'Submitted',
        'remarks': _messageController.text,
      });

      // 2. Trigger the Gmail UI Simulation
      await _simulateGmailDispatch(_selectedRequestType!, hash);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedRequestType = null;
          _messageController.clear();
        });
        _tabController.animateTo(1); // Move to history tab
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError("System Error: Could not reach the ledger.");
      }
    }
  }

  /// GMAIL SIMULATION: Displays the scannable ticket sent to Gmail
  Future<void> _simulateGmailDispatch(String type, String hash) async {
    final email = widget.studentData['email'] ?? "your registered gmail";
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$hash";

    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mail, color: aViolet, size: 48),
            const SizedBox(height: 20),
            const Text("GMAIL TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Text("An official copy of your request for $type has been sent to:",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(email,
                style: const TextStyle(
                    color: success, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Image.network(qrUrl, width: 150, height: 150),
            ),
            const SizedBox(height: 24),
            const Text(
                "Present this QR at the Accounting window for collection.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          Center(
              child: TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("UNDERSTOOD",
                      style: TextStyle(fontWeight: FontWeight.bold))))
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDashboardSummary(cardColor, textColor),
        const SizedBox(height: 24),
        _buildTabBar(textColor),
        const SizedBox(height: 24),
        SizedBox(
          height:
              600, // Constraints height for the TabBarView to prevent layout exceptions
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNewRequestForm(cardColor, textColor),
              _buildRequestHistory(cardColor, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSummary(Color cardColor, Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().client.from('office_requests').stream(
          primaryKey: ['id']).eq('student_id', widget.studentData['id']),
      builder: (context, snapshot) {
        int active = 0;
        int pickup = 0;
        int completed = 0;

        if (snapshot.hasData) {
          final data = snapshot.data!;
          active = data
              .where((r) =>
                  r['request_status'] == 'Submitted' ||
                  r['request_status'] == 'Processing')
              .length;
          pickup = data
              .where((r) => r['request_status'] == 'Ready for Pickup')
              .length;
          completed =
              data.where((r) => r['request_status'] == 'Released').length;
        }

        return Row(
          children: [
            _statCard("Pending Review", active.toString(), Colors.blueAccent,
                cardColor, textColor),
            const SizedBox(width: 16),
            _statCard("Ready for Pickup", pickup.toString(), success, cardColor,
                textColor),
            const SizedBox(width: 16),
            _statCard("Total Released", completed.toString(), aViolet,
                cardColor, textColor),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, Color cardColor,
      Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: aViolet),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: "REQUEST DOCUMENT"),
          Tab(text: "TRACKING & TICKETS")
        ],
      ),
    );
  }

  Widget _buildNewRequestForm(Color cardColor, Color textColor) {
    final inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(LucideIcons.fileSignature, color: aViolet),
              const SizedBox(width: 12),
              Text("Registrar Service Gateway",
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ]),
            const SizedBox(height: 32),
            _buildLabel("Select Document Type", textColor),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRequestType,
              items: _serviceCatalog.map((s) => s['name'].toString()).toList(),
              hint: "Choose document...",
              onChanged: (val) => setState(() => _selectedRequestType = val),
              textColor: textColor,
              fillColor: inputFill,
            ),
            const SizedBox(height: 24),
            _buildLabel("Purpose / Remarks", textColor),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                  hintText: "Reason for request...",
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT TO CLOUD LEDGER",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestHistory(Color cardColor, Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().client.from('office_requests').stream(
          primaryKey: ['id']).eq('student_id', widget.studentData['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));
        final requests = snapshot.data!;
        if (requests.isEmpty)
          return const Center(
              child: Text("No records found in cloud database."));

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            bool isPaid = req['payment_status'] == 'Paid';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: ExpansionTile(
                leading: const Icon(LucideIcons.fileText, color: aViolet),
                title: Text(req['request_type'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                    "Ref: ${req['qr_hash'].toString().split('-').last}",
                    style:
                        const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                trailing: _statusBadge(req['request_status'],
                    isPaid ? success : Colors.orangeAccent),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildTicketSection(req, textColor),
                        const Divider(height: 32, color: Colors.white10),
                        _timelineItem("Request Filed",
                            req['date_applied'] ?? "Just now", true),
                        _timelineItem(
                            req['request_status'], "Latest Update", false),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTicketSection(Map<String, dynamic> req, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: aViolet.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: aViolet.withOpacity(0.1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OFFICIAL GMAIL TICKET",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: aViolet)),
                const SizedBox(height: 4),
                Text(
                    req['payment_status'] == 'Paid'
                        ? "PAID & CLEARED"
                        : "UNPAID",
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text("Scan this QR at Window 2 for releasing.",
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: QrImageView(
                data: req['qr_hash'],
                size: 60,
                version: QrVersions.auto,
                gapless: false),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String label, String time, bool done) => Row(children: [
        Icon(LucideIcons.circleDot, size: 12, color: done ? success : aViolet),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(time, style: const TextStyle(fontSize: 10, color: Colors.blueGrey))
      ]);
  Widget _buildLabel(String l, Color t) => Text(l.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: t.withOpacity(0.5)));
  Widget _buildDropdown(
          {required String? value,
          required List<String> items,
          required String hint,
          required ValueChanged<String?> onChanged,
          required Color textColor,
          required Color fillColor}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: fillColor, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: surfaceDark,
                  style: TextStyle(color: textColor),
                  onChanged: onChanged,
                  items: items
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  hint: Text(hint,
                      style: TextStyle(color: textColor.withOpacity(0.3))))));
  Widget _statusBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
}
