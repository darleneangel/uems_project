import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
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

  // --- FILTER STATE ---
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  Color? get textColor => null;

  @override
  void initState() {
    super.initState();
    _loadTeacherLoad();
  }

  /// 🛰️ DATABASE: Load subjects assigned to this professor from study_loads
  Future<void> _loadTeacherLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _service.client
          .from('study_loads')
          .select('subject_id, subjects(id, code, name)')
          .eq('professor_id', widget.userData['id']);

      final List<dynamic> raw = response as List;
      final Map<String, dynamic> unique = {};

      for (var item in raw) {
        final sub = item['subjects'];
        if (sub != null) unique[sub['id'].toString()] = sub;
      }

      if (mounted) {
        setState(() {
          _mySubjects = unique.values.cast<Map<String, dynamic>>().toList();
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

  /// 🛰️ DATABASE: Fetch the roster with associated Grade records
  Future<void> _loadRoster() async {
    if (_selectedSubjectId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await _service.client
          .from('study_loads')
          .select('''
            id, 
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
              final_numeric_grade
            )
          ''')
          .eq('professor_id', widget.userData['id'])
          .eq('subject_id', _selectedSubjectId!)
          .not('student_id', 'is', null);

      if (mounted) {
        setState(() {
          _roster = List<Map<String, dynamic>>.from(response).map((item) {
            final gradesList = item['grades'] as List?;

            // Map raw values for UI inputs and calculated values for DB
            item['active_grade'] = (gradesList != null && gradesList.isNotEmpty)
                ? Map<String, dynamic>.from(gradesList.first)
                : {
                    'midterm_grade': '0',
                    'final_grade': '0', // Raw Input Final Percentage
                    'final_numeric_grade': 0.0 // The Transmuted scale (1.0-5.0)
                  };

            // Internal calculation for UI Display
            item['weighted_raw_avg'] = _calculateWeightedRaw(
                item['active_grade']['midterm_grade'],
                item['active_grade']['final_grade']);

            return item;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Roster Sync Error: $e");
      _showToast("Error syncing roster.", Colors.redAccent);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Update the 'grades' table
  Future<void> _saveGrades(Map<String, dynamic> row) async {
    final activeGrade = row['active_grade'];
    final studyLoadId = row['id'];

    // Transmute for DB storage (Numeric(3,2) only allows values < 10)
    double transmutedScale = _transmuteToScale(row['weighted_raw_avg']);

    try {
      await _service.client.from('grades').upsert({
        if (activeGrade['id'] != null) 'id': activeGrade['id'],
        'study_load_id': studyLoadId,
        'midterm_grade': activeGrade['midterm_grade'].toString(),
        'final_grade':
            activeGrade['final_grade'].toString(), // Stores raw final input
        'final_numeric_grade': transmutedScale, // Stores the 1.0-5.0 scale
        'graded_by': widget.userData['id'],
        'status': 'Encoded',
      });

      _showToast(
          "Grades for ${row['profiles']['fn']} saved to Grade Book.", success);
      _loadRoster();
    } catch (e) {
      debugPrint("Save Error: $e");
      _showToast("Sync Error: Check Input Values.", Colors.redAccent);
    }
  }

  /// 📐 LOGIC: Weighted Raw Average (e.g., 90.0)
  double _calculateWeightedRaw(dynamic rawMidterm, dynamic rawFinal) {
    double m = double.tryParse(rawMidterm.toString()) ?? 0.0;
    double f = double.tryParse(rawFinal.toString()) ?? 0.0;
    if (m == 0 && f == 0) return 0.0;
    return (m * 0.4) + (f * 0.6);
  }

  /// 📐 LOGIC: Transmutation to 1.00-5.00 Scale with 95 Ceiling
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
        Text(
          "Faculty Grade Encoding",
          style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: text,
              letterSpacing: -1),
        ),
        const Text(
          "Ceiling: 95.0. Numeric GWA reflects weighted raw scores.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color bg, Color text) {
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
          _buildDropdown(
              "Teaching Assignments", _selectedSubjectId, _mySubjects, (v) {
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
          _exportBtn(
              LucideIcons.fileText, "PDF REPORT", _generateGradePDF, aViolet),
        ],
      ),
    );
  }

  Widget _buildEncodingModule(Color bg, Color text) {
    final filteredRoster = _roster.where((s) {
      final name =
          "${s['profiles']['fn']} ${s['profiles']['ln']}".toLowerCase();
      final id = s['profiles']['user_id_number'].toString();
      final query = _searchController.text.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: text, fontSize: 14),
            decoration: const InputDecoration(
              hintText: "Search class roster...",
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
              const SizedBox(height: 24),
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
          _tableHead("RAW MIDTERM", 2),
          _tableHead("RAW FINAL", 2),
          _tableHead("NUMERIC GWA", 2),
          _tableHead("TRANSMUTED", 2),
          const SizedBox(width: 40),
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
              child: Text("${profile['fn']} ${profile['ln']}",
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.bold, fontSize: 14))),

          Expanded(flex: 2, child: _gradeInput(s, 'midterm_grade')),
          Expanded(flex: 2, child: _gradeInput(s, 'final_grade')),

          // Show Weighted Raw Average (e.g., 90.0)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(rawAvg == 0 ? "0.0" : rawAvg.toStringAsFixed(1),
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),

          // Show Transmuted Scale (e.g., 1.25)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                    transmuted == 0 ? "N/A" : transmuted.toStringAsFixed(2),
                    style: const TextStyle(
                        color: success, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.save, size: 18, color: aViolet),
            onPressed: () => _saveGrades(s),
          ),
        ],
      ),
    );
  }

  Widget _gradeInput(Map<String, dynamic> s, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(
            color: widget.isDarkMode ? Colors.white : pViolet,
            fontSize: 13,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: (s['active_grade'][field] ?? "0").toString(),
          hintStyle: const TextStyle(color: Colors.blueGrey),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          setState(() {
            s['active_grade'][field] = v;

            // Recalculate the weighted raw average based on percentage inputs
            s['weighted_raw_avg'] = _calculateWeightedRaw(
                s['active_grade']['midterm_grade'],
                s['active_grade']['final_grade']);
          });
        },
      ),
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
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
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
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildEmptyState(Color t) => Center(
      child: Padding(
          padding: const EdgeInsets.all(80),
          child: Column(
            children: [
              Icon(LucideIcons.users, size: 48, color: t.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text("No students found in this roster.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.withOpacity(0.2))),
            ],
          )));

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));

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
                  pw.Text("OFFICIAL GRADE BOOK REPORT",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.SizedBox(height: 8),
                  pw.Text("Subject: $_selectedSubjectName"),
                  pw.Text("Institutional Ceiling: 95.0"),
                  pw.Text("Generated on: ${DateTime.now()}"),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: [
                      "Student Name",
                      "Raw Midterm",
                      "Raw Final",
                      "Weighted Avg",
                      "Transmuted"
                    ],
                    data: _roster.map((s) {
                      final p = s['profiles'];
                      final double rAvg = s['weighted_raw_avg'] ?? 0.0;
                      return [
                        "${p['ln']}, ${p['fn']}",
                        s['active_grade']['midterm_grade'] ?? "0",
                        s['active_grade']['final_grade'] ?? "0",
                        rAvg.toStringAsFixed(1),
                        _transmuteToScale(rAvg).toStringAsFixed(2)
                      ];
                    }).toList(),
                  ),
                ],
              ),
            )));

    final dir = await getTemporaryDirectory();
    final file =
        File("${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
