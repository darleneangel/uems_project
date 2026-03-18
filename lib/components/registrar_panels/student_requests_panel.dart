import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../services/supabase_service.dart';
import '../../widgets/windows_qr_scanner.dart'; // Import the working scanner widget

class StudentRequestsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRequestsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRequestsPanel> createState() => _StudentRequestsPanelState();
}

class _StudentRequestsPanelState extends State<StudentRequestsPanel> {
  String? _selectedRequestId;
  final TextEditingController _replyController = TextEditingController();
  bool _isProcessing = false;

  // Modern Tonal Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // --- 📷 STEP 1: SCANNER INTEGRATION ---

  /// Opens the Terminal Hub to scan a student's digital ticket
  void _openRequestScanner() {
    showDialog(
      context: context,
      builder: (cxt) => WindowsQRScanner(
        onScan: (code) {
          // THE FIX: Do NOT call Navigator.pop(cxt) here.
          // The WindowsQRScanner widget internally handles closing the dialog
          // to prevent the Navigator history from becoming empty (Black Screen).
          _handleScannedRequest(code);
        },
        onManualEntry: () {
          Navigator.pop(cxt);
          _showManualEntryDialog();
        },
      ),
    );
  }

  /// 🛰️ STEP 2: CLOUD LOOKUP (The logic that "finds" the request)
  Future<void> _handleScannedRequest(String hash) async {
    if (!mounted) return;

    setState(() => _isProcessing = true);
    final client = SupabaseService().client;

    try {
      // Find the request record matching the QR hash
      final result = await client
          .from('office_requests')
          .select('id')
          .eq('qr_hash', hash)
          .maybeSingle();

      // FOCUS SAFETY: Gives Windows time to return focus to the main window
      // after the scanner sub-window closes.
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result == null) {
        _showToast("Service Ticket not found in institutional ledger.",
            Colors.redAccent);
        return;
      }

      // Automatically "Select" the request to show details on the right panel
      setState(() {
        _selectedRequestId = result['id'];
      });

      _showToast("Identity Verified. Analyzing claim eligibility...", aViolet);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Sync Error: Hardware focus interrupted.", Colors.redAccent);
      }
    }
  }

  // --- SMTP NOTIFICATION ENGINE ---
  Future<void> _notifyStudentViaEmail({
    required String recipientEmail,
    required String studentName,
    required String docType,
    required String status,
  }) async {
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    const String appPassword = 'jnea wnbk atjg gyqi';

    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = const Address(senderEmail, 'SSCR Registrar Office')
      ..recipients.add(recipientEmail)
      ..subject = 'Document Update: $docType is $status'
      ..html = """
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 12px;'>
          <h2 style='color: #2E1065;'>Registrar Notification</h2>
          <p>Hello <b>$studentName</b>,</p>
          <p>The status of your request for <b>$docType</b> has been updated to: <span style='color: #8B5CF6; font-weight: bold;'>$status</span>.</p>
          <p>You may now log in to your student portal to view, download, or print your official digital copy.</p>
          <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
          <p style='font-size: 10px; color: #888;'>UEMS Cloud Service | San Sebastian College - Recoletos de Cavite</p>
        </div>
      """;

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  /// VALIDATION & RELEASE: Checks grades and authorizes digital access
  Future<void> _verifyAndAuthorize(
      Map<String, dynamic> req, Map<String, dynamic> profile) async {
    setState(() => _isProcessing = true);
    final client = SupabaseService().client;

    try {
      // 1. Data Integrity Check (Grades)
      final grades = await client
          .from('grades')
          .select('id, study_loads!inner(student_id)')
          .eq('study_loads.student_id', profile['id'])
          .limit(1);

      if (grades.isEmpty) {
        _showDialog(
            "Action Blocked",
            "This student has no encoded grades in the cloud ledger. Please coordinate with the Program Chair before releasing.",
            Colors.orange);
      } else {
        // 2. Update Status in Database
        await client.from('office_requests').update({
          'request_status': 'Ready for Pickup',
          'released_at': DateTime.now().toIso8601String(),
        }).eq('id', req['id']);

        // 3. Trigger Email
        await _notifyStudentViaEmail(
          recipientEmail: profile['email'],
          studentName: "${profile['fn']} ${profile['ln']}",
          docType: req['request_type'],
          status: "Ready for Access",
        );

        _showDialog(
            "Access Granted",
            "Digital authorization complete. Student has been notified via ${profile['email']}.",
            success);
      }
    } catch (e) {
      _showToast("Processing Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendReply(String receiverId) async {
    if (_replyController.text.isEmpty) return;
    final registrar = SupabaseService().client.auth.currentUser;

    try {
      await SupabaseService().client.from('messages').insert({
        'sender_id': registrar?.id,
        'receiver_id': receiverId,
        'content': _replyController.text,
      });

      if (mounted) {
        _replyController.clear();
        _showToast("Message synced to student portal.", aViolet);
      }
    } catch (e) {
      _showToast("Message Error: $e", Colors.redAccent);
    }
  }

  void _showManualEntryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (cxt) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text("Manual Ticket Lookup",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration:
              const InputDecoration(hintText: "Enter REQ-XXXX-XXXX Hash..."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(cxt), child: const Text("CANCEL")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(cxt);
                _handleScannedRequest(ctrl.text.trim());
              },
              child: const Text("VERIFY")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      children: [
        _buildTopHeader(textColor),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LEFT SIDE: LIVE REQUEST QUEUE
              Expanded(
                flex: 4,
                child: _buildRequestQueue(cardColor, textColor, subTextColor),
              ),
              const SizedBox(width: 24),
              // 2. RIGHT SIDE: CLOUD DETAIL VIEW
              Expanded(
                flex: 6,
                child: _selectedRequestId == null
                    ? _buildEmptyDetailState(textColor, subTextColor)
                    : _buildRequestDetailView(
                        cardColor, textColor, subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Scholastic Records Terminal",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            const Text(
                "Scan student claim tickets to authorize document access.",
                style: TextStyle(color: Colors.blueGrey)),
          ]),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _openRequestScanner,
            icon: const Icon(LucideIcons.scanLine),
            label: const Text("ACTIVATE SCANNER HUB"),
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

  Widget _buildRequestQueue(Color cardBg, Color text, Color subText) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Incoming Queue",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900, color: text, fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService().client.from('office_requests').stream(
                  primaryKey: ['id']).order('date_applied', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return Center(
                      child: Text("Queue is clear.",
                          style: TextStyle(color: subText)));
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final req = list[index];
                    bool isSelected = _selectedRequestId == req['id'];

                    return FutureBuilder(
                      future: SupabaseService()
                          .client
                          .from('profiles')
                          .select('fn, ln')
                          .eq('id', req['student_id'])
                          .maybeSingle(),
                      builder: (context, profileSnap) {
                        final String studentName = profileSnap.hasData &&
                                profileSnap.data != null
                            ? "${profileSnap.data!['fn']} ${profileSnap.data!['ln']}"
                            : "Loading Identity...";

                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedRequestId = req['id']),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            color: isSelected
                                ? aViolet.withOpacity(0.1)
                                : Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        req['qr_hash']
                                            .toString()
                                            .split('-')
                                            .last,
                                        style: const TextStyle(
                                            color: aViolet,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10)),
                                    _statusBadge(req['request_status']),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(studentName,
                                    style: TextStyle(
                                        color: text,
                                        fontWeight: FontWeight.bold)),
                                Text(req['request_type'],
                                    style: TextStyle(
                                        color: subText, fontSize: 13)),
                              ],
                            ),
                          ),
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

  Widget _buildRequestDetailView(Color cardBg, Color text, Color subText) {
    return FutureBuilder<Map<String, dynamic>>(
        future: SupabaseService()
            .client
            .from('office_requests')
            .select('*, profiles(*, student_details(courses(name)))')
            .eq('id', _selectedRequestId!)
            .single(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final req = snapshot.data!;
          final p = req['profiles'];

          // THE FIX: Robust check for student_details type
          final detailsRaw = p['student_details'];
          Map<String, dynamic>? details;

          if (detailsRaw is List && detailsRaw.isNotEmpty) {
            details = detailsRaw[0];
          } else if (detailsRaw is Map<String, dynamic>) {
            details = detailsRaw;
          }

          final String courseName =
              details?['courses']?['name'] ?? "BS Computer Science";

          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IDENTITY CARD
                _buildIdentityCard(p, details, req, text, subText),

                const SizedBox(height: 32),
                const Text("INSTITUTIONAL CLEARANCE CHECK",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const SizedBox(height: 16),

                // VERIFICATION SUMMARY CARD (Is paid? Is ready?)
                _buildVerificationSummary(req, text),

                const Divider(height: 48, color: Colors.white10),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Process & Authorization
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("AUTHORIZATION",
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueGrey,
                                    letterSpacing: 1)),
                            const SizedBox(height: 24),
                            _infoRow(
                                "Assessment:", "₱${req['amount_due']}", text),
                            _infoRow("Request Status:", req['request_status'],
                                aViolet),
                            const Spacer(),
                            if (_isProcessing)
                              const Center(
                                  child:
                                      CircularProgressIndicator(color: aViolet))
                            else
                              _buildActionButtons(req, p),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 40, color: Colors.white10),
                      // Messaging
                      Expanded(
                        flex: 1,
                        child: _buildMessagingThread(p, text, subText),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Widget _buildIdentityCard(
      Map<String, dynamic> p,
      Map<String, dynamic>? details,
      Map<String, dynamic> req,
      Color text,
      Color subText) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: aViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(LucideIcons.user, color: aViolet, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${p['fn'] ?? 'N/A'} ${p['ln'] ?? ''}",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: text, fontSize: 22)),
              Text(
                  "${p['user_id_number'] ?? 'N/A'} • ${details?['courses']?['name'] ?? 'General Program'}",
                  style: TextStyle(
                      color: subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: aViolet, borderRadius: BorderRadius.circular(12)),
          child: Text(req['request_type'],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildVerificationSummary(Map<String, dynamic> req, Color text) {
    bool isPaid = req['payment_status'] == 'Paid';
    bool isReady = req['request_status'] == 'Ready for Pickup' ||
        req['request_status'] == 'Released';

    return Row(
      children: [
        // Payment Summary
        Expanded(
          child: _statusTile(
              "Payment Status",
              isPaid ? "SETTLED" : "UNPAID",
              isPaid ? success : Colors.orangeAccent,
              isPaid ? LucideIcons.checkCircle2 : LucideIcons.alertCircle),
        ),
        const SizedBox(width: 16),
        // Readiness Summary
        Expanded(
          child: _statusTile(
              "Releasing Status",
              isReady ? "PREPARED" : "IN PROCESS",
              isReady ? success : aViolet,
              isReady ? LucideIcons.packageCheck : LucideIcons.clock),
        ),
      ],
    );
  }

  Widget _statusTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 10),
              Text(value,
                  style: GoogleFonts.inter(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> req, Map<String, dynamic> p) {
    bool isPaid = req['payment_status'] == 'Paid';
    bool isAlreadyReady = req['request_status'] == 'Ready for Pickup' ||
        req['request_status'] == 'Released';

    return Column(
      children: [
        if (!isPaid)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text("Verification locked until payment is settled.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: (isPaid && !isAlreadyReady)
                ? () => _verifyAndAuthorize(req, p)
                : null,
            icon: const Icon(LucideIcons.shieldCheck),
            label: const Text("APPROVE & RELEASE",
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagingThread(
      Map<String, dynamic> p, Color text, Color subText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("COMMUNICATION",
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1)),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService()
                .client
                .from('messages')
                .stream(primaryKey: ['id']),
            builder: (context, msgSnap) {
              if (!msgSnap.hasData) return const SizedBox();
              final msgs = msgSnap.data!
                  .where((m) =>
                      m['sender_id'] == p['id'] || m['receiver_id'] == p['id'])
                  .toList();
              return ListView.builder(
                  itemCount: msgs.length,
                  itemBuilder: (context, i) => _buildChatBubble(msgs[i], text));
            },
          ),
        ),
        _buildReplyInput(p['id'], text, subText),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, Color text) {
    bool isStudent =
        msg['sender_id'] != SupabaseService().client.auth.currentUser?.id;
    return Align(
      alignment: isStudent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isStudent ? Colors.white.withOpacity(0.05) : aViolet,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment:
              isStudent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(msg['content'],
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            const Text("Just now",
                style: TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(String studentId, Color text, Color subText) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: _replyController,
        style: TextStyle(color: text, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Reply to student...",
          hintStyle: TextStyle(color: subText, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: IconButton(
              icon: const Icon(LucideIcons.send, size: 18, color: aViolet),
              onPressed: () => _sendReply(studentId)),
        ),
      ),
    );
  }

  Widget _infoRow(String l, String v, Color c) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l,
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Text(v,
            style:
                TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w900))
      ]));
  Widget _buildEmptyDetailState(Color text, Color subText) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.mousePointer2, color: text.withOpacity(0.1), size: 64),
        const SizedBox(height: 16),
        Text("Scan ticket or select a request to begin verification.",
            textAlign: TextAlign.center, style: TextStyle(color: subText))
      ]));

  Widget _statusBadge(String status) {
    Color color = status == "Released"
        ? success
        : (status == "Ready for Pickup"
            ? Colors.blueAccent
            : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.inter(
              color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  void _showDialog(String t, String m, Color c) {
    showDialog(
        context: context,
        builder: (cxt) => AlertDialog(
                backgroundColor: surfaceDark,
                title: Text(t,
                    style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                content: Text(m, style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(cxt),
                      child: const Text("OK"))
                ]));
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
