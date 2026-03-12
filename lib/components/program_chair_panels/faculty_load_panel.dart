import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class FacultyLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  const FacultyLoadPanel({super.key, required this.isDarkMode});

  @override
  State<FacultyLoadPanel> createState() => _FacultyLoadPanelState();
}

class _FacultyLoadPanelState extends State<FacultyLoadPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = "All";

  bool _isLoading = true;
  String? _chairDeptId;
  String? _chairDeptName;
  List<Map<String, dynamic>> _facultyList = [];
  int _totalAssignedUnits = 0;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _initializeFacultyOversight();
  }

  /// 🛰️ STEP 1: Handshake - Identify the Chair and their managed Department
  Future<void> _initializeFacultyOversight() async {
    setState(() => _isLoading = true);
    final client = SupabaseService().client;
    final user = client.auth.currentUser;

    try {
      // Find the Chair's department
      final chairData = await client
          .from('employee_details')
          .select('department_id, departments(name)')
          .eq('profile_id', user!.id)
          .maybeSingle();

      if (chairData != null) {
        _chairDeptId = chairData['department_id'];
        _chairDeptName = chairData['departments']['name'];
      }

      await _fetchFacultyLoadData();
    } catch (e) {
      debugPrint("Context Initialization Error: $e");
    }
  }

  /// 🛰️ STEP 2: Fetch Professors (Filtered by Dept + Gen Ed + Expertise)
  Future<void> _fetchFacultyLoadData() async {
    final client = SupabaseService().client;

    try {
      // 1. Deep join fetch: Profiles -> Employee Details -> Expertise -> Subjects
      final List<dynamic> profData = await client.from('profiles').select('''
            *,
            employee_details!inner(*, departments!inner(*)),
            professor_expertise (
              subjects (*)
            )
          ''').eq('role', 'professor');

      // 2. Filter logic: Show specialists in Chair's Dept OR Gen Ed staff (CAS)
      final List<Map<String, dynamic>> filteredList =
          List<Map<String, dynamic>>.from(profData).where((p) {
        final String deptName = p['employee_details']['departments']['name'];
        final String deptId = p['employee_details']['department_id'];

        return deptId == _chairDeptId ||
            deptName.contains("General Education") ||
            deptName.contains("Gen Ed") ||
            deptName == "CAS";
      }).toList();

      // 3. Aggregate Units for Statistics
      int unitSum = 0;
      for (var prof in filteredList) {
        final List<dynamic> loads = await client
            .from('study_loads')
            .select('subjects(units)')
            .eq('professor_id', prof['id']);

        int profUnits = 0;
        for (var l in loads) {
          profUnits += (l['subjects']['units'] as int? ?? 0);
        }
        prof['current_units'] = profUnits;
        unitSum += profUnits;
      }

      if (mounted) {
        setState(() {
          _facultyList = filteredList;
          _totalAssignedUnits = unitSum;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Faculty Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getProcessedList() {
    final query = _searchController.text.toLowerCase();
    return _facultyList.where((f) {
      final name = "${f['fn']} ${f['ln']}".toLowerCase();
      final pos = f['employee_details']['position'].toString().toLowerCase();
      final matchesSearch = name.contains(query) || pos.contains(query);

      if (_activeFilter == "Overloaded")
        return matchesSearch && (f['current_units'] ?? 0) > 21;
      if (_activeFilter == "Underloaded")
        return matchesSearch && (f['current_units'] ?? 0) < 12;
      if (_activeFilter == "Regular")
        return matchesSearch &&
            (f['current_units'] ?? 0) >= 12 &&
            (f['current_units'] ?? 0) <= 21;

      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    final filteredList = _getProcessedList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // 2. ANALYTICS ROW (Live Data)
          Row(
            children: [
              _statItem("Managed Faculty", _facultyList.length.toString(),
                  LucideIcons.users, aViolet, textColor),
              const SizedBox(width: 20),
              _statItem("Total Units Assigned", _totalAssignedUnits.toString(),
                  LucideIcons.layers, success, textColor),
              const SizedBox(width: 20),
              _statItem(
                  "Avg Unit Load",
                  (_totalAssignedUnits /
                          (_facultyList.isEmpty ? 1 : _facultyList.length))
                      .toStringAsFixed(1),
                  LucideIcons.activity,
                  Colors.blueAccent,
                  textColor),
            ],
          ),
          const SizedBox(height: 32),

          _buildFilterBar(textColor),
          const SizedBox(height: 24),

          // 4. FACULTY DIRECTORY LIST
          _buildFacultyList(filteredList, textColor, bgColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Faculty Load & Assignment",
          style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1),
        ),
        Text(
          "Department: ${_chairDeptName ?? 'Managed Units'} | Tracking specialization and workload balancing.",
          style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Search faculty name or position...",
                hintStyle: TextStyle(color: Colors.blueGrey),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _filterChip("All"),
        _filterChip("Regular"),
        _filterChip("Overloaded"),
        _filterChip("Underloaded"),
      ],
    );
  }

  Widget _buildFacultyList(
      List<Map<String, dynamic>> list, Color textColor, Color bgColor) {
    if (list.isEmpty) return _buildEmptyState(textColor);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: list.map((f) => _buildFacultyItem(f, textColor)).toList(),
      ),
    );
  }

  Widget _buildFacultyItem(Map<String, dynamic> f, Color textColor) {
    final int units = f['current_units'] ?? 0;
    final String status = units > 21
        ? "Overloaded"
        : (units < 12 ? "Underloaded" : "Regular Load");
    final Color statusColor = units > 21
        ? Colors.orangeAccent
        : (units < 12 ? Colors.blueAccent : success);

    final List expertise = f['professor_expertise'] as List;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    aViolet.withOpacity(0.2),
                    aViolet.withOpacity(0.05)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                    child: Text(f['ln'][0],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: aViolet))),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${f['fn']} ${f['ln']}",
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text(
                        "${f['employee_details']['position']} • ${f['employee_details']['faculty_type']}",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 12)),
                    const SizedBox(height: 12),
                    // FEATURE: Expertise Chips
                    if (expertise.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: expertise.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: aViolet.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: aViolet.withOpacity(0.1)),
                            ),
                            child: Text(
                              e['subjects']['code'],
                              style: const TextStyle(
                                  color: aViolet,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text("No specialization assigned",
                          style: TextStyle(
                              color: Colors.white10,
                              fontSize: 10,
                              fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Load",
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                        Text("$units/24 Units",
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: units / 24,
                          backgroundColor: Colors.white10,
                          color: statusColor,
                          minHeight: 6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _statusBadge(status, statusColor),
                    if (units > 21)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(LucideIcons.alertTriangle,
                            color: Colors.orangeAccent, size: 16),
                      ),
                  ],
                ),
              ),
              _iconAction(
                LucideIcons.bookOpen,
                "View Current Assignments",
                aViolet,
                () => _showProfessorSchedule(f),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
      ],
    );
  }

  /// FEATURE: Detailed Professor Schedule Modal
  void _showProfessorSchedule(Map<String, dynamic> prof) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
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
                    Text("${prof['fn']} ${prof['ln']}",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const Text("Current Academic Assignments",
                        style: TextStyle(color: Colors.blueGrey)),
                  ],
                ),
                _statusBadge("${prof['current_units']} Units", aViolet),
              ],
            ),
            const Divider(height: 60, color: Colors.white10),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: SupabaseService()
                    .client
                    .from('study_loads')
                    .select('*, subjects(*)')
                    .eq('professor_id', prof['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final loads = snapshot.data!;
                  if (loads.isEmpty)
                    return const Center(
                        child: Text(
                            "No active subjects assigned for this semester.",
                            style: TextStyle(color: Colors.white24)));

                  return ListView.builder(
                    itemCount: loads.length,
                    itemBuilder: (context, i) {
                      final l = loads[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar,
                                color: aViolet, size: 18),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(l['subjects']['name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "${l['day_schedule']} • ${l['time_start']} - ${l['time_end']}",
                                      style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12)),
                                ])),
                            Text("${l['subjects']['units']} Units",
                                style: const TextStyle(
                                    color: success,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
      String label, String value, IconData icon, Color color, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.blueGrey.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w900)));

  Widget _iconAction(
      IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color.withOpacity(0.6), size: 18),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  TextStyle _metaStyle() => const TextStyle(
        color: Colors.blueGrey,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      );

  Widget _buildEmptyState(Color textColor) => Center(
      child: Padding(
          padding: const EdgeInsets.all(80),
          child: Text("No professors matching criteria in managed departments.",
              style: TextStyle(color: textColor.withOpacity(0.2)))));
}
