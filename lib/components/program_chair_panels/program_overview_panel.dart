import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class ProgramOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData; // Profile data containing user_id_number

  const ProgramOverviewPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<ProgramOverviewPanel> createState() => _ProgramOverviewPanelState();
}

class _ProgramOverviewPanelState extends State<ProgramOverviewPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _chairDeptId;
  String? _chairDeptName;

  // Department Stats
  int _studentCount = 0;
  int _facultyCount = 0;
  int _subjectCount = 0;

  // Student Directory Data
  List<Map<String, dynamic>> _allStudents = [];
  String _selectedYearFilter = "All";
  final List<String> _yearLevels = [
    "All",
    "1st Year",
    "2nd Year",
    "3rd Year",
    "4th Year"
  ];

  // Visual Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  /// 🛰️ DATABASE: Initialize the dashboard context and load departmental data
  Future<void> _initDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? userIdNum = widget.userData['user_id_number']?.toString();
      if (userIdNum == null) return;

      // 1. Resolve Chair's Department Context
      final chairContext = await _service.getChairContext(userIdNum);
      if (chairContext != null) {
        _chairDeptId = chairContext['department_id']?.toString();
        _chairDeptName =
            chairContext['departments']?['name']?.toString() ?? "Academic Unit";

        // 2. Load Analytics and Student Directory concurrently
        await Future.wait([
          _loadAnalytics(),
          _loadStudentDirectory(),
        ]);
      }
    } catch (e) {
      debugPrint("Dashboard Initialization Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ ANALYTICS: Fetch counts for students, faculty, and subjects
  Future<void> _loadAnalytics() async {
    if (_chairDeptId == null) return;

    try {
      final results = await Future.wait([
        // Count Students in this specific department
        _service.client
            .from('student_details')
            .select('profile_id, courses!inner(department_id)')
            .eq('courses.department_id', _chairDeptId!),

        // Count Faculty assigned to this department
        _service.client
            .from('employee_details')
            .select('profile_id')
            .eq('department_id', _chairDeptId!),

        // Count Subjects owned by this department
        _service.client
            .from('subjects')
            .select('id')
            .eq('department_id', _chairDeptId!),
      ]);

      if (mounted) {
        setState(() {
          _studentCount = (results[0] as List).length;
          _facultyCount = (results[1] as List).length;
          _subjectCount = (results[2] as List).length;
        });
      }
    } catch (e) {
      debugPrint("Analytics Data Sync Error: $e");
    }
  }

  /// 🛰️ DIRECTORY: Fetch all students under the program, regardless of enrollment status
  Future<void> _loadStudentDirectory() async {
    if (_chairDeptId == null) return;

    try {
      final response = await _service.client
          .from('profiles')
          .select('''
            id, user_id_number, fn, ln, role,
            student_details!inner(
              enrollment_status,
              student_type,
              courses!inner(code, department_id),
              year_levels!inner(definition)
            )
          ''')
          .eq('role', 'student')
          .eq('student_details.courses.department_id', _chairDeptId!);

      if (mounted) {
        setState(() {
          _allStudents = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Student Directory Fetch Error: $e");
    }
  }

  /// 🔍 FILTER LOGIC: Applies search query and year level selection to the list
  List<Map<String, dynamic>> get _filteredStudents {
    return _allStudents.where((s) {
      final details = s['student_details'];
      final String fullName = "${s['fn']} ${s['ln']}".toLowerCase();
      final String searchQuery = _searchController.text.toLowerCase();
      final String yearLevel = details?['year_levels']?['definition'] ?? "";

      bool matchesSearch = fullName.contains(searchQuery) ||
          s['user_id_number'].toString().contains(searchQuery);
      bool matchesYear =
          _selectedYearFilter == "All" || yearLevel == _selectedYearFilter;

      return matchesSearch && matchesYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // TOP STATS ROW
          Row(
            children: [
              _statCard("Total Students", _studentCount.toString(),
                  LucideIcons.users, aViolet, cardColor, textColor),
              _statCard(
                  "Department Faculty",
                  _facultyCount.toString(),
                  LucideIcons.userCheck,
                  Colors.blueAccent,
                  cardColor,
                  textColor),
              _statCard("Subject Catalog", _subjectCount.toString(),
                  LucideIcons.layers, success, cardColor, textColor),
            ],
          ),
          const SizedBox(height: 32),

          // STUDENT MANAGEMENT TABLE
          _buildStudentDirectory(cardColor, textColor),

          const SizedBox(height: 32),
          _buildAuditNotice(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_chairDeptName ?? 'Academic'} Program Overview",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          const Text(
              "Management view of departmental statistics and student records.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildStudentDirectory(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Student Master List",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, color: text, fontSize: 18)),
              Row(
                children: [
                  _buildYearFilter(text),
                  const SizedBox(width: 12),
                  _buildSearchBar(text),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildStudentTable(text),
        ],
      ),
    );
  }

  Widget _buildYearFilter(Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 136, 133, 133).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYearFilter,
          dropdownColor: surfaceDark,
          style:
              TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
          items: _yearLevels
              .map((y) => DropdownMenuItem(value: y, child: Text(y)))
              .toList(),
          onChanged: (v) => setState(() => _selectedYearFilter = v!),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color text) {
    return Container(
      width: 280,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {}),
        style: TextStyle(color: text, fontSize: 13),
        decoration: const InputDecoration(
            hintText: "Search ID or Name...",
            hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 12),
            border: InputBorder.none,
            icon: Icon(LucideIcons.search, size: 16, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildStudentTable(Color text) {
    final students = _filteredStudents;
    if (students.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(48),
        child: Text("No records found.",
            style: TextStyle(color: text.withOpacity(1)
                // fontWeight: FontWeight.bold,
                // fontSize: 15
                )),
      ));
    }

    return Column(
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 2, child: _tableHead("ID NUMBER")),
              Expanded(flex: 3, child: _tableHead("STUDENT NAME")),
              Expanded(flex: 2, child: _tableHead("YEAR LEVEL")),
              Expanded(flex: 2, child: _tableHead("ENROLLMENT STATUS")),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        // Data Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          separatorBuilder: (context, i) =>
              const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, i) {
            final s = students[i];
            final details = s['student_details'];
            final String status = details?['enrollment_status'] ?? "Pending";
            final bool isEnrolled = status == "Enrolled";

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(s['user_id_number'].toString(),
                          style: GoogleFonts.inter(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontSize: 15,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 3,
                      child: Text("${s['fn']} ${s['ln']}",
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w900,
                              fontSize: 15))),
                  Expanded(
                      flex: 2,
                      child: Text(
                        details?['year_levels']?['definition'] ?? 'N/A',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 12),
                      )),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isEnrolled ? success : Colors.orangeAccent)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isEnrolled ? success : Colors.orangeAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _tableHead(String t) => Text(t,
      style: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1));

  Widget _statCard(String label, String val, IconData icon, Color color,
          Color bg, Color text) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(val,
                  style: GoogleFonts.inter(
                      fontSize: 26, fontWeight: FontWeight.bold, color: text)),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      );

  Widget _buildAuditNotice(Color text) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: aViolet.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aViolet.withOpacity(0.2))),
        child: Row(
          children: [
            const Icon(LucideIcons.info, color: aViolet, size: 20),
            const SizedBox(width: 16),
            Expanded(
                child: Text(
                    "Master List visibility includes all profiles mapped to this department. Lifecycle status is synced with Registrar records.",
                    style:
                        TextStyle(color: text.withOpacity(0.7), fontSize: 12))),
          ],
        ),
      );
}
