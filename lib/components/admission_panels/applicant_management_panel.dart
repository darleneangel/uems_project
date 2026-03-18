import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class ApplicationsManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ApplicationsManagementPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<ApplicationsManagementPanel> createState() =>
      _ApplicationsManagementPanelState();
}

class _ApplicationsManagementPanelState
    extends State<ApplicationsManagementPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _applicants = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final response =
          await _service.client.from('courses').select('id, name, code');
      setState(() => _courses = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Course Fetch Error: $e");
    }
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('*, courses(name, code)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _applicants = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📝 PRE-REGISTRATION FORM DIALOG
  void _showPreRegistrationForm() {
    final formKey = GlobalKey<FormState>();
    String? selectedCourseId;
    String selectedCategory = "New Student";
    String gender = "Male";

    final idCtrl = TextEditingController();
    final fnCtrl = TextEditingController();
    final lnCtrl = TextEditingController();
    final mnCtrl = TextEditingController();
    final suffixCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    DateTime? dob;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(LucideIcons.userPlus, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Text("Pre-Registration Form",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ACADEMIC CLASSIFICATION",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            dropdownColor: const Color(0xFF1E1B4B),
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldInput("Category"),
                            items: ["New Student", "Returnee", "Transferee"]
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setModalState(() {
                              selectedCategory = v!;
                              if (v != "Returnee") idCtrl.clear();
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: idCtrl,
                            enabled: selectedCategory == "Returnee",
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _fieldInput("Student ID (Returnees Only)"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseId,
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldInput("Target Course / Program"),
                      items: _courses
                          .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text("${c['code']} - ${c['name']}")))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedCourseId = v),
                    ),
                    const SizedBox(height: 32),
                    const Text("PERSONAL INFORMATION",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: fnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("First Name"))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: mnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Middle Name"))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: lnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Last Name"))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: suffixCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Suffix (Jr, III)"))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: gender,
                            dropdownColor: const Color(0xFF1E1B4B),
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldInput("Gender"),
                            items: ["Male", "Female", "Other"]
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setModalState(() => gender = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2005),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now());
                              if (picked != null) {
                                setModalState(() => dob = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: _fieldInput("Birthdate"),
                              child: Text(
                                  dob == null
                                      ? "Select Date"
                                      : dob!.toString().split(' ')[0],
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: mobileCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Mobile Number"))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: emailCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Email Address"))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL",
                    style: TextStyle(color: Colors.blueGrey))),
            ElevatedButton(
              onPressed: () => _submitPreRegistration(
                context,
                courseId: selectedCourseId!,
                category: selectedCategory,
                idNumber: idCtrl.text,
                fn: fnCtrl.text,
                ln: lnCtrl.text,
                mn: mnCtrl.text,
                suffix: suffixCtrl.text,
                email: emailCtrl.text,
                mobile: mobileCtrl.text,
                gender: gender,
                dob: dob,
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text("SUBMIT APPLICATION"),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  /// 🛰️ DATABASE: Save Applicant and Initialize Requirements Checklist
  Future<void> _submitPreRegistration(
    BuildContext context, {
    required String courseId,
    required String category,
    String? idNumber,
    required String fn,
    required String ln,
    String? mn,
    String? suffix,
    required String email,
    required String mobile,
    required String gender,
    DateTime? dob,
  }) async {
    try {
      final appNo =
          "APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      // 1. Insert into Applicants Table
      final res = await _service.client
          .from('applicants')
          .insert({
            'application_no': appNo,
            'full_name': "$ln, $fn ${mn ?? ''} ${suffix ?? ''}".trim(),
            'email': email,
            'applicant_type': category,
            'target_course_id': courseId,
            'status': 'Pending',
          })
          .select()
          .single();

      final String applicantId = res['id'];

      // 2. Initialize Requirement Checklist
      final List<String> standardDocs = [
        "FORM 138 (Report Card)",
        "PSA Birth Certificate",
        "Good Moral Character",
        "Medical Clearance"
      ];
      final requirementInserts = standardDocs
          .map((doc) => {
                'applicant_id': applicantId,
                'requirement_name': doc,
                'is_verified': false,
              })
          .toList();

      await _service.client
          .from('applicant_requirements')
          .insert(requirementInserts);

      Navigator.pop(context);
      _fetchApplicants();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF69F0AE),
          content: Text("Pre-registration successful. Roster created.")));
    } catch (e) {
      debugPrint("Pre-Reg Error: $e");
    }
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Applications Management",
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            Row(
              children: [
                _buildSearchField(cardColor, textColor),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showPreRegistrationForm,
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text("PRE-REGISTER STUDENT"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10)),
                  child: ListView.builder(
                    itemCount: _applicants.length,
                    itemBuilder: (context, i) {
                      final app = _applicants[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        title: Text(app['full_name'],
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${app['email']} • ${app['applicant_type']}",
                            style: const TextStyle(color: Colors.blueGrey)),
                        trailing: Text(app['status'].toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField(Color bg, Color text) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: text, fontSize: 13),
        decoration: const InputDecoration(
            hintText: "Search applicant...",
            border: InputBorder.none,
            prefixIcon: Icon(LucideIcons.search, size: 16)),
      ),
    );
  }
}
