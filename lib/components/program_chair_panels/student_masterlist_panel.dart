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
  String? _chairDeptId;
  List<Map<String, dynamic>> _students = [];
  String _activeFilter = "All";

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);
  static const Color pViolet = Color(0xFF2E1065);

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

      // 1. Get Chair's Department ID
      final chairContext = await _service.getChairContext(userIdNum);
      if (chairContext != null) {
        _chairDeptId = chairContext['department_id']?.toString();

        // 2. Fetch Students with full relational data
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
      // Deep fetch: profiles -> student_details -> study_loads -> subjects
      final response = await _service.client
          .from('profiles')
          .select('''
            id, user_id_number, fn, ln,
            student_details!inner(
              student_type,
              courses!inner(code, department_id),
              year_levels!inner(definition)
            ),
            study_loads!study_loads_student_id_fkey(
              id, day_schedule, time_start, time_end,
              subjects(code, name, units)
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

  List<Map<String, dynamic>> get _filteredStudents {
    final query = _searchController.text.toLowerCase();
    return _students.where((s) {
      final name = "${s['fn']} ${s['ln']}".toLowerCase();
      final id = s['user_id_number'].toString();
      final type = s['student_details']?['student_type'] ?? "";

      bool matchesSearch = name.contains(query) || id.contains(query);
      bool matchesType = _activeFilter == "All" || type == _activeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildFilterBar(cardColor, textColor),
          const SizedBox(height: 24),
          _buildStudentTable(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Student Master Directory",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -1)),
          const Text(
              "Comprehensive view of all departmental students and their current academic loads.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildFilterBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(LucideIcons.search, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: text),
                decoration: const InputDecoration(
                    hintText: "Search Student Name or ID...",
                    border: InputBorder.none),
              ),
            ),
            _typeFilterChip("All"),
            _typeFilterChip("Regular"),
            _typeFilterChip("Irregular"),
          ],
        ),
      );

  Widget _typeFilterChip(String label) {
    bool active = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: active ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? Colors.transparent : Colors.white10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

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
            const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, i) {
          final s = list[i];
          final details = s['student_details'];
          final loads = s['study_loads'] as List;
          final bool isIrreg = details?['student_type'] == 'Irregular';

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(s['ln'][0],
                      style: const TextStyle(
                          color: aViolet, fontWeight: FontWeight.bold))),
            ),
            title: Text("${s['fn']} ${s['ln']}",
                style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Text(
                    "ID: ${s['user_id_number']} • ${details?['year_levels']?['definition']}",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(width: 12),
                _badge(isIrreg ? "IRREGULAR" : "REGULAR",
                    isIrreg ? Colors.orange : success),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${loads.length} Subjects",
                        style: GoogleFonts.orbitron(
                            fontSize: 11,
                            color: aViolet,
                            fontWeight: FontWeight.bold)),
                    Text("${_calculateTotalUnits(loads)} Total Units",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(LucideIcons.eye, color: aViolet, size: 20),
                  onPressed: () => _showLoadDetails(s),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLoadDetails(Map<String, dynamic> student) {
    final loads = student['study_loads'] as List;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white10)),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${student['fn']} ${student['ln']}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text(
                        "Assigned Subject Load - ${student['student_details']?['year_levels']?['definition']}",
                        style: const TextStyle(color: Colors.blueGrey)),
                  ],
                ),
                _badge("${_calculateTotalUnits(loads)} Units", aViolet),
              ],
            ),
            const Divider(height: 60, color: Colors.white10),
            Expanded(
              child: loads.isEmpty
                  ? const Center(
                      child: Text("No subjects enrolled yet.",
                          style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      itemCount: loads.length,
                      itemBuilder: (context, i) {
                        final l = loads[i];
                        final sub = l['subjects'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.bookOpen,
                                  color: aViolet, size: 18),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub['name'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        "${l['day_schedule']} • ${l['time_start']} - ${l['time_end']}",
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text("${sub['units']} Units",
                                  style: const TextStyle(
                                      color: success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalUnits(List loads) {
    return loads.fold(
        0.0,
        (sum, l) =>
            sum + (double.tryParse(l['subjects']['units'].toString()) ?? 0.0));
  }

  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));
}
