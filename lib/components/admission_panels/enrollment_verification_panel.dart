import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class EnrollmentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const EnrollmentVerificationPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

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

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD740);

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
    String selectedStatus = applicant['status'] == 'Verified'
        ? 'Admitted'
        : (applicant['status'] ?? 'Pending');
    String? selectedBylawId = applicant['rejection_bylaw_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F071D),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Policy Evaluation Audit",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                  "Reviewing: ${applicant['fn']} ${applicant['ln']}"
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fieldLabel("ADMISSION DECISION"),
                DropdownButtonFormField<String>(
                  value: ['Pending', 'Admitted', 'Rejected', 'Conditional']
                          .contains(selectedStatus)
                      ? selectedStatus
                      : 'Pending',
                  dropdownColor: const Color(0xFF1E1B4B),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  decoration: _fieldInput("Decision"),
                  items: [
                    {'val': 'Pending', 'label': 'PENDING REVIEW'},
                    {'val': 'Admitted', 'label': 'APPROVE & ADMIT STUDENT'},
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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  decoration: _fieldInput("Select Clause"),
                  items: _allBylaws
                      .where((b) {
                        if (selectedStatus == 'Admitted') {
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
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("CANCEL",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
            ElevatedButton(
              onPressed: () async {
                // FIXED FLOW: Close dialog immediately to prevent context layering issues
                Navigator.pop(dialogContext);

                // Commit decision, reload parent UI, and present handover pop-up
                await _commitDecision(
                    applicant, selectedStatus, selectedBylawId);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text("SUBMIT & RELEASE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }

  /// 🛰️ DATABASE: Commits status and CRITICALLY triggers the Accounting Ticket.
  Future<void> _commitDecision(
      Map<String, dynamic> app, String status, String? bylawId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

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
        await _loadData();
      }
    } catch (e) {
      debugPrint("Handover Update Error: $e");
      if (mounted) setState(() => _isLoading = false);
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

      // Reload first, then display Success modal with details directed to Accounting
      await _loadData();
      _showSuccess(
        "${app['fn']} ${app['ln']} has been successfully approved for institutional admission.\n\n"
        "DIRECTED TO ACCOUNTING: The student registration ledger has been initialized. "
        "A pending Registration Fee ticket (₱2,000.00) has been created in the Accounting Office system.",
      );
    } catch (e) {
      debugPrint("Ticket Creation Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF0F071D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: success, size: 32),
                    const SizedBox(width: 12),
                    Text("Handover Successful",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 18)),
                  ],
                ),
                content: Container(
                  width: 450,
                  child: Text(msg,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14, height: 1.5)),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("UNDERSTOOD",
                          style: TextStyle(
                              color: aViolet,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)))
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
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1)),
        const SizedBox(height: 6),
        const Text(
            "Audit verified applicants and promote them to 'Admitted' status to initialize Accounting Ledgers.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: aViolet))
              : Container(
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: widget.isDarkMode
                              ? Colors.white10
                              : Colors.black12)),
                  child: _queue.isEmpty
                      ? const Center(
                          child: Text("No applicants awaiting policy audit.",
                              style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)))
                      : ListView.separated(
                          itemCount: _queue.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, i) {
                            final app = _queue[i];
                            final isVerified = app['status'] == 'Verified';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 22),
                              // GLYPH FIX: Replaced custom LucideIcons with high-fidelity Material Icons to protect from web rendering bugs
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isVerified
                                    ? success.withOpacity(0.1)
                                    : aViolet.withOpacity(0.1),
                                child: Icon(
                                    isVerified
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.find_in_page_rounded,
                                    color: isVerified ? success : aViolet,
                                    size: 24),
                              ),
                              title: Text(
                                  "${app['ln']}, ${app['fn']}".toUpperCase(),
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                      "Program Track: ${app['courses']?['name'] ?? 'TBA'} (${app['courses']?['code'] ?? ''})",
                                      style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  _statusBadge(
                                      app['status'].toString().toUpperCase(),
                                      isVerified ? success : warning),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _processPolicyDecision(app),
                                icon: const Icon(Icons.gavel_rounded, size: 18),
                                label: const Text("AUDIT POLICIES",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isVerified ? aViolet : Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1))));

  InputDecoration _fieldInput(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none));
}
