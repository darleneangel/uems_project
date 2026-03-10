import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/supabase_service.dart';

class OfficesPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const OfficesPanel(
      {super.key, required this.isDarkMode, required this.studentData});

  @override
  State<OfficesPanel> createState() => _OfficesPanelState();
}

class _OfficesPanelState extends State<OfficesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubmitting = false;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  final List<Map<String, dynamic>> _catalog = [
    {
      "name": "Official Transcript of Records (TOR)",
      "price": 250.0,
      "icon": LucideIcons.fileText
    },
    {
      "name": "Form 138 (Report Card)",
      "price": 150.0,
      "icon": LucideIcons.scroll
    },
    {
      "name": "Certificate of Enrollment",
      "price": 100.0,
      "icon": LucideIcons.clipboardCheck
    },
    {
      "name": "Registration Form (Copy)",
      "price": 50.0,
      "icon": LucideIcons.fileSignature
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// SUBMIT: Creates record and triggers simulated "Gmail Dispatch"
  Future<void> _submitRequest(String type, double price) async {
    setState(() => _isSubmitting = true);
    final client = SupabaseService().client;
    final String hash =
        "REQ-${widget.studentData['user_id_number']}-${Random().nextInt(9999)}";

    try {
      await client.from('office_requests').insert({
        'student_id': widget.studentData['id'],
        'request_type': type,
        'amount_due': price,
        'qr_hash': hash,
        'payment_status': 'Unpaid',
        'request_status': 'Submitted',
      });

      // Simulation: Send to Personal Email
      await _simulateGmailDispatch(type, hash);

      setState(() => _isSubmitting = false);
      _tabController.animateTo(1);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError("System Error: $e");
    }
  }

  Future<void> _simulateGmailDispatch(String type, String ticket) async {
    final email = widget.studentData['email'] ?? "your registered gmail";
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(LucideIcons.mail, color: aViolet, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("QR TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Text("We have sent your official service ticket for $type to:",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(email,
                style: const TextStyle(
                    color: success, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text(
                "Please present the QR at the Accounting window for collection.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          Center(
              child: TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("UNDERSTOOD")))
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
        const SizedBox(height: 24),
        _buildTabBar(textColor),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServiceGrid(cardColor, textColor),
              _buildTrackingList(cardColor, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color t) => Row(
        children: [
          const Icon(LucideIcons.building, color: aViolet, size: 28),
          const SizedBox(width: 16),
          Text("Institutional Service Gateway",
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900, color: t)),
        ],
      );

  Widget _buildTabBar(Color t) => Container(
        height: 45,
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
            Tab(text: "NEW REQUEST"),
            Tab(text: "GMAIL TICKETS & TRACKING")
          ],
        ),
      );

  Widget _buildServiceGrid(Color bg, Color t) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4),
        itemCount: _catalog.length,
        itemBuilder: (context, i) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_catalog[i]['icon'], color: aViolet, size: 24),
              const Spacer(),
              Text(_catalog[i]['name'],
                  style: TextStyle(
                      color: t, fontWeight: FontWeight.bold, fontSize: 13)),
              Text("₱${_catalog[i]['price'].toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: success,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitRequest(
                              _catalog[i]['name'], _catalog[i]['price']),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: aViolet,
                          foregroundColor: Colors.white,
                          elevation: 0),
                      child: const Text("REQUEST"))),
            ],
          ),
        ),
      );

  Widget _buildTrackingList(Color bg, Color t) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().client.from('office_requests').stream(
          primaryKey: ['id']).eq('student_id', widget.studentData['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        if (data.isEmpty)
          return Center(
              child: Text("No request history.",
                  style: TextStyle(color: t.withOpacity(0.3))));

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, i) {
            final req = data[i];
            bool isPaid = req['payment_status'] == 'Paid';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['request_type'],
                            style: TextStyle(
                                color: t,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _badge(req['payment_status'],
                                isPaid ? success : Colors.orangeAccent),
                            const SizedBox(width: 8),
                            _badge(req['request_status'], aViolet),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _qrTrigger(req),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _qrTrigger(Map<String, dynamic> req) => InkWell(
        onTap: () => _showQRModal(req),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: QrImageView(
                  data: req['qr_hash'], size: 50, version: QrVersions.auto),
            ),
            const SizedBox(height: 4),
            const Text("OPEN TICKET",
                style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showQRModal(Map<String, dynamic> req) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: surfaceDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("OFFICIAL GMAIL TICKET",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 24),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(data: req['qr_hash'], size: 200)),
                  const SizedBox(height: 24),
                  Text(req['request_type'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                      "This QR was sent to your Gmail. Scan at Window 2.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 24),
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("CLOSE",
                          style: TextStyle(color: aViolet))),
                ],
              ),
            ));
  }

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
}
