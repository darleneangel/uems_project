import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class GradeBookPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const GradeBookPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<GradeBookPanel> createState() => _GradeBookPanelState();
}

class _GradeBookPanelState extends State<GradeBookPanel> {
  String? _selectedSemester;
  List<String> _semesters = [];
  List<Map<String, dynamic>> _allGrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveGrades();
  }

  /// 🛰️ DATABASE ENGINE: Fetches grades with joined subject and semester data
  Future<void> _fetchLiveGrades() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final client = SupabaseService().client;

    try {
      // JOINED QUERY: Accessing nested descriptions via null-safe aliases
      final response = await client.from('grades').select('''
            midterm_grade,
            final_grade,
            final_numeric_grade,
            status,
            study_loads!inner (
              student_id,
              section_block,
              subjects (code, name, units),
              semesters (description),
              academic_years (description)
            )
          ''').eq('study_loads.student_id', widget.studentData['id']);

      if (mounted) {
        final List<Map<String, dynamic>> fetched =
            List<Map<String, dynamic>>.from(response);

        final Set<String> semesterSet = {};
        for (var row in fetched) {
          // FIX: Added null-aware access to prevent "[] called on null" error
          final loads = row['study_loads'] as Map?;
          final semDesc =
              loads?['semesters']?['description'] ?? "Unknown Semester";
          final yearDesc = loads?['academic_years']?['description'] ?? "N/A";
          semesterSet.add("$semDesc $yearDesc");
        }

        setState(() {
          _allGrades = fetched;
          _semesters = semesterSet.toList()..sort((a, b) => b.compareTo(a));
          if (_semesters.isNotEmpty) {
            _selectedSemester = _semesters.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Grade Book Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredGrades() {
    if (_selectedSemester == null) return [];
    return _allGrades.where((g) {
      final loads = g['study_loads'] as Map?;
      final sem = loads?['semesters']?['description'] ?? "Unknown Semester";
      final year = loads?['academic_years']?['description'] ?? "N/A";
      return "$sem $year" == _selectedSemester;
    }).toList();
  }

  double _calculateTermGWA(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalUnits = 0;

    for (var g in grades) {
      final double numericGrade =
          double.tryParse(g['final_numeric_grade']?.toString() ?? "0.0") ?? 0.0;
      final double units = double.tryParse(
              g['study_loads']?['subjects']?['units']?.toString() ?? "0.0") ??
          0.0;

      if (numericGrade > 0) {
        totalPoints += numericGrade * units;
        totalUnits += units;
      }
    }
    return totalUnits == 0 ? 0.0 : totalPoints / totalUnits;
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    final filtered = _getFilteredGrades();
    final gwa = _calculateTermGWA(filtered);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_semesters.isNotEmpty) ...[
            _buildSemesterSelector(cardColor, textColor),
            const SizedBox(height: 24),
            _buildSummaryCard(
                cardColor, textColor, subTextColor, gwa, filtered.length),
            const SizedBox(height: 24),
            _buildGradeTable(filtered, cardColor, textColor, subTextColor),
          ] else
            _buildEmptyState(subTextColor),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSemester,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: Icon(LucideIcons.chevronDown, color: textColor),
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: (v) => setState(() => _selectedSemester = v),
          items: _semesters
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Color cardColor, Color textColor, Color subTextColor,
      double gwa, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Institutional GWA",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(gwa == 0 ? "N/A" : gwa.toStringAsFixed(2),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            if (gwa <= 1.75 && gwa > 0)
              Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("SCHOLASTIC HONOR",
                      style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text("Total Units",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("$count Subjects",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("VERIFIED RECORD",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1)),
          ]),
        ],
      ),
    );
  }

  Widget _buildGradeTable(List<Map<String, dynamic>> grades, Color cardColor,
      Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(0.8),
          3: FlexColumnWidth(0.8),
          4: FlexColumnWidth(1.2)
        },
        children: [
          TableRow(children: [
            _header("Code", subTextColor),
            _header("Subject", subTextColor),
            _header("MIDTERM", subTextColor, center: true),
            _header("FINAL", subTextColor, center: true),
            _header("GWA", subTextColor, center: true),
          ]),
          ...grades.map((g) {
            final sub = g['study_loads']['subjects'];
            final numericGwa = double.tryParse(
                    g['final_numeric_grade']?.toString() ?? "0.0") ??
                0.0;
            return TableRow(children: [
              _cell(sub['code'], const Color(0xFF8B5CF6), bold: true),
              _cell(sub['name'], textColor),
              _cell(g['midterm_grade'] ?? '-', textColor, center: true),
              _cell(g['final_grade'] ?? '-', textColor, center: true),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: _gwaBadge(numericGwa))),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _header(String t, Color c, {bool center = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(t.toUpperCase(),
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.inter(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)));
  Widget _cell(String t, Color c, {bool bold = false, bool center = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(t,
              textAlign: center ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.inter(
                  color: c,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)));

  Widget _gwaBadge(double gwa) {
    if (gwa == 0) {
      return const Text("-", style: TextStyle(color: Colors.blueGrey));
    }
    final color = gwa <= 3.0 ? const Color(0xFF69F0AE) : Colors.redAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Text(gwa.toStringAsFixed(2),
            style: GoogleFonts.inter(
                color: color, fontSize: 11, fontWeight: FontWeight.w900)));
  }

  Widget _buildEmptyState(Color sub) => Center(
      child: Padding(
          padding: const EdgeInsets.all(100),
          child: Column(children: [
            Icon(LucideIcons.bookOpen, size: 48, color: sub.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("No academic history found.", style: TextStyle(color: sub))
          ])));
}
