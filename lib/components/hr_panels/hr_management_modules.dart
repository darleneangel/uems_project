import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';

class AttendanceLeavePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AttendanceLeavePanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AttendanceLeavePanel> createState() => _AttendanceLeavePanelState();
}

class _AttendanceLeavePanelState extends State<AttendanceLeavePanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _attendanceLogs = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _allEmployees = [];

  bool _isLoading = true;
  int _activeTabIndex = 0;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchStaticData();
  }

  Future<void> _fetchStaticData() async {
    setState(() => _isLoading = true);
    try {
      if (_activeTabIndex == 0) {
        final res = await _service.client
            .from('attendance_logs')
            .select('*, profiles(fn, ln, user_id_number, role)')
            .order('check_in', ascending: false);
        _attendanceLogs = List<Map<String, dynamic>>.from(res);
      } else if (_activeTabIndex == 1) {
        final res = await _service.client
            .from('leave_requests')
            .select(
                '*, profiles!leave_requests_employee_id_fkey(fn, ln, user_id_number)')
            .order('start_date', ascending: false);
        _leaveRequests = List<Map<String, dynamic>>.from(res);
      } else if (_activeTabIndex == 2) {
        final res = await _service.client
            .from('profiles')
            .select('*, employee_details(*)')
            .neq('role', 'student')
            .order('ln', ascending: true);
        _allEmployees = List<Map<String, dynamic>>.from(res);
      }
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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getTitle(),
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5)),
                Row(
                  children: [
                    const Icon(LucideIcons.database,
                        size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text("LIVE DATABASE SYNC ACTIVE",
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _filterChip("Attendance", _activeTabIndex == 0, () {
                  setState(() => _activeTabIndex = 0);
                  _fetchStaticData();
                }),
                _filterChip("Leaves", _activeTabIndex == 1, () {
                  setState(() => _activeTabIndex = 1);
                  _fetchStaticData();
                }),
                _filterChip("Staff Directory", _activeTabIndex == 2, () {
                  setState(() => _activeTabIndex = 2);
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
        _buildSearchBar(cardColor, textColor),
        const SizedBox(height: 24),
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
            child: _buildActiveView(textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView(Color textColor) {
    if (_isLoading && (_activeTabIndex != 0 || _attendanceLogs.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }
    switch (_activeTabIndex) {
      case 0:
        return _buildAttendanceView(textColor);
      case 1:
        return _buildLeaveList(textColor);
      case 2:
        return _buildEmployeeList(textColor);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAttendanceView(Color textColor) {
    return Column(
      children: [
        _tableHeader(['EMPLOYEE', 'USER ID', 'LOG IN', 'LOG OUT', 'STATUS']),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.client
                .from('attendance_logs')
                .stream(primaryKey: ['id']).order('check_in', ascending: false),
            builder: (context, snapshot) {
              final List<Map<String, dynamic>> logs =
                  (snapshot.hasData && snapshot.data!.isNotEmpty)
                      ? snapshot.data!
                      : _attendanceLogs;

              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clock,
                          size: 48, color: Colors.blueGrey.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text("Waiting for first login event...",
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold)),
                      const Text(
                          "Attendance records will appear here as staff log in.",
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: logs.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, i) {
                  final log = logs[i];
                  return FutureBuilder<Map<String, dynamic>?>(
                      future:
                          log.containsKey('profiles') && log['profiles'] != null
                              ? Future.value(log['profiles'])
                              : _service.client
                                  .from('profiles')
                                  .select('fn, ln, user_id_number, role')
                                  .eq('id', log['employee_id'])
                                  .maybeSingle(),
                      builder: (context, profSnap) {
                        final profile = profSnap.data;
                        if (profile == null) {
                          return const SizedBox(
                              height: 60,
                              child: Center(child: LinearProgressIndicator()));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                      "${profile['fn']} ${profile['ln']}",
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13))),
                              Expanded(
                                  child: Text(
                                      profile['user_id_number'] ?? 'N/A',
                                      style: GoogleFonts.inter(
                                          color: Colors.blueGrey,
                                          fontSize: 12))),
                              Expanded(
                                  child: Text(_formatTime(log['check_in']),
                                      style: GoogleFonts.orbitron(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  child: log['check_out'] != null
                                      ? Text(_formatTime(log['check_out']),
                                          style: GoogleFonts.orbitron(
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
                                                  fontWeight:
                                                      FontWeight.bold)))),
                              Expanded(
                                  child:
                                      _statusChip(log['status'] ?? 'Present')),
                            ],
                          ),
                        );
                      });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveList(Color textColor) {
    final list = _leaveRequests;
    return Column(
      children: [
        _tableHeader([
          'EMPLOYEE',
          'TYPE',
          'REASON',
          'PERIOD',
          'DOC',
          'STATUS',
          'ACTIONS'
        ]),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final req = list[i];
              final profile = req['profiles'];

              // Formatting dates for the "Period" column
              final period =
                  "${DateFormat('MM/dd').format(DateTime.parse(req['start_date']))} - ${DateFormat('MM/dd').format(DateTime.parse(req['end_date']))}";

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${profile['fn']} ${profile['ln']}",
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            Text(profile['user_id_number'] ?? 'N/A',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.blueGrey)),
                          ],
                        )),
                    Expanded(
                        child: Text(req['leave_type'],
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: aViolet))),
                    Expanded(
                        flex: 2,
                        child: Text(req['reason'] ?? 'No reason provided',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blueGrey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        child:
                            Text(period, style: const TextStyle(fontSize: 11))),
                    Expanded(
                        child: req['attachment_url'] != null
                            ? IconButton(
                                icon: const Icon(LucideIcons.fileText,
                                    color: Colors.blue, size: 18),
                                onPressed: () =>
                                    _openDocument(req['attachment_url']),
                                tooltip: "View Attached Document",
                              )
                            : const Icon(LucideIcons.fileX,
                                color: Colors.grey, size: 18)),
                    Expanded(child: _statusChip(req['status'])),
                    Expanded(
                        child: req['status'] == 'Pending'
                            ? _actionButtons(req['id'])
                            : const SizedBox()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeList(Color textColor) {
    final list = _allEmployees;
    return Column(
      children: [
        _tableHeader(['STAFF NAME', 'ROLE', 'EMAIL', 'ID NUMBER']),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final emp = list[i];
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: aViolet.withOpacity(0.1),
                    child: Text(emp['ln'][0],
                        style: const TextStyle(color: aViolet))),
                title: Text("${emp['fn']} ${emp['ln']}",
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
                subtitle: Text(emp['email'],
                    style:
                        const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                trailing: Text(emp['user_id_number'] ?? 'NO ID',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

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
                    flex:
                        (t == 'EMPLOYEE' || t == 'REASON' || t == 'STAFF NAME')
                            ? 2
                            : 1,
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
                hintText: "Search records...",
                border: InputBorder.none,
                prefixIcon: Icon(LucideIcons.search,
                    size: 18, color: Colors.blueGrey))),
      );

  Widget _filterChip(String l, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    Color color = (status == 'Approved' || status == 'Present')
        ? success
        : (status == 'Pending' ? Colors.orangeAccent : Colors.redAccent);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 9, fontWeight: FontWeight.w900)));
  }

  Widget _actionButtons(String id) => Row(children: [
        IconButton(
            icon:
                const Icon(LucideIcons.checkCircle2, color: success, size: 18),
            onPressed: () => _handleLeaveAction(id, 'Approved')),
        IconButton(
            icon: const Icon(LucideIcons.xCircle,
                color: Colors.redAccent, size: 18),
            onPressed: () => _handleLeaveAction(id, 'Rejected')),
      ]);

  String _getTitle() => [
        "Attendance Tracking",
        "Leave Administration",
        "Staff Directory"
      ][_activeTabIndex];
  String _getSubtitle() => [
        "Personnel login/logout.",
        "Review applications.",
        "Employee list."
      ][_activeTabIndex];

  Future<void> _handleLeaveAction(String id, String status) async {
    await _service.client
        .from('leave_requests')
        .update({'status': status}).eq('id', id);
    _fetchStaticData();
  }

  Future<void> _manualLogout(String profileId) async {
    await _service.recordAttendanceLogout(profileId);
    _fetchStaticData();
  }

  Future<void> _openDocument(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal());
  }
}
