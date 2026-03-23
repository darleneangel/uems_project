import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class AdmissionOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AdmissionOverviewPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<AdmissionOverviewPanel> createState() => _AdmissionOverviewPanelState();
}

class _AdmissionOverviewPanelState extends State<AdmissionOverviewPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;

  // Data States
  List<Map<String, dynamic>> _allApplicants = [];
  Map<String, int> _statusCounts = {};
  Map<String, int> _courseDistribution = {};
  List<Map<String, dynamic>> _monthlyTrends = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _loadIntelligenceData();
  }

  /// 🛰️ DATABASE: Aggregate all admission data for analytics
  Future<void> _loadIntelligenceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch all records for comprehensive analysis
      final response = await _service.client
          .from('applicants')
          .select('*, courses(code, name)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> applicants =
          List<Map<String, dynamic>>.from(response);
      final now = DateTime.now();

      // 2. Process Analytics in Memory (Faster than multiple SQL Count queries)
      Map<String, int> statusTmp = {
        'Pending': 0,
        'Verified': 0,
        'Admitted': 0,
        'Archived': 0
      };
      Map<String, int> courseTmp = {};
      Map<String, double> trendTmp = {};

      for (var app in applicants) {
        final createdAt = DateTime.tryParse(app['created_at'] ?? '') ?? now;
        final int ageInDays = now.difference(createdAt).inDays;
        final String status = app['status'] ?? 'Pending';
        final String courseCode = app['courses']?['code'] ?? 'GEN';

        // Archival logic
        if (ageInDays > 30) {
          statusTmp['Archived'] = (statusTmp['Archived'] ?? 0) + 1;
        } else {
          statusTmp[status] = (statusTmp[status] ?? 0) + 1;
        }

        // Course distribution
        courseTmp[courseCode] = (courseTmp[courseCode] ?? 0) + 1;

        // Monthly trends
        String month = DateFormat('MMM').format(createdAt);
        trendTmp[month] = (trendTmp[month] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _allApplicants = applicants;
          _statusCounts = statusTmp;
          _courseDistribution = courseTmp;
          _monthlyTrends = trendTmp.entries
              .map((e) => {'month': e.key, 'count': e.value})
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Analytics Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildStatGrid(textColor),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 3, child: _buildIntakeTrendGraph(cardColor, textColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 2, child: _buildCourseHeatmap(cardColor, textColor)),
            ],
          ),
          const SizedBox(height: 32),
          _buildActivityFeed(cardColor, textColor),
        ],
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
            Text("Admission Intelligence",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5)),
            const Text(
                "Real-time demographic tracking and intake volume analysis.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
        IconButton(
          onPressed: _loadIntelligenceData,
          icon: const Icon(LucideIcons.refreshCw, color: aViolet),
          tooltip: "Sync Analytics",
        )
      ],
    );
  }

  Widget _buildStatGrid(Color textColor) {
    return Row(
      children: [
        _statCard("Total Applicants", _allApplicants.length.toDouble(),
            LucideIcons.users, aViolet,
            isInt: true),
        const SizedBox(width: 20),
        _statCard("Pending Review", (_statusCounts['Pending'] ?? 0).toDouble(),
            LucideIcons.clock, Colors.orangeAccent,
            isInt: true),
        const SizedBox(width: 20),
        _statCard(
            "Institutional Admitted",
            (_statusCounts['Admitted'] ?? 0).toDouble(),
            LucideIcons.shieldCheck,
            success,
            isInt: true),
        const SizedBox(width: 20),
        _statCard("Archived Logs", (_statusCounts['Archived'] ?? 0).toDouble(),
            LucideIcons.archive, Colors.blueGrey,
            isInt: true),
      ],
    );
  }

  Widget _statCard(String label, double val, IconData icon, Color color,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(
              isInt ? val.toInt().toString() : val.toString(),
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeTrendGraph(Color cardColor, Color textColor) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Monthly Intake Volume",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 40),
          Expanded(
            child: _monthlyTrends.isEmpty
                ? const Center(
                    child: Text("Waiting for historical data...",
                        style: TextStyle(color: Colors.blueGrey)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _monthlyTrends.map((data) {
                      double max = _monthlyTrends
                          .map((e) => e['count'] as double)
                          .reduce((a, b) => a > b ? a : b);
                      double heightFactor =
                          (data['count'] / max).clamp(0.1, 1.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 45,
                            height: 180 * heightFactor,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [aViolet, Color(0xFFC084FC)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(data['count'].toInt().toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(height: 12),
                          Text(data['month'],
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeatmap(Color cardColor, Color textColor) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Program Distribution",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: _courseDistribution.entries.map((e) {
                double percent = e.value / _allApplicants.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          Text("${(percent * 100).toInt()}%",
                              style: TextStyle(
                                  fontSize: 10, 
                                  color: widget.isDarkMode ? Colors.white70 : Colors.blueGrey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.blueGrey.withOpacity(0.1),
                        color: aViolet,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(Color cardColor, Color textColor) {
    final recent = _allApplicants.take(10).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Recent Institutional Activity",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, color: textColor)),
          ),
          const Divider(height: 1, color: Colors.white10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final app = recent[i];
              // Normalized Identity Extraction
              final name =
                  "${app['ln'] ?? 'TBA'}, ${app['fn'] ?? ''}".toUpperCase();
              final status = app['status'] ?? "Pending";

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: aViolet.withOpacity(0.1),
                  child: Text(app['ln'] != null ? app['ln'][0] : 'A',
                      style: const TextStyle(
                          color: aViolet, fontWeight: FontWeight.bold)),
                ),
                title: Text(name,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                subtitle: Text(
                    "${app['application_no']} • ${app['courses']?['name'] ?? 'GEN'}",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                trailing: _statusBadge(status),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color c = (s == "Verified" || s == "Admitted")
        ? success
        : (s == "Rejected" ? Colors.redAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}
