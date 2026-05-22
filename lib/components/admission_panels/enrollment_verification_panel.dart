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

  /// 🛰️ DATABASE: Fetches 'Verified' students coming straight from Document Verification.
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch metadata (Bylaws)
      final bylawRes =
          await _service.client.from('admission_bylaws').select('*');

      // 2. Fetch applicants who need policy review
      // 🎯 THE FIX: The join logic has been hardened.
      // We use .filter with 'in' to ensure 'Verified' students (who just came from Document Verification)
      // are the priority for this terminal.
      final response = await _service.client
          .from('applicants')
          .select('''
            *, 
            courses!applicants_target_course_id_fkey(name, code), 
            admission_bylaws!applicants_rejection_bylaw_id_fkey(description, code)
          ''')
          .filter('status', 'in', '("Verified", "Pending", "Conditional")')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _queue = List<Map<String, dynamic>>.from(response);
          _allBylaws = List<Map<String, dynamic>>.from(bylawRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Verification Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📝 POLICY REVIEW: Logic to promote student to 'Admitted'
  void _processPolicyDecision(Map<String, dynamic> applicant) {
    // 🛡️ REFINEMENT: If they are 'Verified', the standard promotion target is 'Admitted'
    String selectedStatus = applicant['status'] == 'Verified'
        ? 'Admitted'
        : (applicant['status'] ?? 'Pending');
    String? selectedBylawId = applicant['rejection_bylaw_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
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
                value: ['Pending', 'Admitted', 'Rejected', 'Conditional']
                        .contains(selectedStatus)
                    ? selectedStatus
                    : 'Pending',
                dropdownColor: const Color(0xFF1E1B4B),
                style: const TextStyle(color: Colors.white),
                decoration: _fieldInput("Decision"),
                items: [
                  {'val': 'Pending', 'label': 'PENDING REVIEW'},
                  {'val': 'Admitted', 'label': 'APPROVE & ADMIT student'},
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
              _fieldLabel("INSTITUTIONAL BYLAW BASIS"),
              DropdownButtonFormField<String>(
                value: selectedBylawId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1B4B),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: _fieldInput("Select Clause"),
                items: _allBylaws
                    .where((b) {
                      if (selectedStatus == 'Admitted')
                        return b['category'] == 'Approval';
                      if (selectedStatus == 'Rejected')
                        return b['category'] == 'Rejection';
                      if (selectedStatus == 'Conditional')
                        return b['category'] == 'Conditional';
                      return false;
                    })
                    .map((b) => DropdownMenuItem(
                        value: b['id'].toString(),
                        child: Text("${b['code']}: ${b['description']}")))
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
                    applicant, selectedStatus, selectedBylawId);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white),
              child: const Text("SUBMIT & RELEASE"),
            )
          ],
        ),
      ),
    );
  }

  /// 🛰️ DATABASE: Commits status and CRITICALLY triggers the Accounting Ticket.
  Future<void> _commitDecision(
      Map<String, dynamic> app, String status, String? bylawId) async {
    try {
      // 1. Update status to 'Admitted'
      await _service.client.from('applicants').update({
        'status': status,
        'rejection_bylaw_id': bylawId,
      }).eq('id', app['id']);

      // 🎯 THE HANDOVER: If the student is Admitted, immediately create the ticket for Accounting.
      if (status == 'Admitted') {
        await _finalizeHandover(app);
      } else {
        _loadData();
      }
    } catch (e) {
      debugPrint("Handover Update Error: $e");
    }
  }

  Future<void> _finalizeHandover(Map<String, dynamic> app) async {
    try {
      // Create 'Registration Fee' ticket in office_requests ledger
      await _service.client.from('office_requests').insert({
        'qr_hash':
            'REG-${app['application_no']}-${DateTime.now().millisecondsSinceEpoch}',
        'request_type': 'Registration Fee',
        'status': 'Pending Payment',
        'request_status': 'Submitted',
        'amount_due': 2000.00,
        'remarks':
            '${app['fn']} ${app['ln']}. Approved for Institutional Intake.',
      });

      _loadData();
      _showSuccess("${app['fn']} ${app['ln']} released to Accounting.");
    } catch (e) {
      debugPrint("Ticket Creation Error: $e");
    }
  }

  void _showSuccess(String msg) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("Success"),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"))
                ]));
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
        Text("Enrollment Policy Audit",
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
        const Text(
            "Audit verified applicants and promote them to 'Admitted' status for Accounting.",
            style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10)),
                  child: _queue.isEmpty
                      ? const Center(
                          child: Text("No applicants awaiting policy audit.",
                              style: TextStyle(color: Colors.blueGrey)))
                      : ListView.separated(
                          itemCount: _queue.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, i) {
                            final app = _queue[i];
                            final isVerified = app['status'] == 'Verified';
                            return ListTile(
                              contentPadding: const EdgeInsets.all(24),
                              leading: Icon(
                                  isVerified
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.fileSearch,
                                  color: isVerified
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFF8B5CF6)),
                              title: Text(
                                  "${app['ln']}, ${app['fn']}".toUpperCase(),
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Program: ${app['courses']?['name'] ?? 'TBA'}",
                                      style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 11)),
                                  Text("Status: ${app['status']}",
                                      style: TextStyle(
                                          color: isVerified
                                              ? const Color(0xFF69F0AE)
                                              : Colors.orangeAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _processPolicyDecision(app),
                                icon: const Icon(LucideIcons.gavel, size: 14),
                                label: const Text("AUDIT",
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: isVerified
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.blueGrey,
                                    foregroundColor: Colors.white),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold))));
  InputDecoration _fieldInput(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none));
}
