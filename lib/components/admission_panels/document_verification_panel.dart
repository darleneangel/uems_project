import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class DocumentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const DocumentVerificationPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<DocumentVerificationPanel> createState() =>
      _DocumentVerificationPanelState();
}

class _DocumentVerificationPanelState extends State<DocumentVerificationPanel> {
  final SupabaseService _service = SupabaseService();
  String? _selectedApplicantId;
  String? _selectedApplicantName;
  List<Map<String, dynamic>> _pendingApplicants = [];
  List<Map<String, dynamic>> _requirements = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingApplicants();
  }

  /// 🛰️ DATABASE: Load applicants who are currently in 'Pending' status
  /// Normalized logic: Constructs the display name from granular components
  Future<void> _loadPendingApplicants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('id, fn, ln, application_no')
          .eq('status', 'Pending')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _pendingApplicants = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Applicants Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Load the institutional requirement checklist for the chosen applicant
  Future<void> _loadRequirements(String applicantId, String name) async {
    setState(() {
      _isLoading = true;
      _selectedApplicantName = name;
    });
    try {
      final response = await _service.client
          .from('applicant_requirements')
          .select('*')
          .eq('applicant_id', applicantId)
          .order('requirement_name', ascending: true);

      if (mounted) {
        setState(() {
          _requirements = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Requirements Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Toggle individual document verification status
  Future<void> _toggleRequirement(String reqId, bool val) async {
    try {
      await _service.client.from('applicant_requirements').update({
        'is_verified': val,
        'verified_at': val ? DateTime.now().toIso8601String() : null
      }).eq('id', reqId);

      // Refresh the local checklist view
      _loadRequirements(_selectedApplicantId!, _selectedApplicantName!);
    } catch (e) {
      debugPrint("Requirement Toggle Error: $e");
    }
  }

  /// 🛰️ DATABASE: Finalize verification and move applicant to the Enrollment Policy Audit queue
  Future<void> _completeVerification() async {
    if (_selectedApplicantId == null) return;

    setState(() => _isActionLoading = true);
    try {
      // Transition status to 'Verified' to appear in EnrollmentVerificationPanel
      await _service.client
          .from('applicants')
          .update({'status': 'Verified'}).eq('id', _selectedApplicantId!);

      if (mounted) {
        _showSuccessDialog();
        setState(() {
          _selectedApplicantId = null;
          _selectedApplicantName = null;
          _requirements = [];
          _isActionLoading = false;
        });
        _loadPendingApplicants();
      }
    } catch (e) {
      debugPrint("Verification Completion Error: $e");
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  bool get _canFinalize =>
      _requirements.isNotEmpty &&
      _requirements.every((req) => req['is_verified'] == true);

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Color(0xFF69F0AE)),
            SizedBox(width: 12),
            Text("Verification Complete",
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
            "$_selectedApplicantName has been cleared for policy evaluation and final admission audit.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text("PROCEED"),
          )
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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT SIDE: PENDING ROSTER ---
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Document Verification Queue",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontSize: 20)),
                const Text(
                    "Select an applicant to audit submitted credentials.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: _isLoading && _pendingApplicants.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF8B5CF6)))
                        : _pendingApplicants.isEmpty
                            ? const Center(
                                child: Text(
                                    "All pending documents have been verified.",
                                    style: TextStyle(color: Colors.blueGrey)))
                            : ListView.separated(
                                itemCount: _pendingApplicants.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Colors.white10, height: 1),
                                itemBuilder: (context, i) {
                                  final app = _pendingApplicants[i];
                                  final isSelected =
                                      _selectedApplicantId == app['id'];
                                  final String name =
                                      "${app['ln'] ?? 'TBA'}, ${app['fn'] ?? 'TBA'}"
                                          .toUpperCase();

                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: const Color(0xFF8B5CF6)
                                        .withOpacity(0.1),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF8B5CF6)
                                          : Colors.white10,
                                      child: Icon(LucideIcons.fileText,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.blueGrey,
                                          size: 16),
                                    ),
                                    title: Text(name,
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13)),
                                    subtitle: Text(
                                        app['application_no'] ?? 'NO-REF',
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 11)),
                                    onTap: () {
                                      setState(() =>
                                          _selectedApplicantId = app['id']);
                                      _loadRequirements(app['id'], name);
                                    },
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // --- RIGHT SIDE: DOCUMENT CHECKLIST ---
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Submission Audit",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontSize: 20)),
                const Text(
                    "Tick items once physical copies are received and verified.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: _selectedApplicantId == null
                        ? Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardCheck,
                                  size: 48,
                                  color: Colors.blueGrey.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              const Text(
                                  "Select an applicant from the roster to begin verification.",
                                  style: TextStyle(color: Colors.blueGrey)),
                            ],
                          ))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedApplicantName!,
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              color: textColor)),
                                      const Text(
                                          "Required Institutional Documents",
                                          style: TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  if (_canFinalize)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF69F0AE)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Text("CLEARANCE READY",
                                          style: TextStyle(
                                              color: Color(0xFF69F0AE),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                    ),
                                ],
                              ),
                              const Divider(height: 48, color: Colors.white10),
                              Expanded(
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: Color(0xFF8B5CF6)))
                                    : ListView.builder(
                                        itemCount: _requirements.length,
                                        itemBuilder: (context, i) {
                                          final req = _requirements[i];
                                          final bool verified =
                                              req['is_verified'] ?? false;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.03),
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: CheckboxListTile(
                                              title: Text(
                                                  req['requirement_name'],
                                                  style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 13,
                                                      fontWeight: verified
                                                          ? FontWeight.bold
                                                          : FontWeight.normal)),
                                              subtitle: Text(
                                                  verified
                                                      ? "Verified on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(req['verified_at']))}"
                                                      : "Awaiting physical submission",
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blueGrey)),
                                              value: verified,
                                              activeColor:
                                                  const Color(0xFF8B5CF6),
                                              onChanged: (v) =>
                                                  _toggleRequirement(
                                                      req['id'], v!),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton.icon(
                                  onPressed: (_canFinalize && !_isActionLoading)
                                      ? _completeVerification
                                      : null,
                                  icon: _isActionLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(LucideIcons.checkCircle),
                                  label: const Text(
                                      "FINALIZE & PROMOTE TO AUDIT",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    disabledBackgroundColor:
                                        Colors.white.withOpacity(0.05),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
