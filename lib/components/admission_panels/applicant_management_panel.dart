import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class ApplicantManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const ApplicantManagementPanel({super.key, required this.isDarkMode});

  @override
  State<ApplicantManagementPanel> createState() =>
      _ApplicantManagementPanelState();
}

class _ApplicantManagementPanelState extends State<ApplicantManagementPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = "All";

  // Real Database Lists (Map stored as: {'id': 'UUID', 'name': 'Course Name'})
  List<Map<String, String>> _dbPrograms = [];
  final List<String> _dbCategories = [
    "New Student",
    "Transferee",
    "Cross Enrollee",
    "Returning Student"
  ];

  bool _isFetchingMasterData = false;

  // Form State for Dialogs
  String? _selectedCategoryId;
  String? _selectedCourseId;

  // Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// DATABASE: Loads Courses from the 'courses' table to populate the form
  Future<void> _loadMasterData() async {
    setState(() => _isFetchingMasterData = true);
    try {
      final client = SupabaseService().client;
      final List<dynamic> courseData =
          await client.from('courses').select('id, name');

      if (mounted) {
        setState(() {
          _dbPrograms = courseData
              .map((c) =>
                  {'id': c['id'].toString(), 'name': c['name'].toString()})
              .toList();
          _isFetchingMasterData = false;
        });
      }
    } catch (e) {
      debugPrint("Master Data Fetch Error: $e");
      if (mounted) setState(() => _isFetchingMasterData = false);
    }
  }

  /// CREATE: Save pre-registration to 'applicants' table
  Future<void> _handlePreRegistration(Map<String, dynamic> data) async {
    try {
      await SupabaseService().client.from('applicants').insert(data);
      if (mounted) {
        _showToast("Intake Record Created Successfully.", success);
      }
    } catch (e) {
      if (mounted) _showToast("Database Sync Error: $e", Colors.redAccent);
    }
  }

  /// UPDATE: Modify status or details in 'applicants'
  Future<void> _handleUpdateStatus(String id, String newStatus) async {
    try {
      await SupabaseService()
          .client
          .from('applicants')
          .update({'status': newStatus}).eq('id', id);
      if (mounted) _showToast("Applicant status set to $newStatus.", aViolet);
    } catch (e) {
      if (mounted) _showToast("Update Failed: $e", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildControls(cardColor, textColor),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService().client.from('applicants').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }

                final list = snapshot.data!.where((a) {
                  final mSearch = a['full_name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase());
                  final mFilter = _filter == "All" || a['status'] == _filter;
                  return mSearch && mFilter;
                }).toList();

                if (list.isEmpty) return _buildEmptyState(textColor);

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _applicantCard(list[i], cardColor, textColor),
                );
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Applicant Intake Directory",
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: t,
                      letterSpacing: -1)),
              const Text(
                  "Consolidated view of pre-registration records awaiting verification.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isFetchingMasterData
                ? null
                : () => _showNewApplicationDialog(context),
            icon: _isFetchingMasterData
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.plusCircle, size: 18),
            label: Text(
                _isFetchingMasterData ? "SYNCING..." : "NEW PRE-REGISTRATION"),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          )
        ],
      );

  Widget _buildControls(Color bg, Color t) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                style: TextStyle(color: t),
                decoration: const InputDecoration(
                    hintText: "Search applicant by legal name...",
                    prefixIcon: Icon(LucideIcons.search, color: aViolet),
                    border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _filterChip("All"),
          _filterChip("Pending"),
          _filterChip("Verified"),
        ],
      );

  Widget _filterChip(String l) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(
          label: Text(l),
          selected: _filter == l,
          onSelected: (s) => setState(() => _filter = l),
          selectedColor: aViolet,
          labelStyle: TextStyle(
              color: _filter == l ? Colors.white : Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      );

  Widget _applicantCard(Map<String, dynamic> a, Color bg, Color t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: aViolet.withOpacity(0.1),
              child: Text(a['full_name'][0],
                  style: const TextStyle(
                      color: aViolet, fontWeight: FontWeight.bold))),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['full_name'],
                    style: TextStyle(
                        color: t, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("${a['application_no']} • ${a['applicant_type']}",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ],
            ),
          ),
          _statusBadge(a['status']),
          const SizedBox(width: 16),
          _actionMenu(a),
        ],
      ),
    );
  }

  Widget _actionMenu(Map<String, dynamic> a) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, color: Colors.blueGrey),
      color: surfaceDark,
      onSelected: (val) => _handleUpdateStatus(a['id'], val),
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'Pending',
            child:
                Text("Set to Pending", style: TextStyle(color: Colors.white))),
        const PopupMenuItem(
            value: 'Verified',
            child: Text("Set to Verified", style: TextStyle(color: success))),
      ],
    );
  }

  Widget _statusBadge(String s) {
    Color c =
        (s == 'Verified' || s == 'Admitted') ? success : Colors.orangeAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(s.toUpperCase(),
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));
  }

  // --- DIALOGS ---

  void _showNewApplicationDialog(BuildContext context) {
    final surnameCtrl = TextEditingController();
    final givenNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                widget.isDarkMode ? const Color(0xFF0F071D) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 850,
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                        color: aViolet.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            bottomLeft: Radius.circular(32))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.userPlus,
                            color: aViolet, size: 40),
                        const SizedBox(height: 24),
                        Text("Pre-Reg\nSystem",
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: aViolet,
                                height: 1.1)),
                        const Spacer(),
                        _step("Category", _selectedCategoryId != null),
                        _step("Program", _selectedCourseId != null),
                        _step("Identity", givenNameCtrl.text.isNotEmpty),
                      ],
                    ),
                  ),
                  // Form
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Database Provisioning",
                                style: _sectionHeaderStyle()),
                            const SizedBox(height: 24),
                            _buildLabel("Intake Classification *"),
                            _buildDropdown(
                                value: _selectedCategoryId,
                                items: _dbCategories,
                                onChanged: (v) => setDialogState(
                                    () => _selectedCategoryId = v)),
                            const SizedBox(height: 16),
                            _buildLabel("Target Course (from Courses Table) *"),
                            _buildMapDropdown(
                                value: _selectedCourseId,
                                items: _dbPrograms,
                                onChanged: (v) => setDialogState(
                                    () => _selectedCourseId = v)),
                            const SizedBox(height: 32),
                            Text("Legal Identity",
                                style: _sectionHeaderStyle()),
                            const SizedBox(height: 24),
                            Row(children: [
                              Expanded(child: _field("Surname *", surnameCtrl)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _field("Given Name *", givenNameCtrl)),
                            ]),
                            const SizedBox(height: 16),
                            _field("Email Address *", emailCtrl),
                            const SizedBox(height: 40),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("CANCEL")),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_selectedCategoryId == null ||
                                          _selectedCourseId == null ||
                                          surnameCtrl.text.isEmpty) return;
                                      _handlePreRegistration({
                                        "application_no":
                                            "APL-2026-${100 + Random().nextInt(900)}",
                                        "full_name":
                                            "${givenNameCtrl.text.toUpperCase()} ${surnameCtrl.text.toUpperCase()}",
                                        "email": emailCtrl.text,
                                        "applicant_type": _selectedCategoryId,
                                        "target_course_id":
                                            _selectedCourseId, // Mapped to UUID
                                        "status": "Pending",
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: aViolet,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 18)),
                                    child: const Text("INITIALIZE RECORD"),
                                  ),
                                ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _step(String l, bool a) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(a ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 14, color: a ? aViolet : Colors.blueGrey),
        const SizedBox(width: 12),
        Text(l,
            style: TextStyle(
                color: a ? aViolet : Colors.blueGrey,
                fontSize: 12,
                fontWeight: a ? FontWeight.bold : FontWeight.normal))
      ]));
  Widget _field(String l, TextEditingController c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextField(
            controller: c,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)))
      ]);

  Widget _buildDropdown(
      {required String? value,
      required List<String> items,
      required Function(String?) onChanged}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: onChanged)));
  }

  Widget _buildMapDropdown(
      {required String? value,
      required List<Map<String, String>> items,
      required Function(String?) onChanged}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e['id'],
                        child: Text(e['name']!,
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: onChanged)));
  }

  Widget _buildLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
              letterSpacing: 0.5)));
  TextStyle _sectionHeaderStyle() => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: aViolet,
      letterSpacing: 1.5);
  Widget _buildEmptyState(Color t) => Center(
      child: Text("No applicants found in the cloud directory.",
          style: TextStyle(color: t.withOpacity(0.2))));
  void _showToast(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}
