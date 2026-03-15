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

  @override
  void initState() {
    super.initState();
    _loadTeacherLoad();
  }

  /// 🛰️ DATABASE: Load all unique subjects assigned to this professor
  Future<void> _loadTeacherLoad() async {
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
      debugPrint("Load Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Fetch students enrolled in the selected subject
  Future<void> _loadRoster() async {
    if (_selectedSubjectId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('study_loads')
          .select('''
            id, 
            assignment_grade, 
            exam_grade, 
            project_grade, 
            final_grade,
            profiles!study_loads_student_id_fkey(id, fn, ln, user_id_number)
          ''')
          .eq('professor_id', widget.userData['id'])
          .eq('subject_id', _selectedSubjectId!);

      if (mounted) {
        setState(() {
          _roster = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Roster Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Update specific student grades
  Future<void> _saveGrades(Map<String, dynamic> row) async {
    try {
      await _service.client.from('study_loads').update({
        'assignment_grade': row['assignment_grade'],
        'exam_grade': row['exam_grade'],
        'project_grade': row['project_grade'],
        'final_grade': row['final_grade'],
      }).eq('id', row['id']);

      _showToast(
          "Grades for ${row['profiles']['fn']} updated successfully.", success);
    } catch (e) {
      _showToast("Update Failed: $e", Colors.redAccent);
    }
  }

  /// 📐 LOGIC: Weighted Grade Calculation (30/40/30)
  String _calculateFinal(dynamic a, dynamic e, dynamic p) {
    double assign = double.tryParse(a.toString()) ?? 0.0;
    double exam = double.tryParse(e.toString()) ?? 0.0;
    double proj = double.tryParse(p.toString()) ?? 0.0;

    double average = (assign * 0.3) + (exam * 0.4) + (proj * 0.3);

    // SSC-R Cavite Grade Mapping Simulation
    if (average >= 95) return "1.00";
    if (average >= 90) return "1.25";
    if (average >= 85) return "1.50";
    if (average >= 80) return "1.75";
    if (average >= 75) return "2.00";
    if (average >= 70) return "2.50";
    if (average >= 60) return "3.00";
    return "5.00";
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
          "Synchronized academic outcomes. Updates here reflect instantly on the student's portal.",
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
              "Current Teaching Load", _selectedSubjectId, _mySubjects, (v) {
            setState(() => _selectedSubjectId = v);
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
          _tableHead("ASGN (30%)", 2),
          _tableHead("EXAM (40%)", 2),
          _tableHead("PROJ (30%)", 2),
          _tableHead("FINAL", 2),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> s, Color text) {
    final profile = s['profiles'];
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
          Expanded(flex: 2, child: _gradeInput(s, 'assignment_grade')),
          Expanded(flex: 2, child: _gradeInput(s, 'exam_grade')),
          Expanded(flex: 2, child: _gradeInput(s, 'project_grade')),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text(s['final_grade'] ?? "0.00",
                      style: const TextStyle(
                          color: success, fontWeight: FontWeight.w900))),
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
          hintText: (s[field] ?? "0").toString(),
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
            s[field] = double.tryParse(v) ?? 0.0;
            s['final_grade'] = _calculateFinal(
                s['assignment_grade'], s['exam_grade'], s['project_grade']);
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
                      child: Text("${i['code']} - ${i['name']}")))
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(Color t) => Center(
      child: Padding(
          padding: const EdgeInsets.all(80),
          child: Text("No students currently enrolled in this subject roster.",
              style: TextStyle(color: t.withOpacity(0.2)))));

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));

  Future<void> _generateGradePDF() async {
    if (_roster.isEmpty) return;
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (c) => pw.Center(
            child: pw.Text(
                "Official Roster Grade Report: $_selectedSubjectName"))));
    final dir = await getTemporaryDirectory();
    final file =
        File("${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
