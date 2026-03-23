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
  List<Map<String, dynamic>> _allApplicants = [];
  List<Map<String, dynamic>> _requirements = [];

  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  /// 🛰️ DATABASE: Fetches applicants with 'Pending' status (Needs Document Audit)
  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('id, fn, ln, application_no, status, created_at')
          .eq('status', 'Pending')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _allApplicants = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequirements(String applicantId, String name) async {
    setState(() {
      _isLoading = true;
      _selectedApplicantId = applicantId;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRequirement(String reqId, bool val) async {
    try {
      await _service.client.from('applicant_requirements').update({
        'is_verified': val,
        'verified_at': val ? DateTime.now().toIso8601String() : null
      }).eq('id', reqId);
      _loadRequirements(_selectedApplicantId!, _selectedApplicantName!);
    } catch (e) {
      debugPrint("Toggle Error: $e");
    }
  }

  /// 🛰️ STEP 1: Moves student to 'Verified' status
  /// This triggers their appearance in the Enrollment Verification (Policy Audit) Panel.
  Future<void> _completeVerification() async {
    if (_selectedApplicantId == null) return;
    setState(() => _isActionLoading = true);
    try {
      await _service.client
          .from('applicants')
          .update({'status': 'Verified'}).eq('id', _selectedApplicantId!);

      if (mounted) {
        _showSuccessDialog();
        setState(() {
          _selectedApplicantId = null;
          _requirements = [];
          _isActionLoading = false;
        });
        _fetchApplicants();
      }
    } catch (e) {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  bool get _canFinalize =>
      _requirements.isNotEmpty &&
      _requirements.every((req) => req['is_verified'] == true);

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
          // LEFT: QUEUE
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Verification Queue",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontSize: 20)),
                const Text("Initial Document Audit",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: _isLoading && _allApplicants.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: _allApplicants.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10),
                            itemBuilder: (context, i) {
                              final app = _allApplicants[i];
                              return ListTile(
                                title: Text(
                                    "${app['ln']}, ${app['fn']}".toUpperCase(),
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                subtitle: Text(app['application_no'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 11)),
                                onTap: () => _loadRequirements(
                                    app['id'], "${app['fn']} ${app['ln']}"),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // RIGHT: CHECKLIST
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10)),
              child: _selectedApplicantId == null
                  ? const Center(
                      child: Text("Select an applicant to verify documents"))
                  : Column(
                      children: [
                        Text("Checklist for $_selectedApplicantName",
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.bold)),
                        const Divider(height: 40),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _requirements.length,
                            itemBuilder: (context, i) => CheckboxListTile(
                              title: Text(_requirements[i]['requirement_name'],
                                  style: TextStyle(
                                      color: textColor, fontSize: 13)),
                              value: _requirements[i]['is_verified'],
                              onChanged: (v) => _toggleRequirement(
                                  _requirements[i]['id'], v!),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed:
                                _canFinalize ? _completeVerification : null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6)),
                            child: const Text("PROMOTE TO POLICY AUDIT"),
                          ),
                        )
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("Verified"),
                content: const Text(
                    "Document audit complete. Student promoted to Policy Audit."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"))
                ]));
  }
}
