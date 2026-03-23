import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class HRLeaveRequestPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HRLeaveRequestPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<HRLeaveRequestPanel> createState() => _HRLeaveRequestPanelState();
}

class _HRLeaveRequestPanelState extends State<HRLeaveRequestPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('leave_requests')
          .select(
              '*, profiles!leave_requests_employee_id_fkey(fn, ln, user_id_number)')
          // FILTER: Only show requests from regular staff, not HR themselves
          .eq('is_hr_request', false)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Leave Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Leave Administration",
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor)),
                  const Text("Review and process employee leave applications.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                ],
              ),
              IconButton(
                  onPressed: _fetchData,
                  icon: const Icon(LucideIcons.refreshCw,
                      size: 20, color: aViolet)),
            ],
          ),
          const SizedBox(height: 32),
          _buildSearchBar(cardColor, textColor),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: aViolet))
                : Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: widget.isDarkMode
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05)),
                    ),
                    child: _buildList(textColor),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color textColor) {
    final filtered = _requests.where((r) {
      final name =
          "${r['profiles']['fn']} ${r['profiles']['ln']}".toLowerCase();
      return name.contains(_searchController.text.toLowerCase());
    }).toList();

    if (filtered.isEmpty) return _emptyState();

    return Column(
      children: [
        // REMOVED 'DOC' from header list
        _tableHeader(
            ['EMPLOYEE', 'TYPE', 'REASON', 'PERIOD', 'STATUS', 'ACTIONS']),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final req = filtered[i];
              final profile = req['profiles'];
              final period =
                  "${_fmtDate(req['start_date'])} - ${_fmtDate(req['end_date'])}";

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
                            ])),
                    Expanded(
                        child: Text(req['leave_type'],
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: aViolet))),
                    Expanded(
                        flex: 2,
                        child: Text(req['reason'] ?? 'No justification',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blueGrey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        child:
                            Text(period, style: const TextStyle(fontSize: 11))),
                    // REMOVED 'DOC' (attachment_url) UI column from the row
                    Expanded(child: _statusChip(req['status'])),
                    Expanded(
                        child: req['status'] == 'Pending'
                            ? _actionButtons(req)
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
                    flex: (t == 'EMPLOYEE' || t == 'REASON') ? 2 : 1,
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
                hintText: "Search requests...",
                border: InputBorder.none,
                prefixIcon: Icon(LucideIcons.search,
                    size: 18, color: Colors.blueGrey))),
      );

  Widget _statusChip(String status) {
    Color color = status == 'Approved'
        ? success
        : (status == 'Pending' ? Colors.orangeAccent : Colors.redAccent);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 9, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center));
  }

  Widget _actionButtons(Map<String, dynamic> req) => Row(children: [
        IconButton(
            icon:
                const Icon(LucideIcons.checkCircle2, color: success, size: 18),
            onPressed: () => _handleAction(req['id'], 'Approved')),
        IconButton(
            icon: const Icon(LucideIcons.xCircle,
                color: Colors.redAccent, size: 18),
            onPressed: () => _handleAction(req['id'], 'Rejected')),
      ]);

  Future<void> _handleAction(String id, String status) async {
    await _service.client.from('leave_requests').update(
        {'status': status, 'approved_by': widget.userData['id']}).eq('id', id);
    _fetchData();
  }

  String _fmtDate(String d) => DateFormat('MM/dd').format(DateTime.parse(d));

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.calendar,
            size: 40, color: Colors.blueGrey.withOpacity(0.3)),
        const SizedBox(height: 12),
        const Text("No pending requests.",
            style: TextStyle(color: Colors.blueGrey))
      ]));
}
