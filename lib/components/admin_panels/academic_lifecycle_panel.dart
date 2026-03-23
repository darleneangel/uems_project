import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class AcademicLifecyclePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AcademicLifecyclePanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AcademicLifecyclePanel> createState() => _AcademicLifecyclePanelState();
}

class _AcademicLifecyclePanelState extends State<AcademicLifecyclePanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _terms = [];
  Map<String, dynamic>? _enrollmentSettings;

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _refreshLifecycleData();
  }

  /// 🛰️ DATABASE: Syncs the institutional calendar and global enrollment toggles
  Future<void> _refreshLifecycleData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetch all academic terms ordered by chronological label
      final res = await _service.client
          .from('academic_terms')
          .select('*')
          .order('year_label', ascending: false)
          .order('semester_label', ascending: true);

      // Fetch global enrollment portal settings
      final settingsRes = await _service.client
          .from('system_settings')
          .select('*')
          .eq('key', 'enrollment_status')
          .maybeSingle();

      setState(() {
        _terms = List<Map<String, dynamic>>.from(res);
        _enrollmentSettings = settingsRes?['value'];
        _isLoading = false;
      });
    } catch (e) {
      _showToast("Institutional Sync Error: Unable to reach core ledger.",
          Colors.redAccent);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🛰️ DATABASE: Toggles global enrollment portal status across the university
  Future<void> _toggleGlobalEnrollment(bool isOpen) async {
    setState(() => _isActionLoading = true);
    try {
      final updatedValue = Map<String, dynamic>.from(_enrollmentSettings ?? {});
      updatedValue['is_open'] = isOpen;

      await _service.client
          .from('system_settings')
          .update({'value': updatedValue}).eq('key', 'enrollment_status');

      await _refreshLifecycleData();
      _showToast(
          isOpen ? "Enrollment Gateway Opened" : "Enrollment Gateway Closed",
          isOpen ? success : Colors.orangeAccent);
    } catch (e) {
      _showToast("Gateway Toggle Failed", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// 🛰️ DATABASE: Activating a term automatically deactivates all others for integrity
  Future<void> _toggleTermStatus(String id, bool active) async {
    setState(() => _isActionLoading = true);
    try {
      if (active) {
        // Enforce Scholastic Rule: Only one period can be active at a time
        await _service.client
            .from('academic_terms')
            .update({'is_active': false}).neq('id', id);
      }

      await _service.client.from('academic_terms').update({
        'is_active': active,
        'updated_by': widget.userData['id'] // Audit trail
      }).eq('id', id);

      await _refreshLifecycleData();
      _showToast(
          active ? "Academic Period Activated" : "Period Deactivated", success);
    } catch (e) {
      _showToast("Activation Error: Verification failed.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildEnrollmentControl(cardColor, textColor),
          const SizedBox(height: 48),
          Row(
            children: [
              Text("OFFICIAL TERM REGISTRY",
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: aViolet,
                      letterSpacing: 1.5)),
              const Spacer(),
              Text("${_terms.length} RECOGNIZED ENTRIES",
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: aViolet))
                : ListView.separated(
                    itemCount: _terms.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final term = _terms[i];
                      final bool isActive = term['is_active'] ?? false;
                      return _termCard(term, isActive, cardColor, textColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Academic Lifecycle",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w900, color: t)),
            const Text(
                "Institutional command for academic years, semesters, and intake periods.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          ]),
          ElevatedButton.icon(
            onPressed: _showAddTermDialog,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text("PROVISION NEW TERM"),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ],
      );

  Widget _buildEnrollmentControl(Color bg, Color text) {
    bool isOpen = _enrollmentSettings?['is_open'] ?? false;
    String deadline = _enrollmentSettings?['deadline'] ?? "No date configured";

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isOpen ? success.withOpacity(0.3) : Colors.white10),
          boxShadow: [
            if (isOpen)
              BoxShadow(
                  color: success.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0)
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: (isOpen ? success : aViolet).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(isOpen ? LucideIcons.userPlus : LucideIcons.userX,
                color: isOpen ? success : aViolet, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Institutional Enrollment Gateway",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 18, color: text)),
              Text(
                  "Access: ${isOpen ? 'PUBLIC - Accepting Applications' : 'RESTRICTED - Closed'}",
                  style: TextStyle(
                      color: isOpen ? success : Colors.blueGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text("System Deadline: $deadline",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ]),
          ),
          _statusBadge(isOpen ? "OPEN" : "LOCKED",
              isOpen ? success : Colors.orangeAccent),
          const SizedBox(width: 16),
          _isActionLoading
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: isOpen,
                  activeThumbColor: success,
                  onChanged: (v) => _toggleGlobalEnrollment(v)),
        ],
      ),
    );
  }

  Widget _termCard(
      Map<String, dynamic> term, bool active, Color bg, Color text) {
    String start = term['start_date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(term['start_date']))
        : "TBA";
    String end = term['end_date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(term['end_date']))
        : "TBA";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? aViolet : Colors.white10, width: active ? 2 : 1)),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(term['year_label'],
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900, fontSize: 18, color: text)),
            Text(term['semester_label'].toString().toUpperCase(),
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ]),
          const SizedBox(width: 48),
          _metaInfo("Term Commencement", start),
          const SizedBox(width: 24),
          _metaInfo("Planned Completion", end),
          const Spacer(),
          if (active) _statusBadge("CURRENTLY ACTIVE", success),
          const SizedBox(width: 20),
          _isActionLoading
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: active,
                  activeThumbColor: success,
                  onChanged: (v) => _toggleTermStatus(term['id'], v)),
        ],
      ),
    );
  }

  Widget _metaInfo(String l, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.toUpperCase(),
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(v,
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      );

  void _showAddTermDialog() {
    final yearCtl = TextEditingController(text: "2025-2026");
    String semester = "1st Semester";
    DateTimeRange? period;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(LucideIcons.calendarPlus, color: aViolet),
              const SizedBox(width: 12),
              Text("Provision New Term",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: yearCtl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Academic Year Label (e.g. 2026-2027)"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: semester,
                dropdownColor: surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Semester Type"),
                items: ["1st Semester", "2nd Semester", "Summer Term"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setModalState(() => semester = v!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                    builder: (context, child) => Theme(
                      data: widget.isDarkMode
                          ? ThemeData.dark()
                          : ThemeData.light(),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModalState(() => period = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar,
                          size: 18, color: aViolet),
                      const SizedBox(width: 12),
                      Text(
                          period == null
                              ? "Define Date Range"
                              : "${DateFormat('MM/dd/y').format(period!.start)} — ${DateFormat('MM/dd/y').format(period!.end)}",
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL")),
            ElevatedButton(
                onPressed: () async {
                  if (period == null) return;
                  try {
                    await _service.client.from('academic_terms').insert({
                      'year_label': yearCtl.text.trim(),
                      'semester_label': semester,
                      'start_date': period!.start.toIso8601String(),
                      'end_date': period!.end.toIso8601String(),
                      'is_active': false,
                      'status': 'Closed',
                      'updated_by': widget.userData['id']
                    });
                    if (mounted) Navigator.pop(context);
                    _refreshLifecycleData();
                    _showToast("Institutional Calendar Updated", success);
                  } catch (e) {
                    _showToast("Database Rejection: Check Constraints",
                        Colors.redAccent);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                child: const Text("SAVE TERM TO LEDGER")),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String h) => InputDecoration(
        labelText: h,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: aViolet)),
      );

  Widget _statusBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));

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
