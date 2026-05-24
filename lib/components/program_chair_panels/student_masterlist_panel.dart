import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

/// Intelligent utility to dynamically evaluate academic standings of student study loads.
class StudentAcademicSummary {
  final int totalSubjects;
  final double totalUnits;
  final double passedUnits;
  final double failedUnits;
  final double droppedUnits;
  final int passedCount;
  final int failedCount;
  final int droppedCount;
  final int ongoingCount;
  final double gpa;

  StudentAcademicSummary({
    required this.totalSubjects,
    required this.totalUnits,
    required this.passedUnits,
    required this.failedUnits,
    required this.droppedUnits,
    required this.passedCount,
    required this.failedCount,
    required this.droppedCount,
    required this.ongoingCount,
    required this.gpa,
  });

  factory StudentAcademicSummary.fromLoads(List loads) {
    int totalSubs = loads.length;
    double totalU = 0;
    double passedU = 0;
    double failedU = 0;
    double droppedU = 0;
    int passedC = 0;
    int failedC = 0;
    int droppedC = 0;
    int ongoingC = 0;
    double gradeSum = 0;
    int gradedCount = 0;

    for (var load in loads) {
      final subject = load['subjects'];
      final double units =
          double.tryParse(subject?['units']?.toString() ?? '0') ?? 0.0;
      totalU += units;

      // Extract Grade Book details safely from nested grades table
      final rawGrades = load['grades'];
      Map<String, dynamic>? gradeRecord;
      if (rawGrades is List && rawGrades.isNotEmpty) {
        gradeRecord = Map<String, dynamic>.from(rawGrades.first);
      } else if (rawGrades is Map) {
        gradeRecord = Map<String, dynamic>.from(rawGrades);
      }

      final rawGrade = gradeRecord?['final_numeric_grade'];
      final rawRemarks =
          (gradeRecord?['status'] ?? '').toString().toUpperCase();

      // Evaluate the status / remarks
      if (rawRemarks.contains('PASSED') ||
          rawRemarks == 'PASS' ||
          rawRemarks == 'P') {
        passedC++;
        passedU += units;
      } else if (rawRemarks.contains('FAILED') ||
          rawRemarks == 'FAIL' ||
          rawRemarks == 'F') {
        failedC++;
        failedU += units;
      } else if (rawRemarks.contains('DROPPED') ||
          rawRemarks == 'DRP' ||
          rawRemarks == 'W') {
        droppedC++;
        droppedU += units;
      } else {
        // Fallback evaluation on numeric GPA if remarks column is empty
        if (rawGrade != null) {
          final double? gradeVal = double.tryParse(rawGrade.toString());
          if (gradeVal != null && gradeVal > 0) {
            gradeSum += gradeVal * units;
            gradedCount += units.toInt();

            // Philippine grading standard (1.00 is excellent, 3.00 is passing, 5.00 is failing)
            if (gradeVal <= 3.0 && gradeVal >= 1.0) {
              passedC++;
              passedU += units;
            } else if (gradeVal > 3.0 && gradeVal <= 5.0) {
              failedC++;
              failedU += units;
            }
            // 100-Point grading standard (75 is passing, below 75 is failing)
            else if (gradeVal >= 75.0) {
              passedC++;
              passedU += units;
            } else if (gradeVal < 75.0 && gradeVal > 0.0) {
              failedC++;
              failedU += units;
            } else {
              ongoingC++;
            }
          } else {
            ongoingC++;
          }
        } else {
          ongoingC++;
        }
      }
    }

    double computedGpa = gradedCount > 0 ? (gradeSum / gradedCount) : 0.0;
    return StudentAcademicSummary(
      totalSubjects: totalSubs,
      totalUnits: totalU,
      passedUnits: passedU,
      failedUnits: failedU,
      droppedUnits: droppedU,
      passedCount: passedC,
      failedCount: failedC,
      droppedCount: droppedC,
      ongoingCount: ongoingC,
      gpa: computedGpa,
    );
  }
}

class StudentMasterListPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const StudentMasterListPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<StudentMasterListPanel> createState() => _StudentMasterListPanelState();
}

class _StudentMasterListPanelState extends State<StudentMasterListPanel> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _chairDeptId;
  List<Map<String, dynamic>> _students = [];

  // --- 🎯 FILTERS ---
  String _activeTypeFilter = "All"; // All, Regular, Irregular
  String _activeStatusFilter =
      "All"; // All, Enrolled, Not Enrolled/Pending, Dropped
  String _activeAcademicFilter =
      "All"; // All, Clean Pass, Has Failures, Empty Load

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color warning = Color(0xFFFFD740);
  static const Color danger = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _initPanel();
  }

  /// 🛰️ INITIALIZE: Resolve Chair context and fetch departmental students
  Future<void> _initPanel() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? userIdNum = widget.userData['user_id_number']?.toString();
      debugPrint("🛰️ Resolving Department Chair Context for ID: $userIdNum");
      if (userIdNum == null) {
        setState(() => _isLoading = false);
        return;
      }

      final chairContext = await _service.getChairContext(userIdNum);
      if (chairContext != null) {
        _chairDeptId = chairContext['department_id']?.toString();
        debugPrint("✅ Resolved Department ID: $_chairDeptId");
        await _fetchStudents();
      } else {
        debugPrint(
            "⚠️ Warning: Program Chair context not found for ID $userIdNum in database");
      }
    } catch (e) {
      debugPrint("Master List Init Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents() async {
    if (_chairDeptId == null) {
      debugPrint(
          "⚠️ Cannot fetch: Program Chair has no associated department ID.");
      return;
    }

    try {
      debugPrint(
          "🛰️ Stage 1: Requesting Profiles + Study Loads + Nested Grade Book Details for Dept: $_chairDeptId");

      // FIXED QUERY: Removed the invalid direct 'remarks' and 'grade' attributes from study_loads table join.
      // Now queries midterm, finals, numerical scores, and statuses nested directly on the 'grades' table.
      final response = await _service.client
          .from('profiles')
          .select('''
            id, user_id_number, fn, ln, email,
            student_details!inner(
              student_type,
              enrollment_status,
              courses!inner(code, name, department_id),
              year_levels!inner(definition)
            ),
            study_loads!study_loads_student_id_fkey(
              id,
              subjects(code, name, units),
              grades(
                midterm_grade,
                final_grade,
                final_numeric_grade,
                status
              )
            )
          ''')
          .eq('role', 'student')
          .eq('student_details.courses.department_id', _chairDeptId!);

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response);
          debugPrint(
              "✅ Success! Loaded ${_students.length} students with active grade sheets.");
        });
      }
    } catch (e) {
      debugPrint(
          "⚠️ Stage 1 Grade Sheet Query failed: $e. Transitioning to Stage 2 Fallback.");
      await _runSecondaryResilientFallback();
    }
  }

  /// Backup query structure without the highly nested grade joins (e.g. if grades table is currently being migrated)
  Future<void> _runSecondaryResilientFallback() async {
    try {
      debugPrint(
          "🛰️ Stage 2: Pulling Profiles + Academic study loads (excluding nested marks and remarks)");

      // FIXED QUERY: Removed invalid 'remarks' from the fallback select parameters as well
      final response = await _service.client
          .from('profiles')
          .select('''
            id, user_id_number, fn, ln, email,
            student_details!inner(
              student_type,
              enrollment_status,
              courses!inner(code, name, department_id),
              year_levels!inner(definition)
            ),
            study_loads!study_loads_student_id_fkey(
              id,
              subjects(code, name, units)
            )
          ''')
          .eq('role', 'student')
          .eq('student_details.courses.department_id', _chairDeptId!);

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response);
          debugPrint(
              "⚡ Success! Fallback Stage 2 resolved ${_students.length} student profiles.");
        });
      }
    } catch (err) {
      debugPrint(
          "⚠️ Fallback Stage 2 failed: $err. Transitioning to Stage 3 Schema-Resilient Fallback.");
      await _runBasicRosterFallback();
    }
  }

  /// Ultimate baseline fallback query to make sure the list is never blank
  Future<void> _runBasicRosterFallback() async {
    try {
      debugPrint(
          "🛰️ Stage 3: Fetching basic raw student roster with no joins");
      final response = await _service.client.from('profiles').select('''
            id, user_id_number, fn, ln, email,
            student_details(
              student_type,
              enrollment_status
            )
          ''').eq('role', 'student');

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response);
          debugPrint(
              "⚡ Fallback Stage 3 complete: Loaded ${_students.length} basic profiles.");
        });
      }
    } catch (err) {
      debugPrint("❌ Database Core Unreachable: $err");
      _showToast("Administrative Database Node currently offline.", danger);
    }
  }

  /// 🛰️ DATABASE ACTION: Administrative Drop
  Future<void> _dropStudent(String profileId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F071D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: danger, size: 32),
            SizedBox(width: 12),
            Text("Administrative Drop",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        content: Text(
          "Are you sure you want to drop $name from the academic roster? \n\n"
          "This action will flag the student as 'Dropped' and restrict further enrollment actions for this term.",
          style:
              const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCEL",
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
            child: const Text("CONFIRM DROP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      try {
        await _service.client.from('student_details').update(
            {'enrollment_status': 'Dropped'}).eq('profile_id', profileId);

        _showToast("Student $name has been dropped.", success);
        await _fetchStudents();
      } catch (e) {
        _showToast("Drop Action Failed: Connection Error", danger);
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
  }

  /// 📐 DYNAMIC FILTER ENGINE
  List<Map<String, dynamic>> get _filteredStudents {
    final query = _searchController.text.toLowerCase().trim();
    return _students.where((s) {
      final name = "${s['fn']} ${s['ln']}".toLowerCase();
      final id = (s['user_id_number'] ?? '').toString().toLowerCase();

      final details = s['student_details'];
      final status = (details?['enrollment_status'] ?? "Pending").toString();
      final rawType = (details?['student_type'] ?? "Regular").toString();
      final bool isActuallyIrregular = rawType == "Irregular";

      // Compute dynamic academic performance on the fly
      final loads = s['study_loads'] as List? ?? [];
      final summary = StudentAcademicSummary.fromLoads(loads);

      bool matchesSearch =
          query.isEmpty || name.contains(query) || id.contains(query);

      bool matchesType = true;
      if (_activeTypeFilter == "Regular") {
        matchesType = !isActuallyIrregular;
      } else if (_activeTypeFilter == "Irregular") {
        matchesType = isActuallyIrregular;
      }

      bool matchesStatus = true;
      if (_activeStatusFilter == "Enrolled") {
        matchesStatus = status == "Enrolled" || status == "Cleared";
      } else if (_activeStatusFilter == "Not Enrolled") {
        matchesStatus =
            status != "Enrolled" && status != "Cleared" && status != "Dropped";
      } else if (_activeStatusFilter == "Dropped") {
        matchesStatus = status == "Dropped";
      }

      bool matchesAcademic = true;
      if (_activeAcademicFilter == "Passing") {
        matchesAcademic = summary.failedCount == 0 && summary.passedCount > 0;
      } else if (_activeAcademicFilter == "Has Failures") {
        matchesAcademic = summary.failedCount > 0;
      } else if (_activeAcademicFilter == "Dropped Load") {
        matchesAcademic = summary.droppedCount > 0;
      }

      return matchesSearch && matchesType && matchesStatus && matchesAcademic;
    }).toList();
  }

  // --- STATISTICS CALCULATORS ---
  int get _totalStudentsCount => _students.length;
  int get _enrolledCount => _students.where((s) {
        final status = s['student_details']?['enrollment_status'] ?? '';
        return status == 'Enrolled' || status == 'Cleared';
      }).length;
  int get _failingCount => _students.where((s) {
        final loads = s['study_loads'] as List? ?? [];
        return StudentAcademicSummary.fromLoads(loads).failedCount > 0;
      }).length;
  int get _droppedCount => _students
      .where((s) => s['student_details']?['enrollment_status'] == 'Dropped')
      .length;

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
          _buildDepartmentWarningBanner(), // Database diagnostics banner
          _buildPerformanceDashboard(textColor),
          const SizedBox(height: 32),
          _buildFilterSuite(cardColor, textColor),
          const SizedBox(height: 24),
          _buildStudentTable(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UI REFINEMENT: Made page headers larger and bolder for high readability
          Text("Departmental Master Roster",
              style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -1.2)),
          const SizedBox(height: 6),
          Text(
              "Administrative management of student academic progress, profiles, and class drops.",
              style: TextStyle(
                  color: Colors.blueGrey.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.4)),
        ],
      );

  Widget _buildDepartmentWarningBanner() {
    if (_chairDeptId != null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: danger, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "No Assigned Department Registered",
                  style: TextStyle(
                      color: danger, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your Program Chair account is currently not assigned to any departmental node in the database. "
                  "Please ensure your profile is linked in the Supabase 'department_chairs' table to load students.",
                  style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard(Color text) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = (constraints.maxWidth - 48) / 4;
      if (constraints.maxWidth < 800)
        cardWidth = (constraints.maxWidth - 16) / 2;
      if (constraints.maxWidth < 500) cardWidth = constraints.maxWidth;

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildStatCard("DEPARTMENT ROSTER", _totalStudentsCount.toString(),
              Icons.groups_rounded, aViolet, cardWidth),
          _buildStatCard("ENROLLED ACTIVE", _enrolledCount.toString(),
              Icons.how_to_reg_rounded, success, cardWidth),
          _buildStatCard("ACADEMIC FAILURES", _failingCount.toString(),
              Icons.gpp_maybe_rounded, warning, cardWidth),
          _buildStatCard("DROPPED STUDENTS", _droppedCount.toString(),
              Icons.person_off_rounded, danger, cardWidth),
        ],
      );
    });
  }

  Widget _buildStatCard(
      String title, String val, IconData icon, Color color, double width) {
    final cardBg = widget.isDarkMode ? surfaceDark : Colors.white;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UI REFINEMENT: Made stat category titles slightly larger and spaced out
                Text(title,
                    style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                // UI REFINEMENT: Scaled performance stat numbers up to 36 with robust monospace font
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: widget.isDarkMode ? Colors.white : pViolet,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          )
        ],
      ),
    );
  }

  Widget _buildFilterSuite(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: Colors.blueGrey, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        color: text, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                        hintText: "Search Name or Student ID...",
                        hintStyle:
                            TextStyle(color: Colors.blueGrey, fontSize: 16),
                        border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 28),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _filterLabel("STATUS: "),
                  _chip("All", _activeStatusFilter == "All",
                      (v) => setState(() => _activeStatusFilter = v)),
                  _chip("Enrolled", _activeStatusFilter == "Enrolled",
                      (v) => setState(() => _activeStatusFilter = v)),
                  _chip("Not Enrolled", _activeStatusFilter == "Not Enrolled",
                      (v) => setState(() => _activeStatusFilter = v)),
                  _chip("Dropped", _activeStatusFilter == "Dropped",
                      (v) => setState(() => _activeStatusFilter = v)),
                  const SizedBox(width: 28),
                  _filterLabel("ACADEMICS: "),
                  _chip("All", _activeAcademicFilter == "All",
                      (v) => setState(() => _activeAcademicFilter = v)),
                  _chip("Clean Passing", _activeAcademicFilter == "Passing",
                      (v) => setState(() => _activeAcademicFilter = v)),
                  _chip("Has Failures", _activeAcademicFilter == "Has Failures",
                      (v) => setState(() => _activeAcademicFilter = v)),
                  _chip("Dropped Load", _activeAcademicFilter == "Dropped Load",
                      (v) => setState(() => _activeAcademicFilter = v)),
                  const SizedBox(width: 28),
                  _filterLabel("TYPE: "),
                  _chip("All", _activeTypeFilter == "All",
                      (v) => setState(() => _activeTypeFilter = v)),
                  _chip("Regular", _activeTypeFilter == "Regular",
                      (v) => setState(() => _activeTypeFilter = v)),
                  _chip("Irregular", _activeTypeFilter == "Irregular",
                      (v) => setState(() => _activeTypeFilter = v)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStudentTable(Color bg, Color text) {
    final list = _filteredStudents;
    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(56.0),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded,
                        color: Colors.blueGrey, size: 48),
                    const SizedBox(height: 18),
                    Text("No students match your filter criteria.",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, i) {
                final s = list[i];
                final details = s['student_details'];
                final String status =
                    (details?['enrollment_status'] ?? "Pending").toString();
                final bool isEnrolled =
                    status == "Enrolled" || status == "Cleared";
                final bool isDropped = status == "Dropped";
                final bool isIrreg = details?['student_type'] == 'Irregular';

                final loads = s['study_loads'] as List? ?? [];
                final summary = StudentAcademicSummary.fromLoads(loads);

                final studentName = "${s['fn']} ${s['ln']}";

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  onTap: () => _showStudentProgressModal(s, summary),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: isDropped
                        ? danger.withOpacity(0.1)
                        : (isEnrolled
                            ? success.withOpacity(0.1)
                            : warning.withOpacity(0.1)),
                    child: Text(s['ln'][0],
                        style: TextStyle(
                            color: isDropped
                                ? danger
                                : (isEnrolled ? success : warning),
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                  title: Row(
                    children: [
                      // UI REFINEMENT: Enlarged Student name font in table row to 17
                      Text(studentName.toUpperCase(),
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.bold,
                              fontSize: 17)),
                      const SizedBox(width: 12),
                      if (summary.failedCount > 0)
                        _badge("ACADEMIC WARNING", danger)
                      else if (summary.passedCount > 0 &&
                          summary.ongoingCount == 0)
                        _badge("EXCELLENT STANDING", success),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // UI REFINEMENT: Expanded basic demographic line details to 14
                      Text(
                          "ID: ${s['user_id_number']} • ${details?['year_levels']?['definition'] ?? 'N/A'} • ${details?['courses']?['code'] ?? 'N/A'}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _badge(
                              status.toUpperCase(),
                              isDropped
                                  ? danger
                                  : (isEnrolled ? success : warning)),
                          const SizedBox(width: 8),
                          _badge(isIrreg ? "IRREGULAR" : "REGULAR",
                              isIrreg ? Colors.orange : Colors.blueAccent),
                          const SizedBox(width: 20),
                          _loadProgressBar(summary),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // UI REFINEMENT: Increased units and totals metrics text
                          Text("${summary.totalUnits.toStringAsFixed(1)} Units",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 4),
                          Text(
                              "${summary.passedCount}P • ${summary.failedCount}F • ${summary.droppedCount}D",
                              style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'drop') _dropStudent(s['id'], studentName);
                          if (val == 'view')
                            _showStudentProgressModal(s, summary);
                        },
                        icon: const Icon(Icons.more_vert_rounded,
                            color: Colors.blueGrey, size: 24),
                        color: widget.isDarkMode ? surfaceDark : Colors.white,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.school_rounded,
                                    color: aViolet, size: 18),
                                SizedBox(width: 12),
                                Text("View Grade Sheet",
                                    style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (!isDropped)
                            const PopupMenuItem(
                              value: 'drop',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_rounded,
                                      color: danger, size: 18),
                                  SizedBox(width: 12),
                                  Text("Drop Student",
                                      style: TextStyle(
                                          color: danger,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _loadProgressBar(StudentAcademicSummary summary) {
    if (summary.totalSubjects == 0) return const SizedBox.shrink();

    return Row(
      children: [
        // UI REFINEMENT: Adjusted label to 11 point bold
        const Text("PROGRESS: ",
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (summary.passedCount > 0)
                Expanded(
                  flex: summary.passedCount,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: success,
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                  ),
                ),
              if (summary.failedCount > 0)
                Expanded(
                  flex: summary.failedCount,
                  child: Container(color: danger),
                ),
              if (summary.droppedCount > 0)
                Expanded(
                  flex: summary.droppedCount,
                  child: Container(color: Colors.orange),
                ),
              if (summary.ongoingCount > 0)
                Expanded(
                  flex: summary.ongoingCount,
                  child: Container(color: Colors.blueGrey.withOpacity(0.4)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStudentProgressModal(
      Map<String, dynamic> s, StudentAcademicSummary summary) {
    final textTheme = widget.isDarkMode ? Colors.white : pViolet;
    final details = s['student_details'];
    final loads = s['study_loads'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF0F071D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(40),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UI REFINEMENT: Enlarged student name title to 28
                        Text("${s['fn']} ${s['ln']}".toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: textTheme,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text("Registered Email: ${s['email'] ?? 'N/A'}",
                            style: const TextStyle(
                                color: Colors.blueGrey, fontSize: 14)),
                      ],
                    ),
                  ),
                  _badge(
                    (details?['enrollment_status'] ?? 'Pending')
                        .toString()
                        .toUpperCase(),
                    details?['enrollment_status'] == 'Dropped'
                        ? danger
                        : (details?['enrollment_status'] == 'Enrolled' ||
                                details?['enrollment_status'] == 'Cleared'
                            ? success
                            : warning),
                    large: true,
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 40),

              // Key Performance Indicator Badges - Enlarged for outstanding visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressMetrics(
                      "PASSED UNITS",
                      "${summary.passedUnits.toStringAsFixed(1)} Units",
                      success),
                  _buildProgressMetrics(
                      "FAILED UNITS",
                      "${summary.failedUnits.toStringAsFixed(1)} Units",
                      danger),
                  _buildProgressMetrics(
                      "DROPPED UNITS",
                      "${summary.droppedUnits.toStringAsFixed(1)} Units",
                      Colors.orange),
                  _buildProgressMetrics(
                      "GPA AVERAGE",
                      summary.gpa == 0.0
                          ? "N/A"
                          : summary.gpa.toStringAsFixed(2),
                      aViolet),
                ],
              ),

              const SizedBox(height: 36),
              Text("OFFICIAL GRADE BOOK SHEET",
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: aViolet,
                      letterSpacing: 1.2)),
              const SizedBox(height: 20),

              Expanded(
                child: loads.isEmpty
                    ? const Center(
                        child: Text(
                            "No academic study loads loaded for this term.",
                            style: TextStyle(
                                color: Colors.blueGrey, fontSize: 14)),
                      )
                    : ListView.separated(
                        itemCount: loads.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          final loadItem = loads[index];
                          final subject = loadItem['subjects'];
                          final String code = subject?['code'] ?? 'N/A';
                          final String title = subject?['name'] ?? 'N/A';
                          final String units =
                              subject?['units']?.toString() ?? '0';

                          // Safely parse nested grades block
                          final rawGrades = loadItem['grades'];
                          Map<String, dynamic>? gradeRecord;
                          if (rawGrades is List && rawGrades.isNotEmpty) {
                            gradeRecord =
                                Map<String, dynamic>.from(rawGrades.first);
                          } else if (rawGrades is Map) {
                            gradeRecord = Map<String, dynamic>.from(rawGrades);
                          }

                          final String midterm =
                              gradeRecord?['midterm_grade']?.toString() ?? '-';
                          final String finals =
                              gradeRecord?['final_grade']?.toString() ?? '-';
                          final String numeric =
                              gradeRecord?['final_numeric_grade']?.toString() ??
                                  '-';
                          final String remark = (gradeRecord?['status'] ??
                                  loadItem['remarks'] ??
                                  'Ongoing')
                              .toString();

                          Color remarkColor = Colors.blueGrey;
                          if (remark.toUpperCase() == 'PASSED')
                            remarkColor = success;
                          if (remark.toUpperCase() == 'FAILED')
                            remarkColor = danger;
                          if (remark.toUpperCase() == 'DROPPED')
                            remarkColor = Colors.orange;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // UI REFINEMENT: Enlarged grade sheet roster item fonts
                                      Text(code,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textTheme,
                                              fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text("$title ($units Units)",
                                          style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Text("MID",
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(midterm,
                                            style: TextStyle(
                                                color: textTheme,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Text("FIN",
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(finals,
                                            style: TextStyle(
                                                color: textTheme,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Text("GWA",
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(numeric,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textTheme,
                                                fontSize: 14,
                                                fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _badge(
                                        remark.toUpperCase(), remarkColor,
                                        large: true),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CLOSE DETAIL SHEET",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                  if (details?['enrollment_status'] != 'Dropped') ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _dropStudent(s['id'], "${s['fn']} ${s['ln']}");
                      },
                      icon: const Icon(Icons.person_remove_rounded, size: 18),
                      label: const Text("DROP STUDENT",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                    ),
                  ]
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressMetrics(String label, String val, Color color) {
    return Column(
      children: [
        // UI REFINEMENT: Metrical labels enlarged to 11
        Text(label,
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // UI REFINEMENT: Scaled dynamic metrics up to 18
        Text(val,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ],
    );
  }

  Widget _filterLabel(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey,
          letterSpacing: 1));

  Widget _chip(String label, bool active, Function(String) onTap) =>
      GestureDetector(
        onTap: () => onTap(label),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
              color: active ? aViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? Colors.transparent : Colors.white10)),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      );

  Widget _badge(String t, Color c, {bool large = false}) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Text(t,
            style: TextStyle(
                color: c,
                fontSize: large ? 11 : 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      );

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
