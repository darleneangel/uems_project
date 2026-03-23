import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class FacultyLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const FacultyLoadPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<FacultyLoadPanel> createState() => _FacultyLoadPanelState();
}

class _FacultyLoadPanelState extends State<FacultyLoadPanel> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _service = SupabaseService();

  String _activeLoadFilter = "All";
  bool _isLoading = true;
  String? _chairDeptId;
  String? _chairDeptName;
  Map<String, dynamic>? _activeTerm;

  List<Map<String, dynamic>> _facultyList = [];
  List<Map<String, dynamic>> _globalSubjectCatalog = [];

  // Statistics
  int _totalFaculty = 0;
  int _overloadedCount = 0;
  int _underloadedCount = 0;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD740);

  @override
  void initState() {
    super.initState();
    _initializeFacultyOversight();
  }

  /// 🛰️ INITIALIZE: Resolve Chair context, Active Term, and load Analytics
  Future<void> _initializeFacultyOversight() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final String? userIdNum = widget.userData['user_id_number']?.toString();
      if (userIdNum == null) return;

      final chairData = await _service.getChairContext(userIdNum);
      final termRes = await _service.getActiveTerm();

      if (chairData != null) {
        _chairDeptId = chairData['department_id']?.toString();
        _chairDeptName = chairData['departments']?['name'];
        _activeTerm = termRes;

        await _fetchSubjectCatalog();
        await _fetchFacultyLoadData();
      }
    } catch (e) {
      debugPrint("Institutional Oversight Init Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSubjectCatalog() async {
    final response = await _service.client.from('subjects').select('*');
    if (mounted) {
      setState(() =>
          _globalSubjectCatalog = List<Map<String, dynamic>>.from(response));
    }
  }

  /// 🛰️ DATABASE: Aggregate Faculty Loads with Full Profile Context
  Future<void> _fetchFacultyLoadData() async {
    if (_chairDeptId == null) return;
    try {
      final List<Map<String, dynamic>> profData =
          await _service.getFacultyDetailed(_chairDeptId!);

      int overloaded = 0;
      int underloaded = 0;

      for (var prof in profData) {
        final List<Map<String, dynamic>> loads =
            await _service.getMasterLoads(prof['id']);

        int totalUnits = 0;
        for (var l in loads) {
          totalUnits +=
              int.tryParse(l['subjects']?['units']?.toString() ?? "0") ?? 0;
        }

        prof['current_units'] = totalUnits;
        prof['master_loads'] = loads;

        if (totalUnits > 21) overloaded++;
        if (totalUnits < 12) underloaded++;
      }

      if (mounted) {
        setState(() {
          _facultyList = profData;
          _totalFaculty = profData.length;
          _overloadedCount = overloaded;
          _underloadedCount = underloaded;
        });
      }
    } catch (e) {
      debugPrint("Data Sync Error: $e");
    }
  }

  /// 🛠️ DATABASE: Insert new assignment into the Master Schedule
  Future<void> _assignSubject(
      String profId, String subId, String day, String time) async {
    final prof = _facultyList.firstWhere((p) => p['id'] == profId);
    final sub =
        _globalSubjectCatalog.firstWhere((s) => s['id'].toString() == subId);
    final int unitsToAdd = int.tryParse(sub['units'].toString()) ?? 0;

    if ((prof['current_units'] ?? 0) + unitsToAdd > 21) {
      _showToast(
          "ASSIGNMENT REJECTED: Maximum capacity (21 Units) reached.", danger);
      return;
    }

    try {
      await _service.client.from('study_loads').insert({
        'professor_id': profId,
        'subject_id': subId,
        'day_schedule': day,
        'time_start': time.contains('-') ? time.split('-')[0].trim() : time,
        'time_end': time.contains('-') ? time.split('-')[1].trim() : "TBD",
        'student_id': null,
        'section_block': 'MASTER',
        'is_locked': false,
      });

      _showToast("Institutional Master Schedule Updated.", success);
      await _fetchFacultyLoadData();
    } catch (e) {
      _showToast("Sync Error: $e", danger);
    }
  }

  Future<void> _deleteMasterLoad(String loadId) async {
    try {
      await _service.client.from('study_loads').delete().eq('id', loadId);
      await _fetchFacultyLoadData();
      _showToast("Schedule Entry Revoked.", warning);
    } catch (e) {
      _showToast("Deletion Error.", danger);
    }
  }

  /// 🔍 FILTER LOGIC
  List<Map<String, dynamic>> get _filteredFaculty {
    final query = _searchController.text.toLowerCase();
    return _facultyList.where((f) {
      final name = "${f['fn']} ${f['ln']}".toLowerCase();
      final id = (f['user_id_number'] ?? '').toString().toLowerCase();
      final units = f['current_units'] ?? 0;

      bool matchesSearch = name.contains(query) || id.contains(query);
      bool matchesLoad = true;

      if (_activeLoadFilter == "Overloaded") {
        matchesLoad = units > 21;
      } else if (_activeLoadFilter == "Underloaded") {
        matchesLoad = units < 12;
      } else if (_activeLoadFilter == "Regular") {
        matchesLoad = units >= 12 && units <= 21;
      }

      return matchesSearch && matchesLoad;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
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
          Row(
            children: [
              _statCard("Total Faculty", _totalFaculty.toString(),
                  LucideIcons.users, aViolet, cardColor, textColor),
              _statCard("Overloaded", _overloadedCount.toString(),
                  LucideIcons.alertTriangle, danger, cardColor, textColor),
              _statCard("Underloaded", _underloadedCount.toString(),
                  LucideIcons.trendingDown, warning, cardColor, textColor),
            ],
          ),
          const SizedBox(height: 32),
          _buildFilterBar(cardColor, textColor),
          const SizedBox(height: 24),
          _buildFacultyList(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Faculty Load Balancing",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          Text(
              "Department: ${_chairDeptName ?? 'N/A'} | Master Schedule Oversight.",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _statCard(String label, String val, IconData icon, Color color,
          Color bg, Color text) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(val,
                      style: GoogleFonts.orbitron(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: text)),
                  Text(label.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildFilterBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
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
                    hintText: "Search Employee ID or Name...",
                    border: InputBorder.none),
              ),
            ),
            const VerticalDivider(color: Colors.white10),
            _loadFilterChip("All"),
            _loadFilterChip("Regular"),
            _loadFilterChip("Overloaded"),
            _loadFilterChip("Underloaded"),
          ],
        ),
      );

  Widget _loadFilterChip(String label) {
    bool active = _activeLoadFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeLoadFilter = label),
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

  Widget _buildFacultyList(Color bg, Color text) => Container(
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredFaculty.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Colors.white10, height: 1),
          itemBuilder: (context, i) {
            final f = _filteredFaculty[i];
            final int units = f['current_units'] ?? 0;
            final String type =
                f['employee_details']?['faculty_type'] ?? "Specialist";
            final bool isGenEd = type == "Gen Ed";

            return ListTile(
              contentPadding: const EdgeInsets.all(24),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: isGenEd
                    ? Colors.blueAccent.withOpacity(0.1)
                    : aViolet.withOpacity(0.1),
                child: Icon(isGenEd ? LucideIcons.book : LucideIcons.cpu,
                    color: isGenEd ? Colors.blueAccent : aViolet, size: 20),
              ),
              title: Text("${f['fn']} ${f['ln']}",
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "ID: ${f['user_id_number'] ?? 'N/A'} • ${f['employee_details']?['position_title'] ?? 'Faculty'}",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  _typeBadge(type.toUpperCase(),
                      isGenEd ? Colors.blueAccent : aViolet),
                ],
              ),
              trailing: SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("$units / 21 Units",
                              style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  color: units > 21 ? danger : text,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: (units / 21).clamp(0.0, 1.0),
                                color: units > 21
                                    ? danger
                                    : (units < 12 ? warning : success),
                                backgroundColor: Colors.white10,
                                minHeight: 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                        onPressed: () => _showManageLoadDialog(f),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: aViolet),
                        child: const Text("SCHEDULE")),
                  ],
                ),
              ),
            );
          },
        ),
      );

  void _showManageLoadDialog(Map<String, dynamic> prof) {
    final String type = prof['employee_details']?['faculty_type'] ?? "";
    final bool isGenEd = type == "Gen Ed";

    final filteredSubjects = _globalSubjectCatalog.where((s) {
      if (isGenEd) return (s['is_professional_course'] == false);
      return (s['department_id']?.toString() == _chairDeptId);
    }).toList();

    String? selSubId;
    final dayCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final List masterLoads = prof['master_loads'] ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          scrollable: false,
          backgroundColor: surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text("Schedule Master: ${prof['fn']}",
              style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "ASSIGNING TO: ${isGenEd ? 'GENERAL EDUCATION' : 'SPECIALIZED'}",
                      style: const TextStyle(
                          color: aViolet,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selSubId,
                    isExpanded: true,
                    dropdownColor: surfaceDark,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _modalInput("Select Subject"),
                    items: filteredSubjects
                        .map((s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text("${s['code']} - ${s['name']}",
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selSubId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: dayCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _modalInput("Day (e.g. MWF)")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: timeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _modalInput("Time Slot (e.g. 09:00 - 10:30)")),
                  const SizedBox(height: 24),
                  const Text("EXISTING ASSIGNMENTS",
                      style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (masterLoads.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No master schedules assigned.",
                            style:
                                TextStyle(color: Colors.white24, fontSize: 11)))
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: masterLoads.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (ctx, i) {
                          final l = masterLoads[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(l['subjects']?['name'] ?? 'Subject',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            subtitle: Text(
                                "${l['day_schedule']} | ${l['time_start']}",
                                style: const TextStyle(
                                    color: Colors.blueGrey, fontSize: 10)),
                            trailing: IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    size: 14, color: danger),
                                onPressed: () {
                                  _deleteMasterLoad(l['id']);
                                  Navigator.pop(context);
                                }),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL",
                    style: TextStyle(color: Colors.blueGrey))),
            ElevatedButton(
                onPressed: selSubId == null
                    ? null
                    : () {
                        _assignSubject(
                            prof['id'], selSubId!, dayCtrl.text, timeCtrl.text);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                child: const Text("SAVE ASSIGNMENT")),
          ],
        ),
      ),
    );
  }

  InputDecoration _modalInput(String l) => InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  Widget _typeBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
