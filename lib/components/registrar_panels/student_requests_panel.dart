import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/windows_qr_scanner.dart';

class StudentRequestsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRequestsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRequestsPanel> createState() => _StudentRequestsPanelState();
}

class _StudentRequestsPanelState extends State<StudentRequestsPanel> {
  String? _selectedRequestId;
  bool _isProcessing = false;

  // Institutional Tonal Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // --- 📷 SCANNER MODULE ---

  void _openRequestScanner() {
    showDialog(
      context: context,
      builder: (cxt) => WindowsQRScanner(
        onScan: (code) {
          _handleScannedRequest(code);
        },
        onManualEntry: () {
          Navigator.pop(cxt);
          _showManualEntryDialog();
        },
      ),
    );
  }

  Future<void> _handleScannedRequest(String hash) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    final client = SupabaseService().client;

    try {
      final result = await client
          .from('office_requests')
          .select('id')
          .eq('qr_hash', hash)
          .maybeSingle();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result == null) {
        _showToast(
            "Service Ticket not found in cloud ledger.", Colors.redAccent);
        return;
      }

      setState(() => _selectedRequestId = (result['id'] ?? '').toString());
      _showToast("Record Verified.", aViolet);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Scanner Sync Error.", Colors.redAccent);
      }
    }
  }

  // --- 📧 NOTIFICATION ENGINE ---

  Future<void> _notifyStudentStatus(
      String email, String name, String doc, String status) async {
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    const String appPassword = 'jnea wnbk atjg gyqi';
    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = const Address(senderEmail, 'Registrar Office')
      ..recipients.add(email)
      ..subject = 'Document Update: $doc'
      ..html = """
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 12px;'>
          <h2 style='color: #2E1065;'>Request Status Update</h2>
          <p>Hello <b>$name</b>,</p>
          <p>The status of your request for <b>$doc</b> has been changed to: <span style='color: #8B5CF6; font-weight: bold;'>$status</span>.</p>
          <p>Please check your student portal for further details.</p>
        </div>
      """;

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  // --- 🛰️ DATABASE ACTIONS ---

  Future<void> _updateRequestStatus(String status, Map<String, dynamic> req,
      Map<String, dynamic> profile) async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService().client.from('office_requests').update({
        'request_status': status,
        if (status == 'Released')
          'released_at': DateTime.now().toIso8601String(),
      }).eq('id', (req['id'] ?? '').toString());

      await _notifyStudentStatus(
          (profile['email'] ?? '').toString(),
          "${profile['fn'] ?? ''} ${profile['ln'] ?? ''}",
          (req['request_type'] ?? 'Official Document').toString(),
          status);

      _showToast("Status updated to $status", success);
    } catch (e) {
      _showToast("Update Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 4,
                    child: _buildIncomingQueue(
                        cardColor, textColor, subTextColor)),
                const SizedBox(width: 24),
                Expanded(
                    flex: 6,
                    child: _buildRequestManagement(
                        cardColor, textColor, subTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Scholastic Fulfillment Terminal",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: t,
                    letterSpacing: -1)),
            const Text(
                "Audit incoming document requests and manage fulfillment lifecycle.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ]),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _openRequestScanner,
            icon: const Icon(LucideIcons.scanLine),
            label: const Text("TICKET SCANNER"),
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

  Widget _buildIncomingQueue(Color bg, Color text, Color sub) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Incoming Applications",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900, color: text, fontSize: 18)),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService().client.from('office_requests').stream(
                  primaryKey: ['id']).order('date_applied', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(sub, "Ledger Link Failure");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }

                final rawList = snapshot.data ?? [];

                final list = rawList.where((req) {
                  final String type = (req['request_type'] ?? '').toString();
                  return type != 'Registration Fee' && type.isNotEmpty;
                }).toList();

                if (list.isEmpty) return _buildEmptyQueue(sub);

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final req = list[i];
                    final String requestId = (req['id'] ?? '').toString();
                    final String studentId =
                        (req['student_id'] ?? '').toString();
                    final String docType =
                        (req['request_type'] ?? 'Official Document')
                            .toString()
                            .toUpperCase();
                    bool isSelected = _selectedRequestId == requestId;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: studentId.isEmpty
                          ? Future.value(null)
                          : SupabaseService()
                              .client
                              .from('profiles')
                              .select(
                                  'fn, ln, user_id_number, student_details(courses(code), year_levels(definition))')
                              .eq('id', studentId)
                              .maybeSingle(),
                      builder: (context, profSnap) {
                        final profile = profSnap.data;
                        String studentDisplay = profile != null
                            ? "${profile['fn']} ${profile['ln']}".trim()
                            : "Identity Pending...";
                        String idDisplay = profile != null
                            ? (profile['user_id_number'] ?? 'N/A').toString()
                            : "LRN-SEARCHING";

                        return ListTile(
                          onTap: () =>
                              setState(() => _selectedRequestId = requestId),
                          selected: isSelected,
                          selectedTileColor: aViolet.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(studentDisplay,
                                      style: TextStyle(
                                          color: text,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13))),
                              _statusChip((req['request_status'] ?? 'Submitted')
                                  .toString()),
                            ],
                          ),
                          subtitle: Text(docType,
                              style: const TextStyle(
                                  color: aViolet,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestManagement(Color bg, Color text, Color sub) {
    if (_selectedRequestId == null) return _buildEmptyDetailState(text, sub);

    return FutureBuilder<Map<String, dynamic>>(
      future: SupabaseService()
          .client
          .from('office_requests')
          .select('''
            *, 
            profiles!office_requests_student_id_fkey(
              *, 
              student_details(
                courses(name), 
                year_levels(definition)
              )
            )
          ''') // 🎯 THE FIX: Explicitly using !office_requests_student_id_fkey to resolve ambiguity
          .eq('id', _selectedRequestId!)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Full Error Log: ${snapshot.error}");
          return _buildErrorState(sub, "Identity Resolution Error");
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: aViolet));
        }

        final req = snapshot.data!;

        final dynamic pRaw = req['profiles'];
        Map<String, dynamic>? p;
        if (pRaw is Map<String, dynamic>) {
          p = pRaw;
        } else if (pRaw is List && pRaw.isNotEmpty) p = pRaw[0];

        Map<String, dynamic>? details;
        if (p != null) {
          final dynamic detailsRaw = p['student_details'];
          if (detailsRaw is List && detailsRaw.isNotEmpty) {
            details = detailsRaw[0];
          } else if (detailsRaw is Map<String, dynamic>) details = detailsRaw;
        }

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailHeader(p, details,
                  (req['request_type'] ?? 'DOC').toString(), text, sub),
              const Divider(height: 64, color: Colors.white10),
              Row(
                children: [
                  _infoBox(
                      "Payment Status",
                      (req['payment_status'] ?? 'Unpaid').toString(),
                      (req['payment_status'] == 'Paid')
                          ? success
                          : Colors.orange),
                  const SizedBox(width: 16),
                  _infoBox("Assessment",
                      "₱${(req['amount_due'] ?? '0.00').toString()}", text),
                ],
              ),
              const SizedBox(height: 48),
              if (_isProcessing)
                const Center(child: LinearProgressIndicator(color: aViolet))
              else
                _buildStatusUpdateButtons(req, p),
              const Spacer(),
              _buildSecurityFooter(req),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic>? p, Map<String, dynamic>? d,
      String doc, Color t, Color s) {
    final String name = p != null
        ? "${p['fn'] ?? 'TBA'} ${p['ln'] ?? ''}".trim()
        : "Identity Pending";
    final String idNum =
        p != null ? (p['user_id_number'] ?? 'N/A').toString() : 'LRN-0000';
    final String course = d != null
        ? (d['courses']?['name'] ?? 'General').toString()
        : 'College Department';

    return Row(
      children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: aViolet.withOpacity(0.1),
            child: const Icon(LucideIcons.fileText, color: aViolet, size: 28)),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: aViolet,
                      letterSpacing: 0.5)),
              Text(name.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold, color: t)),
              Text("LRN: $idNum • $course",
                  style: TextStyle(color: s, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusUpdateButtons(
      Map<String, dynamic> req, Map<String, dynamic>? p) {
    if (p == null) return const SizedBox();
    final String currentStatus = (req['request_status'] ?? '').toString();
    bool isPaid = (req['payment_status'] ?? '').toString() == 'Paid';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statusBtn(
            "IN PROCESS",
            Colors.blueGrey,
            () => _updateRequestStatus('In Process', req, p),
            currentStatus == 'In Process'),
        _statusBtn(
            "READY FOR PICKUP",
            Colors.blue,
            () => _updateRequestStatus('Ready for Pickup', req, p),
            currentStatus == 'Ready for Pickup',
            enabled: isPaid),
        _statusBtn(
            "RELEASED",
            success,
            () => _updateRequestStatus('Released', req, p),
            currentStatus == 'Released',
            enabled: isPaid),
      ],
    );
  }

  Widget _statusBtn(
      String label, Color color, VoidCallback onTap, bool isActive,
      {bool enabled = true}) {
    return ElevatedButton(
      onPressed: (enabled && !isActive) ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : color.withOpacity(0.1),
        foregroundColor: isActive ? Colors.black : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _infoBox(String label, String value, Color vColor) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: GoogleFonts.inter(
                      color: vColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ],
          ),
        ),
      );

  Widget _buildSecurityFooter(Map<String, dynamic> req) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: aViolet.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: aViolet, size: 16),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    "System Verification Hash: ${(req['qr_hash'] ?? 'N/A').toString()}",
                    style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic))),
          ],
        ),
      );

  Widget _statusChip(String status) {
    Color c = status == "Released"
        ? success
        : (status == "Ready for Pickup"
            ? Colors.blueAccent
            : Colors.orangeAccent);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: c, fontSize: 8, fontWeight: FontWeight.w900)));
  }

  Widget _buildEmptyQueue(Color s) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.inbox, size: 40, color: s.withOpacity(0.2)),
        const SizedBox(height: 12),
        Text("Verification queue is clear.", style: TextStyle(color: s))
      ]));
  Widget _buildEmptyDetailState(Color t, Color s) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.fileSearch, size: 64, color: t.withOpacity(0.05)),
        const SizedBox(height: 24),
        Text("Audit document claims in the ledger.",
            style: TextStyle(color: s, fontWeight: FontWeight.bold))
      ]));
  Widget _buildErrorState(Color s, String msg) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.alertTriangle,
            color: Colors.redAccent, size: 32),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(color: s))
      ]));
  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(32),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _showManualEntryDialog() {}
}
