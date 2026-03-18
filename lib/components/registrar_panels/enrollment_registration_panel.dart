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
      ..from = const Address(senderEmail, 'UEMSSP Registrar Office')
      ..recipients.add(recipientEmail)
      ..subject = 'Official Enrollment Confirmation - Bright Future Academy'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 40px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 24px;'>WELCOME TO THE ACADEMY</h1>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>$studentName</b>,</p>
            <p>Your portal access credentials have been generated:</p>
            <div style='background-color: #f8fafc; padding: 20px; border-radius: 12px; margin: 20px 0; border: 1px dashed #cbd5e1;'>
              <p style='margin: 0; font-size: 11px; color: #64748b;'>STUDENT ID NUMBER</p>
              <p style='margin: 5px 0 15px 0; font-size: 22px; font-weight: bold; color: #8B5CF6;'>$studentId</p>
              <p style='margin: 0; font-size: 11px; color: #64748b;'>TEMPORARY PASSWORD</p>
              <p style='margin: 5px 0 0 0; font-size: 18px; font-weight: bold; color: #1e293b;'>$tempPassword</p>
            </div>
            <p style='font-size: 13px; color: #475569;'>You are required to change this password immediately upon logging in for the first time.</p>
          </div>
        </div>
      """;
    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Error: $e');
    }
  }

  Future<void> _fetchClearedApplicants() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('*, courses(*)')
          .or('status.eq.Ready for Registration,status.eq.Admitted')
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

  Future<String> _generateStudentId() async {
    final int currentYear = DateTime.now().year;
    final response = await _service.client
        .from('profiles')
        .select('id')
        .eq('role', 'student');
    final List list = response as List;
    return "$currentYear${(list.length + 1).toString().padLeft(5, '0')}";
  }

  Future<void> _finalizeRegistration(
      Map<String, dynamic> app, String yearLevelId) async {
    setState(() => _isLoading = true);
    try {
      final String studentIdNum = await _generateStudentId();
      final nameParts = app['full_name'].toString().split(', ');
      final String ln = nameParts[0].trim();
      final String remainingNames = nameParts.length > 1 ? nameParts[1] : "";
      final firstNameParts = remainingNames.trim().split(' ');
      final String fn = firstNameParts[0];
      final String mn = firstNameParts.length > 1 ? firstNameParts[1] : "";

      final String defaultPassword = ln.toLowerCase();

      // 1. Create official Profile
      // FIXED: Removed 'is_first_login' column because it does not exist in the DB schema.
      // The system will instead use 'password_hash == ln.toLowerCase()' as the trigger.
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
          })
          .select()
          .single();

      final String newProfileId = profileRes['id'];

      // 2. Create Student Details
      await _service.client.from('student_details').insert({
        'profile_id': newProfileId,
        'course_id': app['target_course_id'],
        'year_level_id': yearLevelId,
        'student_type': app['applicant_type'],
        'enrollment_status': 'Enrolled',
        'section_block': '',
      });

      // 3. Update Applicant status
      await _service.client
          .from('applicants')
          .update({'status': 'Enrolled'}).eq('id', app['id']);

      _sendEnrollmentEmail(
          recipientEmail: app['email'],
          studentName: "$fn $ln",
          studentId: studentIdNum,
          tempPassword: defaultPassword);
      _showSuccessDialog(studentIdNum, app['full_name'], app['email']);
      _fetchClearedApplicants();
    } catch (e) {
      _showToast("Registration Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredQueue {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _queue;
    return _queue
        .where((item) =>
            item['full_name'].toString().toLowerCase().contains(query))
        .toList();
  }

  void _showRegistrationForm(Map<String, dynamic> app) {
    String? selectedYearLevelId;
    List<Map<String, dynamic>> yearLevels = [];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final Future<dynamic> fetchFuture = yearLevels.isEmpty
            ? _service.client.from('year_levels').select('*')
            : Future.value(yearLevels);
        return FutureBuilder<dynamic>(
            future: fetchFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && yearLevels.isEmpty) {
                yearLevels =
                    List<Map<String, dynamic>>.from(snapshot.data as List);
              }
              return AlertDialog(
                backgroundColor: surfaceDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                title: const Text("Official Enrollment",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedYearLevelId,
                      dropdownColor: surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: "Year Level",
                          labelStyle: TextStyle(color: Colors.blueGrey)),
                      items: yearLevels
                          .map((y) => DropdownMenuItem(
                              value: y['id'].toString(),
                              child: Text(y['definition'])))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedYearLevelId = v),
                    ),
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
                    child: const Text("ENROLL STUDENT"),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Enrollment Verification",
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            IconButton(
                onPressed: _fetchClearedApplicants,
                icon:
                    const Icon(LucideIcons.refreshCcw, color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredQueue.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, i) {
                      final app = _filteredQueue[i];
                      return ListTile(
                        title: Text(app['full_name'],
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "ID: ${app['application_no']} • ${app['courses']?['code'] ?? ''}",
                            style: const TextStyle(color: Colors.blueGrey)),
                        trailing: ElevatedButton(
                            onPressed: () => _showRegistrationForm(app),
                            child: const Text("FINALIZE")),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _infoText(String l, String v) => Row(children: [
        Text(l, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(width: 8),
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))
      ]);

  void _showSuccessDialog(String id, String name, String email) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: surfaceDark,
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.partyPopper, color: success, size: 64),
              const SizedBox(height: 24),
              const Text("Registration Successful",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(id,
                  style: GoogleFonts.orbitron(fontSize: 28, color: aViolet)),
              const SizedBox(height: 16),
              Text("Credentials sent to $email",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("DONE"))
            ])));
  }

  void _showToast(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}
