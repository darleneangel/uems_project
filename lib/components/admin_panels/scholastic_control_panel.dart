import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class ScholasticControlPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ScholasticControlPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<ScholasticControlPanel> createState() => _ScholasticControlPanelState();
}

class _ScholasticControlPanelState extends State<ScholasticControlPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _periods = [];
  Map<String, dynamic>? _activeTerm;

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _fetchScholasticContext();
  }

  /// 🛰️ DATABASE: Resolves the active term and associated grading windows
  Future<void> _fetchScholasticContext() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Identify the currently active academic period
      final termRes = await _service.client
          .from('academic_terms')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (termRes != null) {
        _activeTerm = termRes;
        // 2. Fetch associated grading periods
        final periodRes = await _service.client
            .from('grading_periods')
            .select('*')
            .eq('term_id', termRes['id'])
            .order('encoding_start', ascending: true);

        _periods = List<Map<String, dynamic>>.from(periodRes);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _showToast("Scholastic Sync Error: Check ledger connectivity.",
          Colors.redAccent);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Updates a specific grading period configuration
  Future<void> _updatePeriod(String id, Map<String, dynamic> updates) async {
    setState(() => _isSaving = true);
    try {
      await _service.client
          .from('grading_periods')
          .update(updates)
          .eq('id', id);

      await _fetchScholasticContext();
      _showToast("Institutional Schedule Updated", success);
    } catch (e) {
      _showToast("Ledger Update Rejected", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          if (_activeTerm == null)
            _buildNoActiveTermState(textColor)
          else ...[
            _buildTermBanner(textColor),
            const SizedBox(height: 32),
            Text("GRADE ENCODING LIFECYCLE",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: aViolet,
                    letterSpacing: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: _periods
                  .map((p) => _buildPeriodCard(p, cardColor, textColor))
                  .toList(),
            ),
            const SizedBox(height: 48),
            _buildGradingRulesModule(cardColor, textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Scholastic Control Center",
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900, color: t)),
          const Text(
              "Govern grade encoding windows, lock institutional records, and set curriculum standards.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      );

  Widget _buildTermBanner(Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
          color: aViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: aViolet.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(LucideIcons.calendarCheck, color: aViolet, size: 20),
          const SizedBox(width: 16),
          Text("ACTIVE CONTEXT:",
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w900, color: aViolet)),
          const SizedBox(width: 8),
          Text(
              "${_activeTerm!['year_label']} • ${_activeTerm!['semester_label']}"
                  .toUpperCase(),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 13, color: text)),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> period, Color bg, Color text) {
    final bool isLocked = period['is_hard_locked'] ?? false;
    final String start = period['encoding_start'] != null
        ? DateFormat('MMM dd').format(DateTime.parse(period['encoding_start']))
        : "TBA";
    final String end = period['encoding_deadline'] != null
        ? DateFormat('MMM dd')
            .format(DateTime.parse(period['encoding_deadline']))
        : "TBA";

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: !isLocked ? success.withOpacity(0.3) : Colors.white10),
        ),
        child: Column(
          children: [
            Text(period['period_name'].toString().toUpperCase(),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: !isLocked ? success : Colors.blueGrey,
                    fontSize: 12,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            Text("$start — $end",
                style: GoogleFonts.inter(
                    fontSize: 13, color: text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _statusChip(!isLocked ? "OPEN" : "LOCKED",
                !isLocked ? success : Colors.redAccent),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.calendar,
                      size: 18, color: aViolet),
                  onPressed: () => _pickEncodingWindow(period),
                  tooltip: "Set Dates",
                ),
                const SizedBox(width: 8),
                Switch(
                  value: !isLocked,
                  activeThumbColor: success,
                  onChanged: (v) =>
                      _updatePeriod(period['id'], {'is_hard_locked': !v}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingRulesModule(Color bg, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.settings2, color: aViolet, size: 20),
              const SizedBox(width: 12),
              Text("Institutional Grading Rules",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 18, color: text)),
            ],
          ),
          const SizedBox(height: 24),
          _ruleTile(
              "Grade Normalization",
              "Automatically convert percentage scores to 1.0 - 5.0 scale.",
              true),
          _ruleTile("Minimum Passing Mark",
              "Current standard: 75.0% (3.0 numeric).", true),
          _ruleTile(
              "Late Submission Penalty",
              "Apply 5% reduction per day for unauthorized late encoding.",
              false),
        ],
      ),
    );
  }

  Widget _ruleTile(String t, String s, bool val) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(s,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        trailing: Switch(value: val, activeThumbColor: aViolet, onChanged: (v) {}),
      );

  void _pickEncodingWindow(Map<String, dynamic> period) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: widget.isDarkMode
            ? ThemeData.dark()
                .copyWith(colorScheme: const ColorScheme.dark(primary: aViolet))
            : ThemeData.light(),
        child: child!,
      ),
    );

    if (picked != null) {
      _updatePeriod(period['id'], {
        'encoding_start': picked.start.toIso8601String(),
        'encoding_deadline': picked.end.toIso8601String(),
      });
    }
  }

  Widget _buildNoActiveTermState(Color text) => Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(LucideIcons.calendarX, size: 64, color: text.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text("No Active Term Detected",
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
            const Text(
                "Activate a semester in the Academic Lifecycle panel to manage grading.",
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );

  Widget _statusChip(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w900)));

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
