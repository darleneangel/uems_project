import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class StudentMasterListPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const StudentMasterListPanel(
      {super.key, required this.isDarkMode, required this.userData});

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
      if (userIdNum == null) return;

      final chairContext = await _service.getChairContext(userIdNum);
      if (chairContext != null) {
        _chairDeptId = chairContext['department_id']?.toString();
        await _fetchStudents();
      }
    } catch (e) {
      debugPrint("Master List Init Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents() async {
    if (_chairDeptId == null) return;

    try {
      // Fetching profile + detailed student context including enrollment_status
      final response = await _service.client
          .from('profiles')
          .select('''
            id, user_id_number, fn, ln,
            student_details!inner(
              student_type,
              enrollment_status,
              courses!inner(code, name, department_id),
              year_levels!inner(definition)
            ),
            study_loads!study_loads_student_id_fkey(
              id,
              subjects(units)
            )
          ''')
          .eq('role', 'student')
          .eq('student_details.courses.department_id', _chairDeptId!);

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Fetch Students Error: $e");
    }
  }

  /// 🛰️ DATABASE ACTION: Administrative Drop
  /// Permanently updates the student's status to 'Dropped' in the institutional ledger.
  Future<void> _dropStudent(String profileId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: danger),
            SizedBox(width: 12),
            Text("Administrative Drop",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to drop $name from the academic roster? \n\n"
          "This action will flag the student as 'Dropped' and restrict further enrollment actions for this term.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: danger, foregroundColor: Colors.white),
            child: const Text("CONFIRM DROP"),
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
    final query = _searchController.text.toLowerCase();
    return _students.where((s) {
      final name = "${s['fn']} ${s['ln']}".toLowerCase();
      final id = (s['user_id_number'] ?? '').toString().toLowerCase();

      final details = s['student_details'];
      final status = details?['enrollment_status'] ?? "Pending";
      final rawType = (details?['student_type'] ?? "Regular").toString();
      final bool isActuallyIrregular = rawType == "Irregular";

      bool matchesSearch = name.contains(query) || id.contains(query);

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

      return matchesSearch && matchesType && matchesStatus;
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
          Text("Departmental Master Roster",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -1)),
          const Text(
              "Management of student profiles, enrollment statuses, and academic standing.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildFilterSuite(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.search,
                    color: Colors.blueGrey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: text),
                    decoration: const InputDecoration(
                        hintText: "Search Name or Student ID...",
                        border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                  const SizedBox(width: 24),
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
          border: Border.all(color: Colors.white10)),
      child: ListView.separated(
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
          final bool isEnrolled = status == "Enrolled" || status == "Cleared";
          final bool isDropped = status == "Dropped";
          final bool isIrreg = details?['student_type'] == 'Irregular';

          final studentName = "${s['fn']} ${s['ln']}";

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isDropped
                  ? danger.withOpacity(0.1)
                  : (isEnrolled
                      ? success.withOpacity(0.1)
                      : warning.withOpacity(0.1)),
              child: Text(s['ln'][0],
                  style: TextStyle(
                      color:
                          isDropped ? danger : (isEnrolled ? success : warning),
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(studentName.toUpperCase(),
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                    "LRD: ${s['user_id_number']} • ${details?['year_levels']?['definition']}",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _badge(status.toUpperCase(),
                        isDropped ? danger : (isEnrolled ? success : warning)),
                    const SizedBox(width: 8),
                    _badge(isIrreg ? "IRREGULAR" : "REGULAR",
                        isIrreg ? Colors.orange : Colors.blueAccent),
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
                    Text(
                        "${_calculateTotalUnits(s['study_loads'] as List)} Units",
                        style: GoogleFonts.orbitron(
                            fontSize: 11,
                            color: text,
                            fontWeight: FontWeight.bold)),
                    const Text("LOADED",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                if (!isDropped)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'drop') _dropStudent(s['id'], studentName);
                    },
                    icon: const Icon(LucideIcons.moreVertical,
                        color: Colors.blueGrey, size: 18),
                    color: surfaceDark,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'drop',
                        child: Row(
                          children: [
                            Icon(LucideIcons.userX, color: danger, size: 16),
                            SizedBox(width: 12),
                            Text("Drop Student",
                                style: TextStyle(
                                    color: danger,
                                    fontSize: 13,
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

  Widget _filterLabel(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey,
          letterSpacing: 1));

  Widget _chip(String label, bool active, Function(String) onTap) =>
      GestureDetector(
        onTap: () => onTap(label),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: active ? aViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? Colors.transparent : Colors.white10)),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      );

  /// 📐 CALCULATION: Sums up units from the subjects linked to the study loads
  double _calculateTotalUnits(List loads) {
    double total = 0;
    for (var l in loads) {
      total +=
          double.tryParse(l['subjects']?['units']?.toString() ?? "0") ?? 0.0;
    }
    return total;
  }

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Text(t,
            style: TextStyle(
                color: c,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
