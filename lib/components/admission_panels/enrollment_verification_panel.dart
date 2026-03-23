import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class EnrollmentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const EnrollmentVerificationPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<EnrollmentVerificationPanel> createState() =>
      _EnrollmentVerificationPanelState();
}

class _EnrollmentVerificationPanelState
    extends State<EnrollmentVerificationPanel> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _allBylaws = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch metadata (Bylaws)
      final bylawRes =
          await _service.client.from('admission_bylaws').select('*');

      // 2. Fetch applicants who need review (Pending, Conditional) or final handover (Verified)
      final response = await _service.client
          .from('applicants')
          .select('*, courses(name, code), admission_bylaws(description, code)')
          .filter('status', 'in', '("Pending", "Verified", "Conditional")')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _queue = List<Map<String, dynamic>>.from(response);
          _allBylaws = List<Map<String, dynamic>>.from(bylawRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📝 POLICY REVIEW: Evaluation logic migrated from Applications Management
  void _processPolicyDecision(Map<String, dynamic> applicant) {
    String selectedStatus = applicant['status'] ?? 'Pending';
    String? selectedBylawId = applicant['rejection_bylaw_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Policy Evaluation Audit",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, color: Colors.white)),
              Text("Reviewing: ${applicant['fn']} ${applicant['ln']}",
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fieldLabel("ADMISSION DECISION"),
              DropdownButtonFormField<String>(
                initialValue: ['Pending', 'Verified', 'Rejected', 'Conditional']
                        .contains(selectedStatus)
                    ? selectedStatus
                    : 'Pending',
                dropdownColor: const Color(0xFF1E1B4B),
                style: const TextStyle(color: Colors.white),
                decoration: _fieldInput("Current Evaluation"),
                items: [
                  {'val': 'Pending', 'label': 'PENDING REVIEW'},
                  {'val': 'Verified', 'label': 'APPROVE & VERIFY'},
                  {'val': 'Rejected', 'label': 'REJECT APPLICATION'},
                  {'val': 'Conditional', 'label': 'PLACE ON PROBATION'},
                ]
                    .map((s) => DropdownMenuItem(
                        value: s['val'], child: Text(s['label']!.toString())))
                    .toList(),
                onChanged: (v) => setModalState(() {
                  selectedStatus = v!;
                  selectedBylawId = null;
                }),
              ),
              const SizedBox(height: 20),
              _fieldLabel("OFFICIAL POLICY BASIS"),
              DropdownButtonFormField<String>(
                initialValue: selectedBylawId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1B4B),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: _fieldInput("Institutional Clause"),
                items: _allBylaws
                    .where((b) {
                      if (selectedStatus == 'Verified') {
                        return b['category'] == 'Approval';
                      }
                      if (selectedStatus == 'Rejected') {
                        return b['category'] == 'Rejection';
                      }
                      if (selectedStatus == 'Conditional') {
                        return b['category'] == 'Conditional';
                      }
                      return false;
                    })
                    .map((b) => DropdownMenuItem(
                        value: b['id'].toString(),
                        child: Text("${b['code']}: ${b['description']}",
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedBylawId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                await _commitDecision(
                    applicant['id'], selectedStatus, selectedBylawId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6)),
              child: Text("SUBMIT EVALUATION",
                  style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _commitDecision(
      String appId, String status, String? bylawId) async {
    try {
      await _service.client.from('applicants').update({
        'status': status,
        'rejection_bylaw_id': bylawId,
      }).eq('id', appId);
      _loadData();
    } catch (e) {
      debugPrint("DB Update Error: $e");
    }
  }

  /// 🛰️ HANDOVER: Moves 'Verified' applicants to 'Admitted' and alerts Accounting
  Future<void> _finalizeEnrollment(Map<String, dynamic> app) async {
    try {
      await _service.client
          .from('applicants')
          .update({'status': 'Admitted'}).eq('id', app['id']);

      await _service.client.from('office_requests').insert({
        'qr_hash':
            'REG-${app['application_no']}-${DateTime.now().millisecondsSinceEpoch}',
        'request_type': 'Registration Fee',
        'status': 'Pending Payment',
        'amount_due': 2000.00,
        'remarks':
            'Enrollment handover for ${app['fn']} ${app['ln']}. Approved by Admissions.',
      });

      _loadData();
      _showHandoverSuccess("${app['fn']} ${app['ln']}");
    } catch (e) {
      debugPrint("Handover Error: $e");
    }
  }

  void _showHandoverSuccess(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("Handover Successful",
            style: TextStyle(color: Colors.white)),
        content: Text(
            "Applicant $name has been officially admitted. Accounting has been notified of the registration fee.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: Colors.black),
              child: const Text("CONTINUE"))
        ],
      ),
    );
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
        Text("Enrollment Verification & Policy Audit",
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
        const Text(
            "Evaluate applicants against institutional bylaws and release verified students to Accounting.",
            style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _queue.isEmpty
                  ? const Center(
                      child: Text("Verification queue is currently clear.",
                          style: TextStyle(color: Colors.blueGrey)))
                  : Container(
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10)),
                      child: ListView.separated(
                        itemCount: _queue.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, i) {
                          final app = _queue[i];
                          final isVerified = app['status'] == 'Verified';
                          final bylaw = app['admission_bylaws'];

                          return ListTile(
                            contentPadding: const EdgeInsets.all(24),
                            leading: CircleAvatar(
                              backgroundColor: (isVerified
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFF8B5CF6))
                                  .withOpacity(0.1),
                              child: Icon(
                                  isVerified
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.fileSearch,
                                  color: isVerified
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFF8B5CF6)),
                            ),
                            title: Text(
                                "${app['ln']}, ${app['fn']}".toUpperCase(),
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Ref: ${app['application_no']} • ${app['courses']?['name']}",
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 11)),
                                if (bylaw != null)
                                  Text(
                                      "Basis: ${bylaw['code']} - ${bylaw['description']}",
                                      style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: isVerified
                                ? _actionBtn(
                                    "RELEASE TO ACCOUNTING",
                                    LucideIcons.send,
                                    () => _finalizeEnrollment(app),
                                    color: const Color(0xFF8B5CF6))
                                : _actionBtn(
                                    "PROCESS EVALUATION",
                                    LucideIcons.gavel,
                                    () => _processPolicyDecision(app),
                                    color: Colors.blueGrey),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap,
          {required Color color}) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
      );

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1))));

  InputDecoration _fieldInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}
