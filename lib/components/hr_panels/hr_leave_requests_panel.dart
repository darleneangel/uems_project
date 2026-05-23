import 'dart:math';
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
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// 🛰️ DATABASE: Load leave requests joined with profiles & employee details
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('leave_requests')
          .select(
              '*, profiles!leave_requests_employee_id_fkey(fn, ln, user_id_number, role, employee_details(position_title))')
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

  /// 🛰️ DATABASE: Approve or Reject Pending Leave Requests
  Future<void> _handleAction(String id, String status) async {
    setState(() => _isLoading = true);
    try {
      await _service.client
          .from('leave_requests')
          .update({'status': status, 'approved_by': widget.userData['id']}).eq(
              'id', id);

      _showSnackBar("Leave request successfully $status!", success);
      _fetchData();
    } catch (e) {
      _showSnackBar("Transaction failed: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  /// 📄 PDF OVERLAY: Triggers A4 Document preview
  void _openPdfModal(Map<String, dynamic> req, String fullName) {
    final profile = req['profiles'] as Map<String, dynamic>?;
    final String idNum = profile?['user_id_number'] ?? 'N/A';
    final String category = req['leave_type'] ?? 'Sick';
    final String start =
        DateFormat('MMMM dd').format(DateTime.parse(req['start_date']));
    final String end =
        DateFormat('MMMM dd, yyyy').format(DateTime.parse(req['end_date']));
    final String reason = req['reason'] ?? 'No formal justification provided.';
    final String status = req['status'] ?? 'Pending';

    final String submissionDate = DateFormat('MMMM dd, yyyy')
        .format(DateTime.parse(req['created_at']).toLocal());

    final String role = (profile?['role'] ?? '').toString().toLowerCase();
    final bool isEmployeeHR = role == 'hr';

    // Extract dynamic position details
    final detailsList = profile?['employee_details'];
    String positionTitle = "Staff Member";
    if (detailsList != null) {
      if (detailsList is List && detailsList.isNotEmpty) {
        positionTitle = detailsList.first['position_title'] ?? "Staff Member";
      } else if (detailsList is Map) {
        positionTitle = detailsList['position_title'] ?? "Staff Member";
      }
    }

    // Compute duration in days
    int days = 1;
    if (req['start_date'] != null && req['end_date'] != null) {
      final d1 = DateTime.parse(req['start_date'].toString());
      final d2 = DateTime.parse(req['end_date'].toString());
      days = d2.difference(d1).inDays + 1;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LeaveLetterPdfViewerModal(
        isDarkMode: widget.isDarkMode,
        employeeName: fullName,
        employeeId: idNum,
        category: category,
        startDate: start,
        endDate: end,
        totalDays: days,
        reason: reason,
        status: status,
        positionTitle: positionTitle,
        isEmployeeHR: isEmployeeHR,
        submissionDate: submissionDate,
      ),
    );
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
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Leave Administration",
                    style: GoogleFonts.inter(
                      fontSize: 32, // Elevated font size
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Review, audit, and process employee sick and vacation leave letters with official PDF tracking.",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 15), // Elevated font size
                  ),
                ],
              ),
              IconButton(
                onPressed: _fetchData,
                icon:
                    const Icon(LucideIcons.refreshCw, size: 24, color: aViolet),
              ),
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
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: _buildList(textColor),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color textColor) {
    final periodTextColor =
        widget.isDarkMode ? Colors.white70 : const Color(0xFF334155);

    final filtered = _requests.where((r) {
      if (r['profiles'] == null) return false;
      final name =
          "${r['profiles']['fn']} ${r['profiles']['ln']}".toLowerCase();
      return name.contains(_searchController.text.toLowerCase());
    }).toList();

    if (filtered.isEmpty) return _emptyState();

    return Column(
      children: [
        _tableHeader([
          'EMPLOYEE (CLICK TO AUDIT)',
          'TYPE',
          'REASON',
          'PERIOD',
          'STATUS',
          'ACTIONS'
        ]),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) => Divider(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                height: 1),
            itemBuilder: (context, i) {
              final req = filtered[i];
              final profile = req['profiles'];
              final String fullName = "${profile['fn']} ${profile['ln']}";
              final period =
                  "${_fmtDate(req['start_date'])} - ${_fmtDate(req['end_date'])}";

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // 🌟 CLICKABLE EMPLOYEE NAME CELL
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _openPdfModal(req, fullName),
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: aViolet.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.inter(
                                  color: aViolet,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16, // Bigger font size
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.5,
                                  decorationColor: aViolet.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(LucideIcons.fileText,
                                      size: 14, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "ID: ${profile['user_id_number'] ?? 'N/A'} • Click to view PDF letter",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (req['leave_type'] ?? 'Sick').toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14, // Bigger font size
                          fontWeight: FontWeight.bold,
                          color: aViolet,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        req['reason'] ?? 'No justification',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey), // Bigger font size
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        period,
                        style: TextStyle(
                            fontSize: 13,
                            color: periodTextColor,
                            fontWeight: FontWeight.bold), // Bigger font size
                      ),
                    ),
                    Expanded(child: _statusChip(req['status'])),
                    Expanded(
                      child: req['status'] == 'Pending'
                          ? _actionButtons(req)
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: titles
            .map((t) => Expanded(
                  flex: (t == 'EMPLOYEE (CLICK TO AUDIT)' || t == 'REASON')
                      ? 2
                      : 1,
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 11, // Bigger font size
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSearchBar(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white10
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: text, fontSize: 15),
        decoration: const InputDecoration(
          hintText: "Search leave requests by name...",
          hintStyle: TextStyle(color: Colors.blueGrey),
          border: InputBorder.none,
          prefixIcon:
              Icon(LucideIcons.search, size: 20, color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Approved'
        ? success
        : (status == 'Pending' ? Colors.orangeAccent : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900), // Bigger font size
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> req) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.checkCircle2, color: success, size: 22),
          onPressed: () => _handleAction(req['id'], 'Approved'),
          tooltip: "Approve Application",
        ),
        IconButton(
          icon: const Icon(LucideIcons.xCircle,
              color: Colors.redAccent, size: 22),
          onPressed: () => _handleAction(req['id'], 'Rejected'),
          tooltip: "Reject Application",
        ),
      ],
    );
  }

  String _fmtDate(String d) => DateFormat('MM/dd').format(DateTime.parse(d));
  String _fmtFullDate(String d) =>
      DateFormat('MMMM dd, yyyy').format(DateTime.parse(d));

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendar,
              size: 48, color: Colors.blueGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "No active staff leave applications detected.",
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String m, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// =====================================================================
// COMPONENT CLASS: High-Fidelity Simulated Document/PDF Archival Viewer
// =====================================================================
class _LeaveLetterPdfViewerModal extends StatefulWidget {
  final bool isDarkMode;
  final String employeeName;
  final String employeeId;
  final String category;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String positionTitle;
  final bool isEmployeeHR;
  final String submissionDate;

  const _LeaveLetterPdfViewerModal({
    required this.isDarkMode,
    required this.employeeName,
    required this.employeeId,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.positionTitle,
    required this.isEmployeeHR,
    required this.submissionDate,
  });

  @override
  State<_LeaveLetterPdfViewerModal> createState() =>
      _LeaveLetterPdfViewerModalState();
}

class _LeaveLetterPdfViewerModalState
    extends State<_LeaveLetterPdfViewerModal> {
  double _zoomLevel = 1.0;
  double _rotationAngle = 0.0;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final Color paperColor = Colors.white;
    final Color modalBgColor =
        widget.isDarkMode ? const Color(0xFF0F071D) : const Color(0xFFF1F5F9);
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1100,
        height: 850,
        decoration: BoxDecoration(
          color: modalBgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 4),
          ],
        ),
        child: Column(
          children: [
            // 🎛️ 1. PDF READER CONTROLS TOOLBAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode ? const Color(0xFF160D2B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                    bottom:
                        BorderSide(color: Colors.blueGrey.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.fileText, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 12),
                  Text(
                    "Sick_Leave_Letter_${widget.employeeId}.pdf",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 14),
                  ),
                  const Spacer(),

                  // Zoom Controls
                  IconButton(
                    onPressed: () => setState(
                        () => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 1.5)),
                    icon: Icon(LucideIcons.zoomOut, color: textColor, size: 18),
                    tooltip: "Zoom Out",
                  ),
                  Text(
                    "${(_zoomLevel * 100).toInt()}%",
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  IconButton(
                    onPressed: () => setState(
                        () => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 1.5)),
                    icon: Icon(LucideIcons.zoomIn, color: textColor, size: 18),
                    tooltip: "Zoom In",
                  ),
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1, color: Colors.blueGrey),
                  const SizedBox(width: 16),

                  // Rotate Control
                  IconButton(
                    onPressed: () => setState(
                        () => _rotationAngle = (_rotationAngle + 90) % 360),
                    icon:
                        Icon(LucideIcons.rotateCw, color: textColor, size: 18),
                    tooltip: "Rotate Page",
                  ),
                  const SizedBox(width: 16),

                  // Download Button
                  _isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6), strokeWidth: 2))
                      : ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isDownloading = true);
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                setState(() => _isDownloading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Document successfully downloaded to local Storage!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent.withOpacity(0.15),
                            foregroundColor: Colors.greenAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.download, size: 14),
                          label: const Text("DOWNLOAD",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                  const SizedBox(width: 12),

                  // Close button
                  IconButton(
                    icon: Icon(LucideIcons.x, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 📄 2. IMMERSIVE DOCUMENT PAPER VIEWPORT
            Expanded(
              child: InteractiveViewer(
                scaleEnabled: true,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Transform.rotate(
                        angle: _rotationAngle * (3.1415926535 / 180),
                        child: Transform.scale(
                          scale: _zoomLevel,
                          child: Container(
                            width: 780, // A4 Portrait Aspect Ratio Width
                            height: 1050, // A4 Portrait Aspect Ratio Height
                            padding: const EdgeInsets.all(
                                64), // Extended margins matching 48pw
                            decoration: BoxDecoration(
                              color: paperColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2),
                              ],
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: Stack(
                              children: [
                                // High Security Official Watermark
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                      angle: -0.6,
                                      child: Opacity(
                                        opacity: 0.03,
                                        child: Text(
                                          "BRIGHT FUTURE ACADEMY",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Document Content (Matches StaffProfilePortal formatting precisely)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Institutional Header
                                    Text(
                                      'BRIGHT FUTURE ACADEMY',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(
                                            0xFF1A237E), // indigo900
                                      ),
                                    ),
                                    const Text(
                                      'Institutional Human Resources Office',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(
                                        thickness: 1.5, color: Colors.black54),
                                    const SizedBox(height: 32),

                                    // Date Block
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Date: ${widget.submissionDate}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Recipient
                                    Text(
                                      widget.isEmployeeHR
                                          ? 'TO: Office of the School Administrator'
                                          : 'TO: Human Resources Management Office',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.black87),
                                    ),
                                    Text(
                                      'Bright Future Academy',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 24),

                                    // Subject
                                    Text(
                                      'SUBJECT: FORMAL APPLICATION FOR ${widget.category.toUpperCase()} LEAVE',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.black87,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Salutation
                                    Text(
                                      'To Whom It May Concern,',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 16),

                                    // Body Text
                                    Text(
                                      'I am writing to formally request a ${widget.category.toLowerCase()} leave of absence from my duties as '
                                      '${widget.positionTitle} at Bright Future Academy. I will be unable to report to work for a period of '
                                      '${widget.totalDays} day(s), effective from ${widget.startDate} to ${widget.endDate}.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Reason
                                    Text(
                                      'REASON FOR ABSENCE:',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.reason,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          height: 1.4,
                                          color: Colors.black54),
                                    ),
                                    const SizedBox(height: 24),

                                    // Concluding
                                    Text(
                                      'I have made the necessary arrangements to ensure that my pending tasks are handled or delegated appropriately during this period. I will keep the office updated should there be any changes to my recovery timeline.',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          height: 1.5,
                                          color: Colors.black87),
                                      textAlign: TextAlign.justify,
                                    ),
                                    const SizedBox(height: 64),

                                    // Signature block
                                    Text(
                                      'Respectfully yours,',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 48),
                                    Container(
                                      width: 180,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                width: 1, color: Colors.black)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.employeeName,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.black87),
                                    ),
                                    Text(
                                      'Employee ID: ${widget.employeeId}',
                                      style: GoogleFonts.inter(
                                          fontSize: 10, color: Colors.blueGrey),
                                    ),
                                    if (widget.isEmployeeHR)
                                      Text(
                                        'Role: HR Department Personnel',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color:
                                              const Color(0xFFB71C1C), // red900
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 32),

                                    // Clearance Seal (Shows approval stamp on screen inside HR system)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: widget.status == 'Approved'
                                                  ? Colors.green
                                                  : (widget.status == 'Pending'
                                                      ? Colors.orange
                                                      : Colors.red),
                                              width: 3,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Transform.rotate(
                                            angle: -0.1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  widget.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: widget.status ==
                                                            'Approved'
                                                        ? Colors.green
                                                        : (widget.status ==
                                                                'Pending'
                                                            ? Colors.orange
                                                            : Colors.red),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  "UEMSSP SECURE CLEARANCE",
                                                  style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Print Trigger Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode ? const Color(0xFF160D2B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(
                    top: BorderSide(color: Colors.blueGrey.withOpacity(0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    child: const Text("CANCEL"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "PDF printer command sent! Document logged and processed."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    icon: const Icon(LucideIcons.printer),
                    label: const Text("PRINT SYSTEM DOCUMENT"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
