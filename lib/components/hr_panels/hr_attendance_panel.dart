import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class HRAttendancePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HRAttendancePanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<HRAttendancePanel> createState() => _HRAttendancePanelState();
}

class _HRAttendancePanelState extends State<HRAttendancePanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _cachedLogs = [];
  bool _isLoading = true;
  bool _showArchives = false; // Toggle for Today vs Historical Data

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchStaticData();
  }

  /// Initial fetch and manual refresh handler
  Future<void> _fetchStaticData() async {
    setState(() => _isLoading = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      var query = _service.client
          .from('attendance_logs')
          .select('*, profiles(fn, ln, user_id_number, role)');

      if (_showArchives) {
        query = query.lt('log_date', today); // Fetch everything before today
      } else {
        query = query.eq('log_date', today); // Fetch only today
      }

      final res = await query.order('check_in', ascending: false);
      _cachedLogs = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // --- HEADER SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showArchives ? "Attendance Archives" : "Daily Attendance",
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5),
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.database,
                          size: 12, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        _showArchives
                            ? "HISTORICAL LOGS"
                            : "LIVE DATABASE SYNC ACTIVE",
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _filterChip("Today", !_showArchives, () {
                    setState(() => _showArchives = false);
                    _fetchStaticData();
                  }),
                  _filterChip("Archives", _showArchives, () {
                    setState(() => _showArchives = true);
                    _fetchStaticData();
                  }),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _fetchStaticData,
                    icon: const Icon(LucideIcons.refreshCw,
                        size: 20, color: aViolet),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),

          // --- SEARCH BAR ---
          _buildSearchBar(cardColor, textColor),
          const SizedBox(height: 24),

          // --- CONTENT AREA ---
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: widget.isDarkMode
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
              ),
              child: _buildAttendanceList(textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(Color textColor) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: [
        _tableHeader(
            ['DATE', 'EMPLOYEE', 'USER ID', 'TIME IN', 'TIME OUT', 'STATUS']),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            // Stream logic: Archives use static fetch, Today uses real-time stream
            stream: _showArchives
                ? Stream.value(_cachedLogs)
                : _service.client
                    .from('attendance_logs')
                    .stream(primaryKey: ['id'])
                    .eq('log_date', today)
                    .order('check_in', ascending: false),
            builder: (context, snapshot) {
              final List<Map<String, dynamic>> logs =
                  (snapshot.hasData) ? snapshot.data! : _cachedLogs;

              if (logs.isEmpty && _isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: aViolet));
              }

              if (logs.isEmpty) {
                return _emptyState(_showArchives
                    ? "No historical records found."
                    : "No attendance logs recorded for today.");
              }

              return ListView.separated(
                itemCount: logs.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, i) {
                  final log = logs[i];

                  // Use FutureBuilder to resolve Profile if it's missing (usually in real-time streams)
                  return FutureBuilder<Map<String, dynamic>?>(
                    future:
                        log.containsKey('profiles') && log['profiles'] != null
                            ? Future.value(log['profiles'])
                            : _service.client
                                .from('profiles')
                                .select('fn, ln, user_id_number')
                                .eq('id', log['employee_id'])
                                .maybeSingle(),
                    builder: (context, profSnap) {
                      final profile = profSnap.data;
                      if (profile == null) {
                        return const SizedBox(
                            height: 60,
                            child: Center(child: LinearProgressIndicator()));
                      }

                      final name =
                          "${profile['fn']} ${profile['ln']}".toLowerCase();
                      if (_searchController.text.isNotEmpty &&
                          !name
                              .contains(_searchController.text.toLowerCase())) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(_formatDate(log['log_date']),
                                    style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text("${profile['fn']} ${profile['ln']}",
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))),
                            Expanded(
                                child: Text(profile['user_id_number'] ?? 'N/A',
                                    style: GoogleFonts.inter(
                                        color: Colors.blueGrey, fontSize: 12))),
                            Expanded(
                                child: Text(_formatTime(log['check_in']),
                                    style: GoogleFonts.inter(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                              child: log['check_out'] != null
                                  ? Text(_formatTime(log['check_out']),
                                      style: GoogleFonts.inter(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold))
                                  : TextButton(
                                      onPressed: () =>
                                          _manualLogout(log['employee_id']),
                                      child: const Text("CLOCK OUT",
                                          style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                            ),
                            Expanded(
                                child: _statusChip(log['status'] ?? 'Present')),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _tableHeader(List<String> titles) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF8FAFC),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Row(
            children: titles
                .map((t) => Expanded(
                    flex: t == 'EMPLOYEE' ? 2 : 1,
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey,
                            letterSpacing: 1.2))))
                .toList()),
      );

  Widget _buildSearchBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05))),
        child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: text),
            decoration: const InputDecoration(
                hintText: "Search employee logs...",
                border: InputBorder.none,
                prefixIcon: Icon(LucideIcons.search,
                    size: 18, color: Colors.blueGrey))),
      );

  Widget _filterChip(String l, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: active ? aViolet : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: active ? Colors.transparent : Colors.white10)),
            child: Text(l,
                style: TextStyle(
                    color: active ? Colors.white : Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w800))),
      );

  Widget _statusChip(String status) {
    Color color = status == 'Present' ? success : Colors.orangeAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 9, fontWeight: FontWeight.w900)));
  }

  Widget _emptyState(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock,
                size: 48, color: Colors.blueGrey.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(msg,
                style: const TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  // --- HELPERS ---

  Future<void> _manualLogout(String profileId) async {
    await _service.recordAttendanceLogout(profileId);
    _fetchStaticData();
  }

  String _formatDate(dynamic date) {
    if (date == null) return "--";
    return DateFormat('MMM dd, yyyy').format(DateTime.parse(date.toString()));
  }

  String _formatTime(dynamic iso) {
    if (iso == null) return '--:--';
    return DateFormat('hh:mm a')
        .format(DateTime.parse(iso.toString()).toLocal());
  }
}
