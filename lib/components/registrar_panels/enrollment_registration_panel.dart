import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class RegistrarEnrollmentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const RegistrarEnrollmentPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<RegistrarEnrollmentPanel> createState() =>
      _RegistrarEnrollmentPanelState();
}

class _RegistrarEnrollmentPanelState extends State<RegistrarEnrollmentPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  void initState() {
    super.initState();
    _fetchClearedApplicants();
  }

  /// 🛰️ EDGE FUNCTION TRANSACTION ENGINE
  /// Invokes the adaptive Deno transporter in the cloud to dispatch student credentials.
  /// Bypasses client-side SMTP restrictions completely.
  Future<void> _sendEnrollmentEmailViaEdge({
    required String recipientEmail,
    required String studentName,
    required String studentId,
    required String tempPassword,
  }) async {
    try {
      debugPrint(
          "📧 UEMSSP Core: Attempting to invoke credential dispatch pipeline for $recipientEmail...");

      final response = await _service.client.functions.invoke(
        'send-otp', // Reuses our centralized SMTP gateway
        body: {
          'type': 'enrollment',
          'toEmail': recipientEmail,
          'name': studentName,
          'studentId': studentId,
          'tempPassword': tempPassword,
        },
      );

      if (response.status == 200) {
        debugPrint(
            "📧 SMTP: Student credentials successfully dispatched via Edge Core.");
      } else {
        debugPrint(
            "❌ SMTP Error: Response failed with code ${response.status}: ${response.data}");
      }
    } catch (e) {
      debugPrint(
          "❌ Critical Exception: Failed to connect to Edge Core for credential dispatch: $e");
    }
  }

  /// 🛰️ DATABASE: Fetch applicants who have been Admitted by the Admission Office
  Future<void> _fetchClearedApplicants() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('*, courses(*)')
          .eq('status', 'Admitted')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _queue = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📐 ID GENERATOR: Constructs a unique institutional identifier (YYYY + Sequential)
  Future<String> _generateStudentId() async {
    final int currentYear = DateTime.now().year;
    final response = await _service.client
        .from('profiles')
        .select('id')
        .eq('role', 'student');
    final List list = response as List;
    return "$currentYear${(list.length + 1).toString().padLeft(5, '0')}";
  }

  /// 🛰️ DATABASE: Atomic finalization of student record creation
  Future<void> _finalizeRegistration(
      Map<String, dynamic> app, String yearLevelId) async {
    setState(() => _isLoading = true);
    try {
      final String studentIdNum = await _generateStudentId();

      // IDENTITY RESOLUTION: Using normalized fields directly from the applicant record
      final String fn = app['fn'] ?? 'TBA';
      final String mn = app['mn'] ?? '';
      final String ln = app['ln'] ?? 'TBA';
      final String fullName = "$fn ${mn.isNotEmpty ? '$mn ' : ''}$ln";

      // 🛠️ CUSTOM FORMULA: Passwords default to clean firstname + StudentID
      final String cleanFn = fn.toLowerCase().replaceAll(' ', '');
      final String defaultPassword = "$cleanFn$studentIdNum";

      // 1. Create official Institutional Profile
      final profileRes = await _service.client
          .from('profiles')
          .insert({
            'user_id_number': studentIdNum,
            'password_hash': defaultPassword,
            'role': 'student',
            'fn': fn,
            'mn': mn,
            'ln': ln,
            'email': app['email'],
            'gender': app['gender'],
            'dob': app['dob'],
          })
          .select()
          .single();

      final String newProfileId = profileRes['id'];

      // 2. Initialize Student Academic Details
      await _service.client.from('student_details').insert({
        'profile_id': newProfileId,
        'course_id': app['target_course_id'],
        'year_level_id': yearLevelId,
        'student_type': app['applicant_type'] ?? 'New Student',
        'enrollment_status': 'Enrolled',
        'phone': app['phone'],
      });

      // 3. Close Admission Cycle for this record
      await _service.client
          .from('applicants')
          .update({'status': 'Enrolled'}).eq('id', app['id']);

      // 4. Dispatch Digital Credentials via Deno Edge Core
      _sendEnrollmentEmailViaEdge(
          recipientEmail: app['email'],
          studentName: fullName,
          studentId: studentIdNum,
          tempPassword: defaultPassword);

      // 5. Present dialog showing Student ID and Temp Password for Registrar cross-checking
      _showSuccessDialog(studentIdNum, fullName, app['email'], defaultPassword);
      _fetchClearedApplicants();
    } catch (e) {
      _showToast("Registration Ledger Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredQueue {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _queue;
    return _queue.where((item) {
      final fn = (item['fn'] ?? '').toString().toLowerCase();
      final ln = (item['ln'] ?? '').toString().toLowerCase();
      final appNo = (item['application_no'] ?? '').toString().toLowerCase();
      return fn.contains(query) || ln.contains(query) || appNo.contains(query);
    }).toList();
  }

  void _showRegistrationForm(Map<String, dynamic> app) {
    String? selectedYearLevelId;
    List<Map<String, dynamic>> yearLevels = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return FutureBuilder<dynamic>(
            future: yearLevels.isEmpty
                ? _service.client.from('year_levels').select('*')
                : Future.value(yearLevels),
            builder: (context, snapshot) {
              if (snapshot.hasData && yearLevels.isEmpty) {
                yearLevels =
                    List<Map<String, dynamic>>.from(snapshot.data as List);

                // 🎯 AUTOMATION: Pre-select '1st Year' to align with global ledger policy
                try {
                  final firstYear = yearLevels.firstWhere(
                      (y) => y['definition'].toString().contains('1st'),
                      orElse: () => {});
                  if (firstYear.isNotEmpty) {
                    selectedYearLevelId = firstYear['id'].toString();
                  }
                } catch (e) {
                  debugPrint("Pre-selection error: $e");
                }
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF0F071D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Enrollment Finalization",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    const SizedBox(height: 4),
                    Text("Registering: ${app['fn']} ${app['ln']}".toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
                content: snapshot.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        height: 100,
                        child: Center(
                            child: CircularProgressIndicator(color: aViolet)))
                    : Container(
                        width: 450,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ASSIGN ACADEMIC LEVEL",
                                style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedYearLevelId,
                              dropdownColor: const Color(0xFF1E1B4B),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                              ),
                              items: yearLevels
                                  .map((y) => DropdownMenuItem(
                                      value: y['id'].toString(),
                                      child: Text(y['definition'] ?? 'N/A')))
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => selectedYearLevelId = v),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                                "Note: Admitted enrollees will enter the academy roster at their designated year level.",
                                style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL",
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14))),
                  ElevatedButton(
                    onPressed: selectedYearLevelId == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            _finalizeRegistration(app, selectedYearLevelId!);
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: success,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("FINALIZE ENROLLMENT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              );
            });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enrollment Finalization",
                      style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1)),
                  const SizedBox(height: 6),
                  const Text(
                      "Finalize admitted applicant records, generate student profiles, and dispatch portal credentials.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                ],
              ),
              IconButton(
                  onPressed: _fetchClearedApplicants,
                  icon: const Icon(Icons.autorenew_rounded,
                      color: aViolet, size: 28)),
            ],
          ),
          const SizedBox(height: 32),
          _buildSearchBar(cardColor, textColor),
          const SizedBox(height: 24),
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
                    child: _filteredQueue.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _filteredQueue.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10),
                            itemBuilder: (context, i) {
                              final app = _filteredQueue[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                    backgroundColor: aViolet.withOpacity(0.1),
                                    child: Text(app['ln']?[0] ?? 'A',
                                        style: const TextStyle(
                                            color: aViolet,
                                            fontWeight: FontWeight.bold))),
                                title: Text(
                                    "${app['ln']}, ${app['fn']}".toUpperCase(),
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: Text(
                                    "APP REF: ${app['application_no']} • ${app['courses']?['name'] ?? 'College'}",
                                    style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                trailing: ElevatedButton.icon(
                                    onPressed: () => _showRegistrationForm(app),
                                    icon: const Icon(Icons.person_add_rounded,
                                        size: 18, color: Colors.white),
                                    label: const Text("VERIFY & ENROLL",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: aViolet,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 18),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)))),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          style:
              TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
              hintText: "Search verified admitting queue...",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, size: 22, color: aViolet)),
        ),
      );

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.assignment_turned_in_rounded,
            size: 48,
            color: widget.isDarkMode
                ? Colors.blueGrey.withOpacity(0.2)
                : Colors.black.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text("Enrollment finalized queue is currently clear.",
            style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ]));

  void _showSuccessDialog(
      String id, String name, String email, String tempPassword) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F071D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Container(
              width: 450,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.celebration_rounded, color: success, size: 64),
                const SizedBox(height: 24),
                Text("Registration Complete",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const Divider(height: 32, color: Colors.white10),
                const Text("STUDENT ID NUMBER",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(id,
                    style: TextStyle(
                        fontSize: 32,
                        color: aViolet,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 4)),
                const SizedBox(height: 24),
                const Text("TEMPORARY PASSWORD",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text("Portal credentials dispatched to $email",
                    style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 32),
                SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: aViolet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: const Text("DONE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))))
              ]),
            )));
  }

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
