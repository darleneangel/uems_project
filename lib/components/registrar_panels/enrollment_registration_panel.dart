import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../services/supabase_service.dart';

class RegistrarEnrollmentPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const RegistrarEnrollmentPanel(
      {super.key, required this.isDarkMode, required this.userData});

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

  @override
  void initState() {
    super.initState();
    _fetchClearedApplicants();
  }

  /// 📧 SMTP NOTIFICATION ENGINE
  /// Dispatches institutional credentials to the student's registered email
  Future<void> _sendEnrollmentEmail({
    required String recipientEmail,
    required String studentName,
    required String studentId,
    required String tempPassword,
  }) async {
    const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
    const String appPassword = 'jnea wnbk atjg gyqi';
    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = const Address(senderEmail, 'Bright Future Academy Registrar')
      ..recipients.add(recipientEmail)
      ..subject = 'Official Enrollment Confirmation - Bright Future Academy'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 40px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 24px;'>WELCOME TO THE ACADEMY</h1>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>$studentName</b>,</p>
            <p>Your institutional portal access has been provisioned. Please use the following credentials to access your student dashboard:</p>
            <div style='background-color: #f8fafc; padding: 20px; border-radius: 12px; margin: 20px 0; border: 1px dashed #cbd5e1;'>
              <p style='margin: 0; font-size: 11px; color: #64748b;'>STUDENT ID NUMBER</p>
              <p style='margin: 5px 0 15px 0; font-size: 22px; font-weight: bold; color: #8B5CF6;'>$studentId</p>
              <p style='margin: 0; font-size: 11px; color: #64748b;'>TEMPORARY PASSWORD</p>
              <p style='margin: 5px 0 0 0; font-size: 18px; font-weight: bold; color: #1e293b;'>$tempPassword</p>
            </div>
            <p style='font-size: 13px; color: #475569;'>You are required to update your security credentials upon first login.</p>
          </div>
        </div>
      """;
    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Credential Dispatch Error: $e');
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

      // Temporary password defaults to lowercase last name
      final String defaultPassword = ln.toLowerCase().replaceAll(' ', '');

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
      // Mapping 'year_level_id' which is now strictly a UUID reference
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

      // 4. Dispatch Digital Credentials
      _sendEnrollmentEmail(
          recipientEmail: app['email'],
          studentName: fullName,
          studentId: studentIdNum,
          tempPassword: defaultPassword);

      _showSuccessDialog(studentIdNum, fullName, app['email']);
      _fetchClearedApplicants();
    } catch (e) {
      _showToast("Registration Ledger Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredQueue {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _queue;
    return _queue.where((item) {
      final fn = (item['fn'] ?? '').toString().toLowerCase();
      final ln = (item['ln'] ?? '').toString().toLowerCase();
      return fn.contains(query) || ln.contains(query);
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
                backgroundColor: surfaceDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Enrollment Finalization",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Registering: ${app['fn']} ${app['ln']}".toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey,
                            letterSpacing: 1)),
                  ],
                ),
                content: snapshot.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        height: 100,
                        child: Center(
                            child: CircularProgressIndicator(color: aViolet)))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedYearLevelId,
                            dropdownColor: surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Assign Year Level",
                              labelStyle: const TextStyle(
                                  color: Colors.blueGrey, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                            // Mapping to the 'definition' column from public.year_levels
                            items: yearLevels
                                .map((y) => DropdownMenuItem(
                                    value: y['id'].toString(),
                                    child: Text(y['definition'] ?? 'N/A')))
                                .toList(),
                            onChanged: (v) =>
                                setModalState(() => selectedYearLevelId = v),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                              "Note: New enrollees typically enter as 1st Year students.",
                              style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL")),
                  ElevatedButton(
                    onPressed: selectedYearLevelId == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            _finalizeRegistration(app, selectedYearLevelId!);
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: success,
                        foregroundColor: Colors.black),
                    child: const Text("FINALIZE ENROLLMENT"),
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
                  Text("Enrollment Verification",
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const Text(
                      "Finalize verified applicant records and generate institutional credentials.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                ],
              ),
              IconButton(
                  onPressed: _fetchClearedApplicants,
                  icon: const Icon(LucideIcons.refreshCw, color: aViolet)),
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
                        border: Border.all(color: Colors.white10)),
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
                                        fontSize: 14)),
                                subtitle: Text(
                                    "REF: ${app['application_no']} • ${app['courses']?['name'] ?? 'College'}",
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 11)),
                                trailing: ElevatedButton.icon(
                                    onPressed: () => _showRegistrationForm(app),
                                    icon: const Icon(LucideIcons.userCheck,
                                        size: 14),
                                    label: const Text("VERIFY & ENROLL",
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: aViolet,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          style: TextStyle(color: text),
          decoration: const InputDecoration(
              hintText: "Search verified queue...",
              border: InputBorder.none,
              prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet)),
        ),
      );

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.clipboardCheck, // Ensure visibility in light mode
            size: 48,
            color: widget.isDarkMode
                ? Colors.blueGrey.withOpacity(0.2)
                : Colors.black.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text("Verification queue is currently clear.",
            style:
                TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
      ]));

  void _showSuccessDialog(String id, String name, String email) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: surfaceDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.partyPopper, color: success, size: 64),
              const SizedBox(height: 24),
              Text("Registration Complete",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(name.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Divider(height: 32, color: Colors.white10),
              Text(id,
                  style: GoogleFonts.orbitron(
                      fontSize: 32,
                      color: aViolet,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              const SizedBox(height: 8),
              Text("Portal credentials dispatched to $email",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
              const SizedBox(height: 32),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("DONE")))
            ])));
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
