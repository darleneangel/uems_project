import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class RegistrarOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const RegistrarOverviewPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<RegistrarOverviewPanel> createState() => _RegistrarOverviewPanelState();
}

class _RegistrarOverviewPanelState extends State<RegistrarOverviewPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;

  // Intelligence State (Live Database Sync)
  List<Map<String, dynamic>> _recentStudents = [];
  Map<String, int> _courseDistribution = {};
  Map<String, int> _yearLevelDistribution = {};

  int _totalActive = 0;
  int _pendingRequests = 0;
  int _intakePipeline = 0;
  int _totalStudentRecords = 0;

  // Interaction States
  String? _hoveredBar;

  // Standardized Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _loadRegistrarIntelligence();
  }

  /// 🛰️ DATABASE: Aggregate institutional records with specific Year Level mapping
  Future<void> _loadRegistrarIntelligence() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Student Profiles with Deep Joins
      // Join logic: student_details -> courses AND student_details -> year_levels
      final studentRes = await _service.client
          .from('profiles')
          .select('*, student_details(*, courses(name, code), year_levels(*))')
          .eq('role', 'student');

      final List<Map<String, dynamic>> students =
          List<Map<String, dynamic>>.from(studentRes);

      // 2. Fetch Contextual Counters for the Stat Grid
      final requestRes = await _service.client
          .from('office_requests')
          .select('id')
          .eq('status', 'Pending');
      final intakeRes = await _service.client
          .from('applicants')
          .select('id')
          .eq('status', 'Pending');

      // 3. Multi-Dimensional Analytical Processing
      Map<String, int> courseMap = {};
      Map<String, int> yearMap = {};
      int activeCount = 0;

      for (var s in students) {
        final details = s['student_details'];
        if (details == null) continue;

        // Enrollment Calculation
        if (details['enrollment_status'] == 'Enrolled' ||
            details['enrollment_status'] == 'Cleared') {
          activeCount++;
        }

        // Program Population Tally
        String courseCode = details['courses']?['code'] ?? 'N/A';
        courseMap[courseCode] = (courseMap[courseCode] ?? 0) + 1;

        // 🎯 YEAR LEVEL TALLY: Resolved via the 'definition' column in your schema
        final dynamic yearDataRaw = details['year_levels'];
        Map<String, dynamic>? yearData;

        if (yearDataRaw is List && yearDataRaw.isNotEmpty) {
          yearData = yearDataRaw.first;
        } else if (yearDataRaw is Map<String, dynamic>) {
          yearData = yearDataRaw;
        }

        // Using 'definition' as per your public.year_levels schema
        String yearLabel = yearData?['definition'] ?? 'Unassigned';
        yearMap[yearLabel] = (yearMap[yearLabel] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _recentStudents = students.take(8).toList();
          _courseDistribution = courseMap;
          _yearLevelDistribution = yearMap;
          _totalActive = activeCount;
          _totalStudentRecords = students.length;
          _pendingRequests = requestRes.length;
          _intakePipeline = intakeRes.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Registrar Intelligence Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildStatGrid(textColor),
          const SizedBox(height: 32),

          // INTELLIGENCE ROW: Focus on Program Distribution & Year Balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 3,
                  child: _buildChartContainer("Program Population",
                      _buildBarChart(textColor), cardColor, textColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 2,
                  child: _buildChartContainer("Year Level Breakdown",
                      _buildYearAnalytics(textColor), cardColor, textColor)),
            ],
          ),

          const SizedBox(height: 32),
          _buildActivityFeed(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
      String title, Widget child, Color cardBg, Color textColor) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart3, color: aViolet, size: 18),
              const SizedBox(width: 12),
              Text(title.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      fontSize: 11,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(Color textColor) {
    if (_courseDistribution.isEmpty) {
      return const Center(
          child: Text("No enrollment data available.",
              style: TextStyle(color: Colors.blueGrey)));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _courseDistribution.entries.map((e) {
        double max = _courseDistribution.values.reduce(math.max).toDouble();
        double height = (e.value / max) * 200;
        bool isHovered = _hoveredBar == e.key;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Tooltip(
              message: "${e.key}: ${e.value} Enrolled Students",
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredBar = e.key),
                onExit: (_) => setState(() => _hoveredBar = null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 45,
                  height: height.clamp(15, 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: isHovered
                            ? [success, aViolet]
                            : [aViolet, aViolet.withOpacity(0.4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      if (isHovered)
                        BoxShadow(
                            color: aViolet.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2)
                    ],
                  ),
                  child: Center(
                      child: Text(e.value.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(e.key,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildYearAnalytics(Color textColor) {
    if (_yearLevelDistribution.isEmpty) {
      return const Center(
          child: Text("No records found.",
              style: TextStyle(color: Colors.blueGrey)));
    }

    // Sort year levels chronologically for logical UI flow
    final sortedEntries = _yearLevelDistribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: sortedEntries.map((e) {
        double percent =
            _totalStudentRecords == 0 ? 0 : e.value / _totalStudentRecords;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  Text("${(percent * 100).toInt()}%",
                      style: TextStyle(
                          fontSize: 11,
                          color: textColor,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: aViolet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 8,
                    width: percent * 200,
                    decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(colors: [aViolet, success]),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("${e.value} Total Records",
                  style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatGrid(Color textColor) {
    return Row(
      children: [
        _kpiCard("Live Enrollment", _totalActive.toDouble(),
            LucideIcons.userCheck, success,
            isInt: true),
        const SizedBox(width: 20),
        _kpiCard("Pending Load", _pendingRequests.toDouble(),
            LucideIcons.fileText, Colors.orangeAccent,
            isInt: true),
        const SizedBox(width: 20),
        _kpiCard("Intake Queue", _intakePipeline.toDouble(),
            LucideIcons.userPlus, aViolet,
            isInt: true),
        const SizedBox(width: 20),
        _kpiCard("Vault Records", _totalStudentRecords.toDouble(),
            LucideIcons.database, Colors.blueAccent,
            isInt: true),
      ],
    );
  }

  Widget _kpiCard(String label, double val, IconData icon, Color color,
      {bool isInt = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 20),
            Text(isInt ? val.toInt().toString() : val.toString(),
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: widget.isDarkMode ? Colors.white : pViolet)),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Registrar Intelligence Overview",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5)),
            const Text(
                "Institutional population balance and program distribution analytics.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _loadRegistrarIntelligence,
          icon: Icon(LucideIcons.refreshCw, 
              color: widget.isDarkMode ? Colors.white : Colors.white, size: 16),
          label: Text("SYNC LEDGER",
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
        )
      ],
    );
  }

  Widget _buildActivityFeed(Color cardBg, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, color: aViolet, size: 18),
                  const SizedBox(width: 12),
                  Text("Recent Ledger Interactions",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: textColor)),
                ],
              )),
          const Divider(height: 1, color: Colors.white10),
          _recentStudents.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: Text("Ledger currently idle.",
                          style: TextStyle(color: Colors.blueGrey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentStudents.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final s = _recentStudents[i];
                    final details = s['student_details'];

                    // Resolution for the 'definition' field in Year Levels
                    final dynamic yearDataRaw = details?['year_levels'];
                    Map<String, dynamic>? yearData;
                    if (yearDataRaw is List && yearDataRaw.isNotEmpty) {
                      yearData = yearDataRaw.first;
                    } else if (yearDataRaw is Map<String, dynamic>) {
                      yearData = yearDataRaw;
                    }
                    String yearLabel = yearData?['definition'] ?? '1st Year';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      leading: CircleAvatar(
                          backgroundColor: aViolet.withOpacity(0.1),
                          child: Text(s['ln']?[0] ?? 'S',
                              style: const TextStyle(
                                  color: aViolet,
                                  fontWeight: FontWeight.bold))),
                      title: Text("${s['ln']}, ${s['fn']}".toUpperCase(),
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      subtitle: Text(
                          "${s['user_id_number']} • $yearLabel • ${details?['courses']?['name'] ?? 'College'}",
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 11)),
                      trailing: _statusBadge(
                          details?['enrollment_status'] ?? 'Enrolled'),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color c =
        (s == "Cleared" || s == "Enrolled") ? success : Colors.orangeAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(s.toUpperCase(),
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));
  }
}
