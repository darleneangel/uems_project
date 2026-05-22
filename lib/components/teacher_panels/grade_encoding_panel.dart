import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class GradeEncodingPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData; // Context for the logged-in Teacher

  const GradeEncodingPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<GradeEncodingPanel> createState() => _GradeEncodingPanelState();
}

class _GradeEncodingPanelState extends State<GradeEncodingPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  // --- DATABASE DATA ---
  List<Map<String, dynamic>> _mySubjects = [];
  List<Map<String, dynamic>> _roster = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // --- CONTROLLER CACHE ---
  // Prevents focus loss and UI jitter when typing in a list
  final Map<String, Map<String, TextEditingController>> _inputControllers = {};

  // --- FILTER STATE ---
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);
  static const Color danger = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _loadTeacherLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var studentIdMap in _inputControllers.values) {
      for (var controller in studentIdMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// 🛰️ DATABASE: Load unique subjects assigned to this professor
  Future<void> _loadTeacherLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _service.client
          .from('study_loads')
          .select('subject_id, subjects(id, code, name)')
          .eq('professor_id', widget.userData['id']);

      final List<dynamic> raw = response as List;
      final Map<String, Map<String, dynamic>> unique = {};

      for (var item in raw) {
        final sub = item['subjects'] as Map<String, dynamic>?;
        if (sub != null) {
          unique[sub['id'].toString()] = sub;
        }
      }

      if (mounted) {
        setState(() {
          _mySubjects = unique.values.toList();
          if (_mySubjects.isNotEmpty) {
            _selectedSubjectId = _mySubjects.first['id'].toString();
            _selectedSubjectName =
                "${_mySubjects.first['code']} - ${_mySubjects.first['name']}";
            _loadRoster();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Load Teacher Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Fetch unique student roster with associated Grade records
  Future<void> _loadRoster() async {
    if (_selectedSubjectId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await _service.client
          .from('study_loads')
          .select('''
            id, 
            student_id,
            profiles!study_loads_student_id_fkey (
              id, 
              fn, 
              ln, 
              user_id_number
            ),
            grades (
              id,
              midterm_grade,
              final_grade,
              final_numeric_grade,
              status
            )
          ''')
          .eq('professor_id', widget.userData['id'])
          .eq('subject_id', _selectedSubjectId!)
          .filter('student_id', 'not.is', null);

      final List<dynamic> rawData = response as List;

      // 🛡️ UNIQUE FILTER: Ensures students only appear once per class
      final Map<String, Map<String, dynamic>> uniqueRoster = {};

      for (var item in rawData) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        if (profile == null) continue;

        final String studentIdNum = profile['user_id_number'].toString();

        // SAFE EXTRACTION: Handle Supabase Map vs List variations
        final dynamic gradeData = item['grades'];
        Map<String, dynamic>? activeGradeMap;

        if (gradeData is List && gradeData.isNotEmpty) {
          activeGradeMap = Map<String, dynamic>.from(gradeData.first);
        } else if (gradeData is Map<String, dynamic>) {
          activeGradeMap = gradeData;
        }

        // Add if not present; if present, prioritize records that actually have grades
        final bool currentHasGrade = activeGradeMap != null;
        final bool existingHasGrade = uniqueRoster.containsKey(studentIdNum) &&
            uniqueRoster[studentIdNum]!['active_grade']['id'] != null;

        if (!uniqueRoster.containsKey(studentIdNum) ||
            (currentHasGrade && !existingHasGrade)) {
          final Map<String, dynamic> activeGrade = activeGradeMap ??
              {
                'midterm_grade': '',
                'final_grade': '',
                'final_numeric_grade': 0.0,
                'status': 'Draft'
              };

          item['active_grade'] = activeGrade;
          item['weighted_raw_avg'] = _calculateWeightedRaw(
              activeGrade['midterm_grade'], activeGrade['final_grade']);

          // Setup Controllers for this specific student
          _inputControllers.putIfAbsent(
              studentIdNum,
              () => {
                    'midterm_grade': TextEditingController(
                        text: activeGrade['midterm_grade']?.toString() ?? ""),
                    'final_grade': TextEditingController(
                        text: activeGrade['final_grade']?.toString() ?? ""),
                  });

          uniqueRoster[studentIdNum] = Map<String, dynamic>.from(item);
        }
      }

      if (mounted) {
        setState(() {
          _roster = uniqueRoster.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Roster Sync Error: $e");
      _showToast("Error syncing roster.", danger);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Batch Save Grades using 'study_load_id' conflict target
  Future<void> _saveAllGrades() async {
    // 🛡️ FINAL AUDIT: Block save if any grade is out of institutional range or missing
    for (var row in _roster) {
      final String mRaw = row['active_grade']['midterm_grade'].toString();
      final String fRaw = row['active_grade']['final_grade'].toString();

      if (mRaw.isEmpty || fRaw.isEmpty) {
        _showToast("COMMIT BLOCKED: Some student grades are missing.", danger);
        return;
      }

      final double m = double.tryParse(mRaw) ?? 0.0;
      final double f = double.tryParse(fRaw) ?? 0.0;

      if (m > 95.0 || f > 95.0 || m < 75.0 || f < 75.0) {
        _showToast(
            "COMMIT BLOCKED: Roster contains grades outside 75.0 - 95.0 range.",
            danger);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> upsertData = [];

      for (var row in _roster) {
        final activeGrade = row['active_grade'];
        final double rawAvg = row['weighted_raw_avg'] ?? 0.0;
        final double transmuted = _transmuteToScale(rawAvg);

        upsertData.add({
          'study_load_id': row['id'],
          'midterm_grade': activeGrade['midterm_grade'].toString(),
          'final_grade': activeGrade['final_grade'].toString(),
          'final_numeric_grade': transmuted,
          'graded_by': widget.userData['id'],
          'status': 'Encoded',
          'graded_at': DateTime.now().toIso8601String(),
        });
      }

      if (upsertData.isNotEmpty) {
        await _service.client
            .from('grades')
            .upsert(upsertData, onConflict: 'study_load_id');

        _showToast(
            "Class grades successfully committed to institutional ledger.",
            success);
        _loadRoster();
      }
    } catch (e) {
      debugPrint("Batch Save Error: $e");
      _showToast("Sync Error: Database rejected the update.", danger);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 📐 LOGIC: Weighted Raw Average (40% Midterm, 60% Final)
  /// This provides the "Raw Performance Score" before scale conversion.
  double _calculateWeightedRaw(dynamic rawMidterm, dynamic rawFinal) {
    if (rawMidterm.toString().isEmpty || rawFinal.toString().isEmpty)
      return 0.0;

    double m = double.tryParse(rawMidterm.toString()) ?? 0.0;
    double f = double.tryParse(rawFinal.toString()) ?? 0.0;

    // Formula: (Midterm * 40%) + (Final * 60%)
    return (m * 0.4) + (f * 0.6);
  }

  /// 📐 LOGIC: Transmutation to 1.00-5.00 Scale (Institutional Standard)
  /// Basis:
  /// 95-100% = 1.00 (Outstanding)
  /// 91-94%  = 1.25 (Very Good)
  /// 87-90%  = 1.50 (Very Good)
  /// 83-86%  = 1.75 (Good)
  /// 79-82%  = 2.00 (Good)
  /// 75-78%  = 3.00 (Passing)
  /// < 75%   = 5.00 (Failing)
  double _transmuteToScale(double average) {
    if (average == 0) return 0.0;
    if (average >= 95) return 1.00;
    if (average >= 91) return 1.25;
    if (average >= 87) return 1.50;
    if (average >= 83) return 1.75;
    if (average >= 79) return 2.00;
    if (average >= 75) return 3.00;
    return 5.00;
  }

  /// 📐 LOGIC: Validation Check for Error Trapping
  bool _isInvalid(String value) {
    if (value.isEmpty) return true; // Missing input is invalid
    double? val = double.tryParse(value);
    if (val == null) return true;
    return val > 95.0 || val < 75.0; // Out of range is invalid
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildFilterBar(bgColor, textColor),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(80),
                    child: CircularProgressIndicator(color: aViolet)))
          else if (_roster.isEmpty)
            _buildEmptyState(textColor)
          else
            _buildEncodingModule(bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Grade Encoding Terminal",
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: text,
                letterSpacing: -1)),
        const Text(
            "Instructions: Enter scores between 75.0 and 95.0. Results are computed via a 40/60 weighted split.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
      ],
    );
  }

  Widget _buildFilterBar(Color bg, Color text) {
    // Audit current roster validity for Button State
    bool isRosterValid = _roster.every((row) {
      String mStr = row['active_grade']['midterm_grade'].toString();
      String fStr = row['active_grade']['final_grade'].toString();
      if (mStr.isEmpty || fStr.isEmpty) return false;
      double m = double.tryParse(mStr) ?? 0;
      double f = double.tryParse(fStr) ?? 0;
      return m >= 75 && m <= 95 && f >= 75 && f <= 95;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          _buildDropdown("Class Assignment", _selectedSubjectId, _mySubjects,
              (v) {
            final selected =
                _mySubjects.firstWhere((s) => s['id'].toString() == v);
            setState(() {
              _selectedSubjectId = v;
              _selectedSubjectName =
                  "${selected['code']} - ${selected['name']}";
            });
            _loadRoster();
          }),
          const Spacer(),
          _exportBtn(LucideIcons.fileText, "DOWNLOAD ROSTER", _generateGradePDF,
              aViolet),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (_isSaving || _roster.isEmpty || !isRosterValid)
                ? null
                : _saveAllGrades,
            icon: _isSaving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.save),
            label: Text(
                !isRosterValid ? "REVIEWS PENDING (*)" : "COMMIT CLASS GRADES",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: !isRosterValid ? Colors.blueGrey : success,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ],
      ),
    );
  }

  Widget _buildEncodingModule(Color bg, Color text) {
    final query = _searchController.text.toLowerCase();
    final filteredRoster = _roster.where((s) {
      final name =
          "${s['profiles']['fn']} ${s['profiles']['ln']}".toLowerCase();
      final id = s['profiles']['user_id_number'].toString();
      return name.contains(query) || id.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: text, fontSize: 14),
            decoration: const InputDecoration(
              hintText: "Search specific student by name or LRD ID...",
              prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1, color: Colors.white10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRoster.length,
                itemBuilder: (context, i) =>
                    _buildGradeRow(filteredRoster[i], text),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: widget.isDarkMode
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.01),
      child: Row(
        children: [
          _tableHead("ID NUMBER", 2),
          _tableHead("STUDENT NAME", 4),
          _tableHead("MIDTERM (40%)", 2),
          _tableHead("FINAL (60%)", 2),
          _tableHead("WEIGHTED RAW", 2),
          _tableHead("NUMERIC GWA", 2),
        ],
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> s, Color text) {
    final profile = s['profiles'];
    final double rawAvg = s['weighted_raw_avg'] ?? 0.0;
    final double transmuted = _transmuteToScale(rawAvg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(profile['user_id_number'].toString(),
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
          Expanded(
              flex: 4,
              child: Text("${profile['ln']}, ${profile['fn']}".toUpperCase(),
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: _gradeInput(s, 'midterm_grade')),
          Expanded(flex: 2, child: _gradeInput(s, 'final_grade')),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text(rawAvg > 0 ? rawAvg.toStringAsFixed(1) : "-",
                      style: TextStyle(
                          color: text.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)))),
          Expanded(flex: 2, child: Center(child: _gwaBadge(transmuted))),
        ],
      ),
    );
  }

  Widget _gradeInput(Map<String, dynamic> s, String field) {
    final String studentIdNum = s['profiles']['user_id_number'].toString();
    final controller = _inputControllers[studentIdNum]?[field];
    final String value = s['active_grade'][field]?.toString() ?? "";
    final bool invalid = _isInvalid(value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : pViolet,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "75.0",
                hintStyle: const TextStyle(color: Colors.white10),
                filled: true,
                fillColor: aViolet.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                setState(() {
                  s['active_grade'][field] = v;
                  s['weighted_raw_avg'] = _calculateWeightedRaw(
                      s['active_grade']['midterm_grade'],
                      s['active_grade']['final_grade']);
                });
              },
            ),
          ),
          if (invalid)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text("*",
                  style: TextStyle(
                      color: danger,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _gwaBadge(double gwa) {
    if (gwa == 0)
      return const Text("-", style: TextStyle(color: Colors.blueGrey));
    final color = gwa <= 3.0 ? success : danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(gwa.toStringAsFixed(2),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _tableHead(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)));

  Widget _buildDropdown(String label, String? value,
      List<Map<String, dynamic>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: surfaceDark,
            style: TextStyle(
                color: widget.isDarkMode ? Colors.white : pViolet,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            items: items
                .map((i) => DropdownMenuItem(
                    value: i['id'].toString(),
                    child: Text("${i['code']} - ${i['name']}",
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged,
          )),
        ),
      ],
    );
  }

  Widget _exportBtn(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildEmptyState(Color t) => Center(
      child: Padding(
          padding: const EdgeInsets.all(80),
          child: Column(children: [
            Icon(LucideIcons.users, size: 48, color: t.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text("No students found in this roster.",
                style: TextStyle(color: t.withOpacity(0.2)))
          ])));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _generateGradePDF() async {
    if (_roster.isEmpty) return;
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (c) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("OFFICIAL CLASS GRADE ROSTER",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text("Subject: $_selectedSubjectName"),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    "ID",
                    "Student Name",
                    "Midterm",
                    "Final",
                    "Weighted",
                    "GWA"
                  ],
                  data: _roster
                      .map((s) => [
                            s['profiles']['user_id_number'],
                            "${s['profiles']['ln']}, ${s['profiles']['fn']}"
                                .toUpperCase(),
                            s['active_grade']['midterm_grade'],
                            s['active_grade']['final_grade'],
                            s['weighted_raw_avg'].toStringAsFixed(1),
                            _transmuteToScale(s['weighted_raw_avg'])
                                .toStringAsFixed(2)
                          ])
                      .toList(),
                ),
              ])),
    ));
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/GradeRoster_${_selectedSubjectId}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
