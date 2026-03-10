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

  // Form State for Pre-Registration
  String? _selectedCategory;
  String? _selectedProgram;
  bool _noMiddleName = false;
  String _selectedGender = "Male";
  DateTime? _selectedBirthDate;

  // Real Database Lists
  List<String> _dbCategories = [
    "New Student",
    "Transferee",
    "Cross Enrollee",
    "Returning Student"
  ];
  List<String> _dbPrograms = [];
  bool _isFetchingMasterData = false;

  // Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color accentCyan = Color(0xFF22D3EE);

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

  /// FETCH: Loads Courses/Programs from the real database
  Future<void> _loadMasterData() async {
    setState(() => _isFetchingMasterData = true);
    try {
      final client = SupabaseService().client;

      // Fetching programs from the 'courses' table
      final List<dynamic> courseData =
          await client.from('courses').select('name');

      if (mounted) {
        setState(() {
          _dbPrograms = courseData.map((c) => c['name'].toString()).toList();
          if (_dbPrograms.isEmpty) {
            _dbPrograms = ["No Programs Found in DB"];
          }
          _isFetchingMasterData = false;
        });
      }
    } catch (e) {
      debugPrint("Master Data Fetch Error: $e");
      if (mounted) setState(() => _isFetchingMasterData = false);
    }
  }

  /// 1. PRE-REGISTRATION: Save temporary record to 'applicants'
  Future<void> _handlePreRegistration(Map<String, dynamic> data) async {
    try {
      await SupabaseService().client.from('applicants').insert(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: success,
              content: Text("Applicant registered and added to directory.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text("Database Error: $e")),
        );
      }
    }
  }

  /// 2. UPDATE: Modify existing record in 'applicants'
  Future<void> _handleUpdateRegistration(
      String id, Map<String, dynamic> data) async {
    try {
      await SupabaseService()
          .client
          .from('applicants')
          .update(data)
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: success,
              content: Text("Applicant record updated successfully.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text("Update Error: $e")),
        );
      }
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
                if (!snapshot.hasData)
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));

                final list = snapshot.data!.where((a) {
                  final mSearch = a['full_name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase());
                  final mFilter = _filter == "All" || a['status'] == _filter;
                  return mSearch && mFilter;
                }).toList();

                if (list.isEmpty) return _emptyState(textColor);

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
              Text("Applicant Directory",
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: t,
                      letterSpacing: -1)),
              const Text("Manage temporary records for incoming students.",
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
                    hintText: "Search name or ID...",
                    prefixIcon: Icon(LucideIcons.search, color: aViolet),
                    border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _filterChip("All"),
          _filterChip("Pending"),
          _filterChip("For Payment"),
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
          IconButton(
              icon: const Icon(LucideIcons.edit3,
                  size: 18, color: Colors.blueGrey),
              onPressed: () => _showEditApplicationDialog(context, a)),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color c = Colors.orangeAccent;
    if (s == 'Verified' || s == 'Paid') c = success;
    if (s == 'For Payment') c = accentCyan;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(s.toUpperCase(),
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));
  }

  // --- PRE-REGISTRATION DIALOG ---

  void _showNewApplicationDialog(BuildContext context) {
    final TextEditingController surnameCtrl = TextEditingController();
    final TextEditingController givenNameCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();

    // Reset selection state for a fresh dialog session
    _selectedCategory = null;
    _selectedProgram = null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        const Icon(LucideIcons.school,
                            color: aViolet, size: 40),
                        const SizedBox(height: 24),
                        Text("Pre-Registration",
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: aViolet,
                                height: 1.1)),
                        const SizedBox(height: 16),
                        const Text(
                            "Create a temporary intake record for the Admissions pipeline.",
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                                height: 1.5)),
                        const Spacer(),
                        _stepIndicator(
                            "1", "Categorization", _selectedCategory != null),
                        _stepIndicator(
                            "2", "Academic Choice", _selectedProgram != null),
                        _stepIndicator("3", "Identity Details",
                            givenNameCtrl.text.isNotEmpty),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Applicant Metadata",
                                style: _sectionHeaderStyle()),
                            const SizedBox(height: 24),
                            // Real DB Dropdown: Categories
                            _buildDropdown(
                                "Entrance Category *",
                                _selectedCategory,
                                _dbCategories,
                                (v) => setDialogState(
                                    () => _selectedCategory = v)),
                            const SizedBox(height: 16),
                            // Real DB Dropdown: Programs (Courses)
                            _buildDropdown(
                                "Target Program *",
                                _selectedProgram,
                                _dbPrograms,
                                (v) =>
                                    setDialogState(() => _selectedProgram = v)),
                            const SizedBox(height: 32),
                            Text("Personal Identity",
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
                                      child: const Text("CANCEL",
                                          style: TextStyle(
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_selectedCategory == null ||
                                          _selectedProgram == null ||
                                          surnameCtrl.text.isEmpty) return;
                                      _handlePreRegistration({
                                        "application_no":
                                            "APL-2026-${100 + Random().nextInt(900)}",
                                        "full_name":
                                            "${givenNameCtrl.text.toUpperCase()} ${surnameCtrl.text.toUpperCase()}",
                                        "email": emailCtrl.text,
                                        "applicant_type": _selectedCategory,
                                        "target_program": _selectedProgram,
                                        "status": "Pending",
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: aViolet,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 18),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: const Text("INITIALIZE APPLICATION",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
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

  // --- EDIT REGISTRATION DIALOG ---

  void _showEditApplicationDialog(
      BuildContext context, Map<String, dynamic> applicant) {
    // Simple parsing logic to split full name back into Given Name and Surname
    final nameParts = applicant['full_name'].toString().split(' ');
    final String initialSurname = nameParts.length > 1 ? nameParts.last : "";
    final String initialGivenName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join(' ')
        : nameParts.first;

    final TextEditingController surnameCtrl =
        TextEditingController(text: initialSurname);
    final TextEditingController givenNameCtrl =
        TextEditingController(text: initialGivenName);
    final TextEditingController emailCtrl =
        TextEditingController(text: applicant['email'] ?? "");

    String? localCategory = applicant['applicant_type'];
    String? localProgram =
        applicant['target_program']; // Assumes column exists in DB

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        const Icon(LucideIcons.edit3, color: aViolet, size: 40),
                        const SizedBox(height: 24),
                        Text("Edit Record",
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: aViolet,
                                height: 1.1)),
                        const SizedBox(height: 16),
                        Text(
                            "Modifying details for ${applicant['application_no']}",
                            style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                                height: 1.5)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Applicant Metadata",
                                style: _sectionHeaderStyle()),
                            const SizedBox(height: 24),
                            _buildDropdown(
                                "Entrance Category *",
                                localCategory,
                                _dbCategories,
                                (v) => setDialogState(() => localCategory = v)),
                            const SizedBox(height: 16),
                            _buildDropdown(
                                "Target Program *",
                                localProgram,
                                _dbPrograms,
                                (v) => setDialogState(() => localProgram = v)),
                            const SizedBox(height: 32),
                            Text("Personal Identity",
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
                                      child: const Text("CANCEL",
                                          style: TextStyle(
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      _handleUpdateRegistration(
                                          applicant['id'], {
                                        "full_name":
                                            "${givenNameCtrl.text.toUpperCase()} ${surnameCtrl.text.toUpperCase()}",
                                        "email": emailCtrl.text,
                                        "applicant_type": localCategory,
                                        "target_program": localProgram,
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: aViolet,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 18),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: const Text("SAVE CHANGES",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
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

  // --- UI ATOMS ---
  Widget _field(String l, TextEditingController c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(l),
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
          String l, String? v, List<String> i, Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(l),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: v,
                    isExpanded: true,
                    hint: const Text("Select from database...",
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    items: i
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child:
                                Text(e, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: onChanged)))
      ]);

  Widget _stepIndicator(String n, String l, bool a) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        CircleAvatar(
            radius: 10,
            backgroundColor: a ? aViolet : Colors.blueGrey.withOpacity(0.2),
            child: Text(n,
                style: const TextStyle(fontSize: 10, color: Colors.white))),
        const SizedBox(width: 12),
        Text(l,
            style: TextStyle(
                fontSize: 12,
                color: a ? aViolet : Colors.blueGrey,
                fontWeight: a ? FontWeight.bold : FontWeight.normal))
      ]));
  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey,
          letterSpacing: 0.5));
  TextStyle _sectionHeaderStyle() => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: aViolet,
      letterSpacing: 1.5);
  Widget _emptyState(Color t) => Center(
      child: Text("No applicants found matching filter.",
          style: TextStyle(color: t.withOpacity(0.2))));
}
