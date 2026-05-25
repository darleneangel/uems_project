import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
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

  // --- FILTER STATES ---
  String _selectedStatus = 'All'; // Default to All
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Admitted',
    'Enrolled',
    'Archived'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRegistry();
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

  Future<void> _fetchRegistry() async {
    if (!mounted) return;
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

  /// 📐 SMART FILTER ENGINE
  /// Logic:
  /// 1. Filters by Search Term (Real-time).
  /// 2. If 'Archived' is selected, show only records > 30 days old.
  /// 3. If 'All' is selected, show all records <= 30 days old.
  /// 4. Otherwise, show records <= 30 days old matching the specific status.
  List<Map<String, dynamic>> get _filteredApplicants {
    final now = DateTime.now();

    return _applicants.where((app) {
      final String first = (app['fn'] ?? '').toString().toLowerCase();
      final String last = (app['ln'] ?? '').toString().toLowerCase();
      final String appNo =
          (app['application_no'] ?? '').toString().toLowerCase();
      final String query = _searchController.text.toLowerCase();

      // Real-time Search Match
      final bool matchesSearch = first.contains(query) ||
          last.contains(query) ||
          appNo.contains(query);
      if (!matchesSearch) return false;

      // Automated Archival Logic
      final createdAt = DateTime.tryParse(app['created_at'] ?? '') ?? now;
      final int ageInDays = now.difference(createdAt).inDays;
      final bool isArchived = ageInDays > 30;

      if (_selectedStatus == 'Archived') {
        return isArchived;
      } else {
        // Exclude archived records from all active views
        if (isArchived) return false;

        // Handle "All" active filter
        if (_selectedStatus == 'All') return true;

        // Handle specific status filters
        final String status = app['status'] ?? 'Pending';
        return status.toLowerCase() == _selectedStatus.toLowerCase();
      }
    }).toList();
  }

  /// 📝 INTAKE FORM: Validates all institutional identity requirements
  void _showPreRegistrationForm() {
    final formKey = GlobalKey<FormState>();
    String? selectedCourseId;
    String selectedCategory = "New Student";
    String gender = "Male";

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
              Text("Applicant Intake Form",
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
                    _sectionLabel("ACADEMIC CLASSIFICATION"),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldInput("Entry Category"),
                      items: ["New Student", "Returnee", "Transferee"]
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedCategory = v!),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseId,
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldInput("Target Program of Choice"),
                      items: _courses
                          .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text("${c['code']} - ${c['name']}")))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedCourseId = v),
                      validator: (v) =>
                          v == null ? "Program selection required" : null,
                    ),
                    const SizedBox(height: 32),
                    _sectionLabel("LEGAL PERSONAL IDENTITY"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: fnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("First Name *"),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Required"
                                    : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: mnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _fieldInput("Middle Name (Optional)"))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: lnCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Last Name *"),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Required"
                                    : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: suffixCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldInput("Suffix (Optional)"))),
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
                              decoration: _fieldInput("Date of Birth *"),
                              child: Text(
                                  dob == null
                                      ? "Select Date"
                                      : DateFormat('yyyy-MM-dd').format(dob!),
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
                                decoration: _fieldInput("Contact Number *"),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Required"
                                    : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: emailCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _fieldInput("Institutional Email *"),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Required"
                                    : null)),
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
              onPressed: () {
                if (formKey.currentState!.validate() &&
                    dob != null &&
                    selectedCourseId != null) {
                  _submitPreRegistration(
                    context,
                    courseId: selectedCourseId!,
                    category: selectedCategory,
                    fn: fnCtrl.text.trim(),
                    ln: lnCtrl.text.trim(),
                    mn: mnCtrl.text.trim(),
                    suffix: suffixCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    mobile: mobileCtrl.text.trim(),
                    gender: gender,
                    dob: dob!,
                  );
                } else if (dob == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Birthdate is required."),
                      backgroundColor: Colors.orangeAccent));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white),
              child: const Text("INTAKE APPLICANT"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5));

  InputDecoration _fieldInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  /// 🛰️ DATABASE: Saves pre-registration data
  Future<void> _submitPreRegistration(
    BuildContext context, {
    required String courseId,
    required String category,
    required String fn,
    required String ln,
    String? mn,
    String? suffix,
    required String email,
    required String mobile,
    required String gender,
    required DateTime dob,
  }) async {
    try {
      final appNo =
          "APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      final res = await _service.client
          .from('applicants')
          .insert({
            'application_no': appNo,
            'email': email,
            'applicant_type': category,
            'target_course_id': courseId,
            'status': 'Pending',
            'fn': fn,
            'mn': (mn == null || mn.isEmpty) ? '-' : mn,
            'ln': ln,
            'suffix': (suffix == null || suffix.isEmpty) ? 'N/A' : suffix,
            'gender': gender,
            'dob': DateFormat('yyyy-MM-dd').format(dob),
            'phone': mobile,
          })
          .select()
          .single();

      final List<String> standardDocs = [
        "FORM 138",
        "PSA Birth Cert",
        "Good Moral",
        "Medical"
      ];
      await _service.client.from('applicant_requirements').insert(standardDocs
          .map((doc) => {
                'applicant_id': res['id'],
                'requirement_name': doc,
                'is_verified': false
              })
          .toList());

      if (mounted) {
        Navigator.pop(context);
        _fetchRegistry();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color(0xFF69F0AE),
            content: Text(
                "Institutional record created. Applicant synced to registry.")));
      }
    } catch (e) {
      debugPrint("Intake Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

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
                  Text("Admission Registry",
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textColor)),
                  const Text(
                      "Centralized intake terminal with smart archival tracking.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showPreRegistrationForm,
                icon: Icon(LucideIcons.userPlus,
                    color: widget.isDarkMode ? Colors.white : Colors.white),
                label: Text("NEW APPLICANT",
                    style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkMode
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- SMART SEARCH & FILTER SUITE ---
          Row(
            children: [
              Expanded(child: _buildSearchField(cardColor, textColor)),
              const SizedBox(width: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((f) => _filterChip(f)).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: _filteredApplicants.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: _filteredApplicants.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, i) {
                              final app = _filteredApplicants[i];

                              final String first =
                                  (app['fn'] ?? 'TBA').toString();
                              final String last =
                                  (app['ln'] ?? 'TBA').toString();
                              final String suffix = (app['suffix'] != null &&
                                      app['suffix'] != 'N/A' &&
                                      app['suffix'].toString().isNotEmpty)
                                  ? " ${app['suffix']}"
                                  : "";
                              final String name =
                                  "$last, $first$suffix".toUpperCase();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF8B5CF6)
                                        .withOpacity(0.1),
                                    child: Text(
                                        app['ln'] != null ? app['ln'][0] : 'A',
                                        style: const TextStyle(
                                            color: Color(0xFF8B5CF6),
                                            fontWeight: FontWeight.bold))),
                                title: Text(name,
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                subtitle: Text(
                                    "${app['application_no']} • ${app['courses']?['name'] ?? 'UNDECLARED'}",
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 11)),
                                trailing:
                                    _statusChip(app['status'] ?? 'Pending'),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String status) {
    bool isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.blueGrey)),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedStatus = status);
        },
        selectedColor: const Color(0xFF8B5CF6),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.white10)),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.searchX,
            size: 48, color: Colors.blueGrey.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text("No records found in $_selectedStatus view.",
            style: const TextStyle(color: Colors.blueGrey))
      ]));

  Widget _statusChip(String status) {
    bool isVerified =
        status == 'Enrolled' || status == 'Verified' || status == 'Admitted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: isVerified
              ? Colors.green.withOpacity(0.1)
              : (status == 'Rejected'
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: isVerified
                  ? Colors.green
                  : (status == 'Rejected' ? Colors.red : Colors.orange),
              fontSize: 9,
              fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildSearchField(Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          style: TextStyle(color: text, fontSize: 13),
          decoration: const InputDecoration(
              hintText: "Search name or reference...",
              border: InputBorder.none,
              prefixIcon:
                  Icon(LucideIcons.search, size: 16, color: Color(0xFF8B5CF6))),
        ),
      );
}
