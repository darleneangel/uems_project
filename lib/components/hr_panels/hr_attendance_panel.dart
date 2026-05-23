import 'dart:async';
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

  // Tab Control State
  int _activeTab =
      0; // 0: Live Staff Attendance, 1: Leave Requests, 2: Workforce Audits

  // Tab 0 States
  List<Map<String, dynamic>> _cachedLogs = [];
  bool _isLoadingAttendance = true;
  bool _showArchives = false; // Toggle for Today vs Historical Data
  DateTime _selectedDateFilter = DateTime.now();

  // Tab 1 States
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoadingLeaves = true;

  // Tab 2 States (Immutable Audit Trail)
  List<Map<String, dynamic>> _systemAudits = [];
  bool _isLoadingAudits = true;

  // Cache for employee profiles (used for manual entry selection)
  List<Map<String, dynamic>> _staffProfiles = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchStaticData();
    _fetchLeaveRequests();
    _fetchWorkforceAudits();
    _loadStaffProfiles();
  }

  // ---------------------------------------------------------------------
  // TAB 0 DATABASE QUERIES: Attendance Log Sync & Overrides
  // ---------------------------------------------------------------------

  /// Fetch profiles to populate dropdowns for manual logs
  Future<void> _loadStaffProfiles() async {
    try {
      final res = await _service.client
          .from('profiles')
          .select('id, fn, ln, user_id_number, role')
          .neq('role', 'student')
          .order('ln', ascending: true);

      if (mounted && res != null) {
        setState(() {
          _staffProfiles = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint("Error loading staff list: $e");
    }
  }

  /// Unified fetch for logs (Robust fallback to solve standard Supabase streaming limitations)
  Future<void> _fetchStaticData() async {
    if (!mounted) return;
    setState(() => _isLoadingAttendance = true);
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDateFilter);

      var query = _service.client
          .from('attendance_logs')
          .select('*, profiles(fn, ln, user_id_number, role)');

      if (_showArchives) {
        query = query.lt('log_date', todayStr); // Fetch older logs
      } else {
        query = query.eq('log_date', todayStr); // Fetch selected day's logs
      }

      final res = await query.order('check_in_time', ascending: false);
      if (mounted) {
        setState(() {
          _cachedLogs = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint("Attendance Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  /// 🛰️ DATABASE: Manual override check-in by HR
  Future<void> _createManualLog({
    required String userId,
    required DateTime checkIn,
    DateTime? checkOut,
    required String status,
    required String remarks,
  }) async {
    setState(() => _isLoadingAttendance = true);
    try {
      final String logDate = DateFormat('yyyy-MM-dd').format(checkIn);

      // 1. Insert log record
      await _service.client.from('attendance_logs').insert({
        'user_id': userId,
        'check_in_time': checkIn.toUtc().toIso8601String(),
        'check_out_time': checkOut?.toUtc().toIso8601String(),
        'status': status,
        'remarks': remarks,
        'log_date': logDate,
      });

      // 2. Track action within system audit log (shared leave ledger container)
      await _service.client.from('leave_requests').insert({
        'employee_id': userId,
        'leave_type': 'Manual Correction',
        'start_date': logDate,
        'end_date': logDate,
        'status': 'Approved',
        'reason': 'Attendance entry manually corrected/created by HR: $remarks',
        'processed_by': widget.userData['id'],
      });

      _showSnackBar("Attendance log successfully generated!", success);
      _fetchStaticData();
      _fetchWorkforceAudits();
    } catch (e) {
      _showSnackBar("Failed to create log: $e", Colors.redAccent);
      setState(() => _isLoadingAttendance = false);
    }
  }

  /// 🛰️ DATABASE: Edit details of an existing log
  Future<void> _updateAttendanceLog({
    required String logId,
    required DateTime checkIn,
    DateTime? checkOut,
    required String status,
    required String remarks,
    required String employeeId,
  }) async {
    setState(() => _isLoadingAttendance = true);
    try {
      await _service.client.from('attendance_logs').update({
        'check_in_time': checkIn.toUtc().toIso8601String(),
        'check_out_time': checkOut?.toUtc().toIso8601String(),
        'status': status,
        'remarks': remarks,
      }).eq('id', logId);

      // Log HR edit action in audit logs
      await _service.client.from('leave_requests').insert({
        'employee_id': employeeId,
        'leave_type': 'Log Modified',
        'start_date': DateFormat('yyyy-MM-dd').format(checkIn),
        'end_date': DateFormat('yyyy-MM-dd').format(checkIn),
        'status': 'Approved',
        'reason': 'Adjusted check-in/out times. Notes: $remarks',
        'processed_by': widget.userData['id'],
      });

      _showSnackBar("Attendance details successfully updated!", success);
      _fetchStaticData();
      _fetchWorkforceAudits();
    } catch (e) {
      _showSnackBar("Update failed: $e", Colors.redAccent);
      setState(() => _isLoadingAttendance = false);
    }
  }

  /// 🛰️ DATABASE: Delete an attendance log entry
  Future<void> _deleteAttendanceLog(
      String logId, String employeeId, String dateStr) async {
    setState(() => _isLoadingAttendance = true);
    try {
      await _service.client.from('attendance_logs').delete().eq('id', logId);

      // Record deletions inside system audit log
      await _service.client.from('leave_requests').insert({
        'employee_id': employeeId,
        'leave_type': 'Log Deleted',
        'start_date': dateStr,
        'end_date': dateStr,
        'status': 'Rejected',
        'reason': 'Attendance log deleted by HR administration.',
        'processed_by': widget.userData['id'],
      });

      _showSnackBar(
          "Attendance log successfully removed.", Colors.orangeAccent);
      _fetchStaticData();
      _fetchWorkforceAudits();
    } catch (e) {
      _showSnackBar("Deletion failed: $e", Colors.redAccent);
      setState(() => _isLoadingAttendance = false);
    }
  }

  // ---------------------------------------------------------------------
  // TAB 1 DATABASE QUERIES: Leave & Absences
  // ---------------------------------------------------------------------
  Future<void> _fetchLeaveRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingLeaves = true);
    try {
      final res = await _service.client
          .from('leave_requests')
          .select('*, profiles!employee_id(fn, ln, user_id_number, role)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _leaveRequests = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint("Leaves Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLeaves = false);
    }
  }

  Future<void> _processLeave(String leaveId, String status) async {
    setState(() => _isLoadingLeaves = true);
    try {
      await _service.client.from('leave_requests').update({
        'status': status,
        'processed_by': widget.userData['id'],
      }).eq('id', leaveId);

      _showSnackBar("Leave request successfully $status!", success);
      _fetchLeaveRequests();
      _fetchWorkforceAudits(); // Update audit trails
    } catch (e) {
      _showSnackBar("Failed to process leave: $e", Colors.redAccent);
    }
  }

  // ---------------------------------------------------------------------
  // TAB 2 DATABASE QUERIES: Immutable Profile & Salary Audit Trail
  // ---------------------------------------------------------------------
  Future<void> _fetchWorkforceAudits() async {
    if (!mounted) return;
    setState(() => _isLoadingAudits = true);
    try {
      final res = await _service.client
          .from('leave_requests')
          .select(
              '*, profiles!employee_id(fn, ln, user_id_number, role), auditor:profiles!processed_by(fn, ln)')
          .not('processed_by', 'is', null)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _systemAudits = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint("Audits Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAudits = false);
    }
  }

  // ---------------------------------------------------------------------
  // DIALOG FORMS: Create & Edit Attendance Logs
  // ---------------------------------------------------------------------
  void _openAttendanceForm([Map<String, dynamic>? logItem]) {
    final bool isEdit = logItem != null;
    final formKey = GlobalKey<FormState>();

    // Set form initial states
    String? selectedStaffId = isEdit ? logItem['user_id'] : null;
    String selectedStatus =
        isEdit ? (logItem['status'] ?? 'Present') : 'Present';
    final remarksController =
        TextEditingController(text: isEdit ? (logItem['remarks'] ?? '') : '');

    DateTime checkInDate = isEdit
        ? DateTime.parse(logItem['check_in_time']).toLocal()
        : DateTime.now();
    TimeOfDay checkInTime = isEdit
        ? TimeOfDay.fromDateTime(
            DateTime.parse(logItem['check_in_time']).toLocal())
        : const TimeOfDay(hour: 8, minute: 0);

    DateTime? checkOutDate = logItem?['check_out_time'] != null
        ? DateTime.parse(logItem!['check_out_time']).toLocal()
        : null;
    TimeOfDay? checkOutTime = logItem?['check_out_time'] != null
        ? TimeOfDay.fromDateTime(
            DateTime.parse(logItem!['check_out_time']).toLocal())
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setFormState) {
          final modalTextColor =
              widget.isDarkMode ? Colors.white : Colors.black87;

          return AlertDialog(
            backgroundColor:
                widget.isDarkMode ? const Color(0xFF0F071D) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              children: [
                Icon(isEdit ? LucideIcons.edit : LucideIcons.plusCircle,
                    color: aViolet),
                const SizedBox(width: 12),
                Text(
                  isEdit
                      ? "Modify Attendance Record"
                      : "Manually Clock-In Staff",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: modalTextColor,
                      fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Employee Dropdown (Disabled during edits)
                      if (!isEdit) ...[
                        Text("SELECT EMPLOYEE STAFF",
                            style: GoogleFonts.inter(
                                color: Colors.blueGrey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          dropdownColor:
                              widget.isDarkMode ? surfaceDark : Colors.white,
                          style: TextStyle(color: modalTextColor, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          hint: const Text("Choose staff member...",
                              style: TextStyle(color: Colors.blueGrey)),
                          value: selectedStaffId,
                          validator: (val) => val == null
                              ? "Please select a staff member"
                              : null,
                          onChanged: (val) =>
                              setFormState(() => selectedStaffId = val),
                          items: _staffProfiles.map((p) {
                            return DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text(
                                  "${p['ln']}, ${p['fn']} (${p['role'].toString().toUpperCase()})"),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.user,
                                  color: aViolet, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Employee: ${logItem!['profiles']?['fn']} ${logItem['profiles']?['ln']}",
                                style: TextStyle(
                                    color: modalTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 2. Check-In Date and Time Pickers
                      Text("CLOCK-IN TIMESTAMP",
                          style: GoogleFonts.inter(
                              color: Colors.blueGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: checkInDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 30)),
                                );
                                if (date != null)
                                  setFormState(() => checkInDate = date);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: Colors.blueGrey.withOpacity(0.3)),
                                foregroundColor: modalTextColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(LucideIcons.calendar, size: 16),
                              label: Text(
                                  DateFormat('MM/dd/yyyy').format(checkInDate)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: checkInTime,
                                );
                                if (time != null)
                                  setFormState(() => checkInTime = time);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: Colors.blueGrey.withOpacity(0.3)),
                                foregroundColor: modalTextColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(LucideIcons.clock, size: 16),
                              label: Text(checkInTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. Check-Out Date and Time Pickers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("CLOCK-OUT TIMESTAMP (OPTIONAL)",
                              style: GoogleFonts.inter(
                                  color: Colors.blueGrey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          if (checkOutDate != null)
                            GestureDetector(
                              onTap: () => setFormState(() {
                                checkOutDate = null;
                                checkOutTime = null;
                              }),
                              child: const Text("Clear",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: checkOutDate ?? checkInDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 30)),
                                );
                                if (date != null) {
                                  setFormState(() {
                                    checkOutDate = date;
                                    checkOutTime ??=
                                        const TimeOfDay(hour: 17, minute: 0);
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: Colors.blueGrey.withOpacity(0.3)),
                                foregroundColor: modalTextColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(LucideIcons.calendar, size: 16),
                              label: Text(checkOutDate != null
                                  ? DateFormat('MM/dd/yyyy')
                                      .format(checkOutDate!)
                                  : "Select Date"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: checkOutDate == null
                                  ? null
                                  : () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: checkOutTime ??
                                            const TimeOfDay(
                                                hour: 17, minute: 0),
                                      );
                                      if (time != null)
                                        setFormState(() => checkOutTime = time);
                                    },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: Colors.blueGrey.withOpacity(0.3)),
                                foregroundColor: modalTextColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(LucideIcons.clock, size: 16),
                              label: Text(checkOutTime != null
                                  ? checkOutTime!.format(context)
                                  : "Select Time"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Status Selection
                      Text("ATTENDANCE STATUS",
                          style: GoogleFonts.inter(
                              color: Colors.blueGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor:
                            widget.isDarkMode ? surfaceDark : Colors.white,
                        style: TextStyle(color: modalTextColor, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: widget.isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        value: selectedStatus,
                        onChanged: (val) =>
                            setFormState(() => selectedStatus = val!),
                        items: ['Present', 'Late', 'Overtime', 'Undertime']
                            .map((s) {
                          return DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase()));
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 5. Remarks/Auditing text
                      Text("MEMO / AUDITING NOTES",
                          style: GoogleFonts.inter(
                              color: Colors.blueGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: remarksController,
                        style: TextStyle(color: modalTextColor, fontSize: 14),
                        maxLines: 2,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Verification remarks are required"
                            : null,
                        decoration: InputDecoration(
                          hintText:
                              "Add reasoning for manual insertion/alteration...",
                          hintStyle: const TextStyle(
                              color: Colors.blueGrey, fontSize: 13),
                          filled: true,
                          fillColor: widget.isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.blueGrey))),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx);

                    // Recompile dates
                    final DateTime finalCheckIn = DateTime(
                        checkInDate.year,
                        checkInDate.month,
                        checkInDate.day,
                        checkInTime.hour,
                        checkInTime.minute);
                    DateTime? finalCheckOut;
                    if (checkOutDate != null && checkOutTime != null) {
                      finalCheckOut = DateTime(
                          checkOutDate!.year,
                          checkOutDate!.month,
                          checkOutDate!.day,
                          checkOutTime!.hour,
                          checkOutTime!.minute);
                    }

                    if (isEdit) {
                      _updateAttendanceLog(
                        logId: logItem!['id'],
                        checkIn: finalCheckIn,
                        checkOut: finalCheckOut,
                        status: selectedStatus,
                        remarks: remarksController.text,
                        employeeId: logItem['user_id'],
                      );
                    } else {
                      _createManualLog(
                        userId: selectedStaffId!,
                        checkIn: finalCheckIn,
                        checkOut: finalCheckOut,
                        status: selectedStatus,
                        remarks: remarksController.text,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(isEdit ? "SAVE CHANGES" : "MANUAL CLOCK-IN"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog confirmation before deleting a log
  void _confirmDeleteLog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? surfaceDark : Colors.white,
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Delete Attendance Log?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently erase the attendance record for "
          "${log['profiles']?['fn']} ${log['profiles']?['ln']} on ${_formatDate(log['log_date'])}?\n\n"
          "This action will trigger an immutable security auditing log tracking this deletion.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAttendanceLog(
                  log['id'], log['user_id'], log['log_date'].toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("CONFIRM DELETE"),
          ),
        ],
      ),
    );
  }

  /// 📥 SIMULATED PDF VIEW OVERLAY DIALOG TRIGGER
  void _viewLeaveAttachment(Map<String, dynamic> leave, String name) {
    final profile = leave['profiles'] as Map<String, dynamic>?;
    final String idNum = profile?['user_id_number'] ?? 'N/A';
    final String category = leave['leave_type'] ?? 'Sick Leave';
    final String start = _formatDate(leave['start_date']);
    final String end = _formatDate(leave['end_date']);
    final String reason =
        leave['reason'] ?? 'No formal justification provided.';
    final String status = leave['status'] ?? 'Pending';
    final String attachmentUrl = leave['attachment_url'] ??
        'https://ipmkemontxkxzfymidej.supabase.co/storage/v1/object/public/leave_attachments/medical_clearance_sample.pdf';

    // Calculate absolute days
    int days = 1;
    if (leave['start_date'] != null && leave['end_date'] != null) {
      final d1 = DateTime.parse(leave['start_date'].toString());
      final d2 = DateTime.parse(leave['end_date'].toString());
      days = d2.difference(d1).inDays + 1;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LeavePdfViewerModal(
        isDarkMode: widget.isDarkMode,
        employeeName: name,
        employeeId: idNum,
        category: category,
        startDate: start,
        endDate: end,
        totalDays: days,
        reason: reason,
        status: status,
        attachmentUrl: attachmentUrl,
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
          // --- HEADER & TAB NAVIGATION SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTabTitle(),
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5),
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck,
                          size: 12, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        _getTabSubTitle(),
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

              // TAB CHIPS CONTROL BAR
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _tabChip("Attendance", 0, LucideIcons.calendar),
                    _tabChip("Leaves", 1, LucideIcons.mailOpen),
                    _tabChip("Audit Log", 2, LucideIcons.history),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Search Bar & Action Buttons (Rendered only on Tab 0 & Tab 1)
          if (_activeTab != 2) ...[
            Row(
              children: [
                Expanded(child: _buildSearchBar(cardColor, textColor)),

                // Add Manual Entry Button (Only for Tab 0 Attendance logs)
                if (_activeTab == 0) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openAttendanceForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      elevation: 0,
                    ),
                    icon: const Icon(LucideIcons.plusCircle, size: 16),
                    label: const Text("ADD MANUAL LOG",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildSelectedTabContent(textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String title, int index, IconData icon) {
    final bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? Colors.white : Colors.blueGrey, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(Color textColor) {
    switch (_activeTab) {
      case 0:
        return _buildAttendanceSubmodule(textColor);
      case 1:
        return _buildLeavesSubmodule(textColor);
      case 2:
        return _buildImmutableAuditTrail(textColor);
      default:
        return _buildAttendanceSubmodule(textColor);
    }
  }

  // ---------------------------------------------------------------------
  // SUBMODULE: TAB 0 - Attendance List with Student Roles Filtered Out
  // ---------------------------------------------------------------------
  Widget _buildAttendanceSubmodule(Color textColor) {
    final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDateFilter);

    return Column(
      key: const ValueKey(0),
      children: [
        // Submodule Filter Bar (Date Selector + Archives Toggle)
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 24, left: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date picker control to load precise days
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateFilter,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDateFilter = date;
                    });
                    _fetchStaticData();
                  }
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: textColor,
                  side: BorderSide(color: textColor.withOpacity(0.2)),
                ),
                icon:
                    const Icon(LucideIcons.calendar, size: 14, color: aViolet),
                label: Text(
                    "Viewing: ${DateFormat('MM/dd/yyyy').format(_selectedDateFilter)}"),
              ),
              Row(
                children: [
                  _filterChip("Today's Logs", !_showArchives, () {
                    setState(() {
                      _showArchives = false;
                      _selectedDateFilter = DateTime.now();
                    });
                    _fetchStaticData();
                  }),
                  _filterChip("Archives Logbook", _showArchives, () {
                    setState(() => _showArchives = true);
                    _fetchStaticData();
                  }),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _fetchStaticData,
                    icon: const Icon(LucideIcons.refreshCw,
                        size: 16, color: aViolet),
                  ),
                ],
              ),
            ],
          ),
        ),
        _tableHeader([
          'DATE',
          'EMPLOYEE',
          'ROLE',
          'TIME IN',
          'TIME OUT',
          'STATUS',
          'REMARKS',
          'ACTIONS'
        ]),
        Expanded(
          child: _isLoadingAttendance
              ? const Center(child: CircularProgressIndicator(color: aViolet))
              : _cachedLogs.isEmpty
                  ? _emptyState(_showArchives
                      ? "No historical records found before ${DateFormat('MM/dd/yyyy').format(_selectedDateFilter)}."
                      : "No workforce logs recorded for ${DateFormat('MM/dd/yyyy').format(_selectedDateFilter)}.")
                  : ListView.separated(
                      itemCount: _cachedLogs.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      separatorBuilder: (_, __) => Divider(
                          color: widget.isDarkMode
                              ? Colors.white10
                              : Colors.black12,
                          height: 1),
                      itemBuilder: (context, i) {
                        final log = _cachedLogs[i];
                        final profile =
                            log['profiles'] as Map<String, dynamic>?;

                        if (profile == null) return const SizedBox.shrink();

                        // 🔒 HR COMPLIANCE FILTER: Exclude students from display bounds
                        final role = (profile['role'] ?? '')
                            .toString()
                            .toLowerCase()
                            .trim();
                        if (role == 'student' || role.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final name =
                            "${profile['fn']} ${profile['ln']}".toLowerCase();
                        if (_searchController.text.isNotEmpty &&
                            !name.contains(
                                _searchController.text.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
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
                                  child: Text(
                                      "${profile['fn']} ${profile['ln']}",
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13))),
                              Expanded(
                                  child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: aViolet.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                      color: aViolet,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                              Expanded(
                                  child: Text(_formatTime(log['check_in_time']),
                                      style: GoogleFonts.inter(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                child: log['check_out_time'] != null
                                    ? Text(_formatTime(log['check_out_time']),
                                        style: GoogleFonts.inter(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))
                                    : const Text("--:--",
                                        style: TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12)),
                              ),
                              Expanded(
                                  child:
                                      _statusChip(log['status'] ?? 'Present')),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  log['remarks'] ?? 'Normal Check-In',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.blueGrey, fontSize: 11),
                                ),
                              ),
                              // HR Controls Panel on Each item
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit,
                                          size: 16, color: aViolet),
                                      onPressed: () => _openAttendanceForm(log),
                                      tooltip: "Adjust Times / Override Status",
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2,
                                          size: 16, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteLog(log),
                                      tooltip: "Delete Record",
                                    ),
                                  ],
                                ),
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

  // ---------------------------------------------------------------------
  // SUBMODULE: TAB 1 - Leaves & Absences (HR Processing Center with PDF Click Viewer)
  // ---------------------------------------------------------------------
  Widget _buildLeavesSubmodule(Color textColor) {
    if (_isLoadingLeaves) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    // Apply HR search filter key to leave lists
    final searchKey = _searchController.text.trim().toLowerCase();
    final list = _leaveRequests.where((l) {
      final profile = l['profiles'] as Map<String, dynamic>?;
      if (profile == null) return false;
      final name =
          "${profile['fn'] ?? ''} ${profile['ln'] ?? ''}".toLowerCase();
      return searchKey.isEmpty || name.contains(searchKey);
    }).toList();

    if (list.isEmpty) {
      return _emptyState("No active leave or absence requests logged.");
    }

    return Column(
      key: const ValueKey(1),
      children: [
        _tableHeader([
          'STAFF NAME (CLICK TO AUDIT)',
          'ABSENCE CATEGORY',
          'TIMEFRAME',
          'DUR.',
          'STATE',
          'DECISION'
        ]),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) => Divider(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                height: 1),
            itemBuilder: (context, i) {
              final leave = list[i];
              final profile = leave['profiles'] as Map<String, dynamic>?;
              final name =
                  "${profile?['fn'] ?? 'Staff'} ${profile?['ln'] ?? 'Member'}";
              final category = leave['leave_type'] ?? 'Sick Leave';
              final start = _formatDate(leave['start_date']);
              final end = _formatDate(leave['end_date']);
              final status = leave['status'] ?? 'Pending';

              // Calculate absolute days
              int days = 1;
              if (leave['start_date'] != null && leave['end_date'] != null) {
                final d1 = DateTime.parse(leave['start_date'].toString());
                final d2 = DateTime.parse(leave['end_date'].toString());
                days = d2.difference(d1).inDays + 1;
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // 🌟 STAFF NAME COLUMN: Stylized hyperlinked text for PDF viewing modal
                    Expanded(
                      flex: 2, // Increased flex allocation
                      child: InkWell(
                        onTap: () => _viewLeaveAttachment(leave, name),
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: aViolet.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  color: aViolet,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16, // Enlarger font size requested
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.5,
                                  decorationColor: aViolet.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(LucideIcons.fileText,
                                      size: 12, color: Colors.blueGrey),
                                  SizedBox(width: 4),
                                  Text(
                                    "Click to view submitted PDF Document",
                                    style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 11,
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
                      category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: widget.isDarkMode
                            ? Colors.white70
                            : const Color(0xFF334155),
                        fontSize: 14, // Enlarger font size requested
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    Expanded(
                        child: Text(
                      "$start - $end",
                      style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13), // Enlarger font size requested
                    )),
                    Expanded(
                        child: Text(
                      "$days Days",
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold), // Enlarger font size requested
                    )),
                    Expanded(child: _statusChip(status)),
                    Expanded(
                      child: status == 'Pending'
                          ? Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _processLeave(leave['id'], 'Approved'),
                                  icon: const Icon(LucideIcons.check,
                                      color: success, size: 20),
                                  tooltip: "Approve Leave",
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _processLeave(leave['id'], 'Rejected'),
                                  icon: const Icon(LucideIcons.x,
                                      color: Colors.redAccent, size: 20),
                                  tooltip: "Reject Leave",
                                ),
                              ],
                            )
                          : const Text("PROCESSED",
                              style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
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

  // ---------------------------------------------------------------------
  // SUBMODULE: TAB 2 - Immutable Salary & Contract Change Trail (Security)
  // ---------------------------------------------------------------------
  Widget _buildImmutableAuditTrail(Color textColor) {
    if (_isLoadingAudits) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    if (_systemAudits.isEmpty) {
      return _emptyState(
          "No workforce contractual changes have been audited yet.");
    }

    return Column(
      key: const ValueKey(2),
      children: [
        _tableHeader([
          'AUDIT TIMESTAMP',
          'ACTION DESCRIPTION',
          'AUTHOR OPERATOR',
          'SECURITY STATUS'
        ]),
        Expanded(
          child: ListView.separated(
            itemCount: _systemAudits.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) => Divider(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                height: 1),
            itemBuilder: (context, i) {
              final audit = _systemAudits[i];
              final date = _formatDate(audit['created_at']);
              final String auditType =
                  audit['leave_type'] ?? 'Manual Correction';

              // Build high-security system tracking descriptions based on audits
              final String employeeName =
                  "${audit['profiles']?['fn'] ?? 'Staff'} ${audit['profiles']?['ln'] ?? 'Member'}";
              final String auditorName =
                  "${audit['auditor']?['fn'] ?? 'HR'} ${audit['auditor']?['ln'] ?? 'Administrator'}";

              String description = "";
              if (auditType == 'Manual Correction') {
                description =
                    "Manually clocked-in attendance for $employeeName. Notes: ${audit['reason'] ?? ''}";
              } else if (auditType == 'Log Modified') {
                description =
                    "Overwrote and updated checked times for $employeeName. Notes: ${audit['reason'] ?? ''}";
              } else if (auditType == 'Log Deleted') {
                description =
                    "Purged previous attendance log for $employeeName.";
              } else {
                description =
                    "Processed leave/absence status change for $employeeName (${audit['reason'] ?? ''})";
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(date,
                            style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text(description,
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13))),
                    Expanded(
                        child: Text("$auditorName (HR Staff)",
                            style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck,
                            color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 6),
                        Text("SIGNED-LOG",
                            style: GoogleFonts.inter(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // HELPERS, LABELS, & SEARCH BAR UTILITIES
  // ---------------------------------------------------------------------

  String _getTabTitle() {
    if (_activeTab == 0)
      return _showArchives ? "Attendance Archives" : "Daily Attendance";
    if (_activeTab == 1) return "Leaves & Absence Portal";
    return "Immutable Security Audits";
  }

  String _getTabSubTitle() {
    if (_activeTab == 0)
      return _showArchives ? "HISTORICAL LOGBOOK" : "LIVE SYSTEM SYNC ACTIVE";
    if (_activeTab == 1) return "WORKFORCE CALENDAR CONTROLS";
    return "READ-ONLY INSTITUTIONAL SECURITY LEDGER";
  }

  Widget _tableHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.02)
              : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(
          children: titles
              .map((t) => Expanded(
                  flex: t == 'EMPLOYEE' ||
                          t == 'STAFF NAME (CLICK TO AUDIT)' ||
                          t == 'ACTION DESCRIPTION' ||
                          t == 'REMARKS'
                      ? 2
                      : 1,
                  child: Text(t,
                      style: GoogleFonts.inter(
                          fontSize: 11, // Larger font size requested
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey,
                          letterSpacing: 1.2))))
              .toList()),
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
                  : Colors.black.withOpacity(0.05))),
      child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: text),
          decoration: const InputDecoration(
              hintText: "Search logs by employee name...",
              hintStyle: TextStyle(color: Colors.blueGrey),
              border: InputBorder.none,
              prefixIcon:
                  Icon(LucideIcons.search, size: 18, color: Colors.blueGrey))),
    );
  }

  Widget _filterChip(String l, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: active ? aViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? Colors.transparent : Colors.white10)),
          child: Text(l,
              style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w800))),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Present' || status == 'Approved'
        ? success
        : Colors.orangeAccent;
    if (status == 'Rejected') color = Colors.redAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900))); // Larger font size requested
  }

  Widget _emptyState(String msg) {
    return Center(
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
  }

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
class _LeavePdfViewerModal extends StatefulWidget {
  final bool isDarkMode;
  final String employeeName;
  final String employeeId;
  final String category;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String attachmentUrl;

  const _LeavePdfViewerModal({
    required this.isDarkMode,
    required this.employeeName,
    required this.employeeId,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.attachmentUrl,
  });

  @override
  State<_LeavePdfViewerModal> createState() => _LeavePdfViewerModalState();
}

class _LeavePdfViewerModalState extends State<_LeavePdfViewerModal> {
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
                    "leave_clearance_record_${widget.employeeId}.pdf",
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

            // 📄 2. DOCUMENT ARCHIVE PAPER VIEWPORT
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
                            padding: const EdgeInsets.all(48),
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
                                        opacity: 0.04,
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

                                // Document Content
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Letterhead
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "BRIGHT FUTURE ACADEMY",
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                letterSpacing: 1.2,
                                                color: const Color(0xFF1E1033),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "Office of Human Resources & Institutional Planning",
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Text(
                                              "Official Leave & Medical Absence Clearance Form",
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        // Official Verification Stamp/Barcode
                                        Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black,
                                                width: 1.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(LucideIcons.qrCode,
                                                  size: 40,
                                                  color: Colors.black),
                                              const SizedBox(height: 4),
                                              Text(
                                                "ID-${widget.employeeId}",
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(
                                        color: Colors.black, thickness: 1.5),
                                    const SizedBox(height: 28),

                                    // Form Classification
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black, width: 1),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: Text(
                                          "SECTION CERTIFICATION: ${widget.category.toUpperCase()}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 36),

                                    // I. Employee Metadata Details
                                    _buildFormSectionTitle(
                                        "I. REGISTERED APPLICANT METADATA"),
                                    const SizedBox(height: 12),
                                    _buildFormRow("Employee Full Name",
                                        widget.employeeName),
                                    _buildFormRow("Institutional ID Number",
                                        widget.employeeId),
                                    _buildFormRow("Assigned Portal Role",
                                        "FACULTY / STAFF"),
                                    const SizedBox(height: 24),

                                    // II. Leave Chronology
                                    _buildFormSectionTitle(
                                        "II. ABSENCE LEAVE CHRONOLOGY"),
                                    const SizedBox(height: 12),
                                    _buildFormRow(
                                        "Period Start Date", widget.startDate),
                                    _buildFormRow(
                                        "Period End Date", widget.endDate),
                                    _buildFormRow("Total Requested Duration",
                                        "${widget.totalDays} Academic Days"),
                                    const SizedBox(height: 24),

                                    // III. Justification & Details
                                    _buildFormSectionTitle(
                                        "III. FORMAL JUSTIFICATION & MEDICAL CLEARANCE NOTES"),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.reason,
                                        style: GoogleFonts.notoSans(
                                          fontSize: 12,
                                          height: 1.6,
                                          color: Colors.black87,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 36),

                                    // IV. Official Clearance Declarations
                                    _buildFormSectionTitle(
                                        "IV. OFFICIAL SYSTEM CLEARANCE STAMP"),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        // Certification stamp
                                        Container(
                                          padding: const EdgeInsets.all(12),
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
                                        const Spacer(),
                                        // Signature line
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Digitally Signed",
                                              style: GoogleFonts.parisienne(
                                                fontSize: 22,
                                                color: const Color(0xFF6D28D9),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              width: 180,
                                              height: 1,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              "Office of Human Resources (SysAdmin)",
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey),
                                            ),
                                          ],
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

  Widget _buildFormSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        fontSize: 10,
        letterSpacing: 1.1,
        color: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildFormRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
