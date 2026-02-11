import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ApplicantManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const ApplicantManagementPanel({super.key, required this.isDarkMode});

  @override
  State<ApplicantManagementPanel> createState() =>
      _ApplicantManagementPanelState();
}

class _ApplicantManagementPanelState extends State<ApplicantManagementPanel> {
  String _filter = "All";
  final TextEditingController _searchController = TextEditingController();

  // --- DATA STATE (The "Database") ---
  final List<Map<String, dynamic>> _applicants = [
    {
      "id": "APL-2026-001",
      "name": "SARAH JENKINS",
      "program": "BACHELOR OF SCIENCE IN COMPUTER ENGINEERING (BSCPE)",
      "category": "New Student",
      "status": "Pending Face-to-Face",
      "statusColor": Colors.orange,
      "score": null,
      "gender": "Female",
      "birthdate": "2005-05-12",
      "email": "sarah.j@example.com",
    },
    {
      "id": "APL-2026-004",
      "name": "MICHAEL CHEN",
      "program": "BACHELOR OF SCIENCE IN INFORMATION TECHNOLOGY",
      "category": "Transferee",
      "status": "For Interview",
      "statusColor": const Color(0xFF22D3EE), // accentCyan
      "score": "92%",
      "gender": "Male",
      "birthdate": "2004-11-20",
      "email": "m.chen@example.com",
    },
    {
      "id": "APL-2026-088",
      "name": "JESSICA ALBA",
      "program": "BACHELOR OF SCIENCE IN NURSING",
      "category": "Returning Student",
      "status": "Verified",
      "statusColor": const Color(0xFF69F0AE),
      "score": "85%",
      "gender": "Female",
      "birthdate": "2003-01-15",
      "email": "jessica.alba@example.com",
    },
  ];

  // --- FORM STATE ---
  String? _selectedCategory;
  String? _selectedProgram;
  bool _noMiddleName = false;
  String _selectedGender = "Male";
  DateTime? _selectedBirthDate;

  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color accentCyan = Color(0xFF22D3EE);

  final List<String> _categories = [
    "New Student",
    "Transferee",
    "Cross Enrollee",
    "Returning Student",
  ];
  final List<String> _programs = [
    "BACHELOR OF ARTS IN COMMUNICATIONS",
    "BACHELOR OF SCIENCE IN ACCOUNTANCY",
    "BACHELOR OF SCIENCE IN BUSINESS ADMINISTRATION (FINANCIAL MANAGEMENT)",
    "BACHELOR OF SCIENCE IN BUSINESS ADMINISTRATION (MARKETING MANAGEMENT)",
    "BACHELOR OF SCIENCE IN COMPUTER ENGINEERING (BSCPE)",
    "BACHELOR OF SCIENCE IN CRIMINOLOGY",
    "BACHELOR OF SCIENCE IN ELECTRONICS ENGINEERING",
    "BACHELOR OF SCIENCE IN HOSPITALITY MANAGEMENT",
    "BACHELOR OF SCIENCE IN INDUSTRIAL ENGINEERING",
    "BACHELOR OF SCIENCE IN INFORMATION TECHNOLOGY",
    "BACHELOR OF SCIENCE IN MANAGEMENT ACCOUNTING",
    "BACHELOR OF SCIENCE IN NURSING",
    "BACHELOR OF SCIENCE IN PSYCHOLOGY",
    "BACHELOR IN SCIENCE IN TOURISM",
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CRUD OPERATIONS ---

  void _addApplicant(Map<String, dynamic> data) {
    setState(() {
      _applicants.insert(0, data);
    });
  }

  void _updateApplicant(String id, Map<String, dynamic> newData) {
    setState(() {
      int index = _applicants.indexWhere((a) => a['id'] == id);
      if (index != -1) _applicants[index] = newData;
    });
  }

  void _deleteApplicant(String id) {
    setState(() {
      _applicants.removeWhere((a) => a['id'] == id);
    });
  }

  void _updateStatus(String id, String status, Color color) {
    setState(() {
      int index = _applicants.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        _applicants[index]['status'] = status;
        _applicants[index]['statusColor'] = color;
      }
    });
  }

  // --- FILTER LOGIC ---

  List<Map<String, dynamic>> _getFilteredList() {
    final query = _searchController.text.toUpperCase();
    return _applicants.where((a) {
      final matchesSearch =
          a['name'].toString().contains(query) ||
          a['id'].toString().contains(query);
      final matchesFilter = _filter == "All" || a['status'] == _filter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final List<Map<String, dynamic>> filteredList = _getFilteredList();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernHeader(textColor),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Search by Name or Application ID...",
                      hintStyle: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: aViolet,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildModernSegmentedFilter(),
              const SizedBox(width: 20),
              _buildNewAppButton(),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(textColor)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final a = filteredList[index];
                      return _buildApplicantCard(
                        id: a['id'],
                        name: a['name'],
                        program: a['program'],
                        category: a['category'],
                        status: a['status'],
                        statusColor: a['statusColor'],
                        cardColor: cardColor,
                        textColor: textColor,
                        score: a['score'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(Color textColor) {
    int interviewCount = _applicants
        .where((a) => a['status'] == "For Interview")
        .length;
    int pendingExams = _applicants
        .where((a) => a['status'] == "Pending Exam")
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Admissions Pipeline",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            const Text(
              "Manage, evaluate, and transition incoming applicants.",
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _headerStat("Total Intake", _applicants.length.toString(), aViolet),
            _headerVerticalDivider(),
            _headerStat("Active Tests", pendingExams.toString(), Colors.amber),
            _headerVerticalDivider(),
            _headerStat(
              "Interviews",
              interviewCount.toString().padLeft(2, '0'),
              accentCyan,
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerVerticalDivider() =>
      Container(height: 30, width: 1, color: Colors.white10);

  Widget _buildModernSegmentedFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ["All", "For Interview", "Verified"].map((label) {
          bool isSelected = _filter == label;
          return GestureDetector(
            onTap: () => setState(() => _filter = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? aViolet : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: aViolet.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewAppButton() {
    return ElevatedButton.icon(
      onPressed: () => _showNewApplicationDialog(context),
      icon: const Icon(LucideIcons.plus, size: 18),
      label: const Text("NEW APPLICATION"),
      style: ElevatedButton.styleFrom(
        backgroundColor: aViolet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildApplicantCard({
    required String id,
    required String name,
    required String program,
    required String category,
    required String status,
    required Color statusColor,
    required Color cardColor,
    required Color textColor,
    String? score,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [aViolet.withOpacity(0.2), aViolet.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: aViolet,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _badge(category, aViolet.withOpacity(0.1), aViolet),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  program,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoTag(LucideIcons.fingerprint, id),
                    const SizedBox(width: 16),
                    if (score != null)
                      _infoTag(LucideIcons.barChart, "Score: $score"),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusBadge(status, statusColor),
              const SizedBox(height: 16),
              Row(
                children: [
                  _actionButton(
                    LucideIcons.calendar,
                    Colors.blue,
                    "Schedule",
                    () => _updateStatus(id, "Pending Exam", Colors.amber),
                  ),
                  _actionButton(
                    LucideIcons.mic,
                    Colors.orange,
                    "Interview",
                    () => _updateStatus(id, "For Interview", accentCyan),
                  ),
                  if (status == "For Interview")
                    _actionButton(
                      LucideIcons.checkCircle,
                      Colors.green,
                      "Complete",
                      () {
                        _updateStatus(
                          id,
                          "Ready for Admission",
                          const Color(0xFF69F0AE),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Interview completed. Data synced for Registrar transfer.",
                            ),
                          ),
                        );
                      },
                    ),
                  _actionButton(
                    LucideIcons.edit3,
                    Colors.blueGrey,
                    "Edit",
                    () {},
                  ),
                  _actionButton(
                    LucideIcons.trash2,
                    Colors.redAccent,
                    "Delete",
                    () => _confirmDelete(id, name),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CRUD DIALOGS & MODALS ---

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? surfaceDark : Colors.white,
        title: const Text("Confirm Deletion"),
        content: Text(
          "Are you sure you want to remove $name from the pipeline? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteApplicant(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  void _showNewApplicationDialog(BuildContext context) {
    final TextEditingController surnameCtrl = TextEditingController();
    final TextEditingController givenNameCtrl = TextEditingController();
    final TextEditingController mobileCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: widget.isDarkMode
                ? const Color(0xFF0F071D)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 850,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
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
                        bottomLeft: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.school,
                          color: aViolet,
                          size: 40,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Admission\nGateway",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: aViolet,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Ensure all legal names match birth certificates for automated registrar syncing.",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        _stepIndicator(
                          "1",
                          "Categorization",
                          _selectedCategory != null,
                        ),
                        _stepIndicator(
                          "2",
                          "Program Choice",
                          _selectedProgram != null,
                        ),
                        _stepIndicator("3", "Personal Data", false),
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
                            Text(
                              "Student Categorization",
                              style: _sectionHeaderStyle(),
                            ),
                            const SizedBox(height: 24),
                            _buildFormLabel("Entrance Category *"),
                            _buildDropdown(
                              value: _selectedCategory,
                              items: _categories,
                              hint: "Identify student type",
                              onChanged: (val) =>
                                  setDialogState(() => _selectedCategory = val),
                              textColor: textColor,
                            ),
                            if (_selectedCategory == "Returning Student") ...[
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                "Previous Student ID *",
                                LucideIcons.hash,
                              ),
                            ],
                            const SizedBox(height: 32),
                            Text("Academic Path", style: _sectionHeaderStyle()),
                            const SizedBox(height: 24),
                            _buildFormLabel("Target Program *"),
                            _buildDropdown(
                              value: _selectedProgram,
                              items: _programs,
                              hint: "Select degree program",
                              onChanged: (val) =>
                                  setDialogState(() => _selectedProgram = val),
                              textColor: textColor,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              "Identity Details",
                              style: _sectionHeaderStyle(),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    "Surname *",
                                    LucideIcons.user,
                                    controller: surnameCtrl,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    "Given Name *",
                                    LucideIcons.user,
                                    controller: givenNameCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    "Middle Name",
                                    LucideIcons.user,
                                    enabled: !_noMiddleName,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: _noMiddleName,
                                    activeColor: aViolet,
                                    onChanged: (v) => setDialogState(
                                      () => _noMiddleName = v!,
                                    ),
                                  ),
                                ),
                                const Text(
                                  "N/A",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: _buildModernTextField(
                                    "Suffix",
                                    LucideIcons.chevronRight,
                                    hint: "Jr.",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGenderToggle(setDialogState),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildDatePicker(setDialogState),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildModernTextField(
                              "Email Address *",
                              LucideIcons.mail,
                              controller: emailCtrl,
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "DISCARD",
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_selectedCategory == null ||
                                        _selectedProgram == null ||
                                        surnameCtrl.text.isEmpty) {
                                      return;
                                    }
                                    final newApp = {
                                      "id":
                                          "APL-2026-${100 + Random().nextInt(900)}",
                                      "name":
                                          "${givenNameCtrl.text.toUpperCase()} ${surnameCtrl.text.toUpperCase()}",
                                      "program": _selectedProgram,
                                      "category": _selectedCategory,
                                      "status": "Pending Face-to-Face",
                                      "statusColor": Colors.orange,
                                      "score": null,
                                      "gender": _selectedGender,
                                      "email": emailCtrl.text,
                                    };
                                    _addApplicant(newApp);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: aViolet,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "INITIALIZE APPLICATION",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  // --- INTERNAL UI ATOMS ---

  Widget _stepIndicator(String num, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: active
                ? aViolet
                : Colors.blueGrey.withOpacity(0.2),
            child: Text(
              num,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? aViolet : Colors.blueGrey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    String label,
    IconData icon, {
    String? hint,
    bool enabled = true,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 16, color: aViolet.withOpacity(0.5)),
            filled: true,
            fillColor: widget.isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderToggle(Function setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel("GENDER *"),
        const SizedBox(height: 8),
        Row(
          children: ["Male", "Female"].map((g) {
            bool sel = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setDialogState(() => _selectedGender = g),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? aViolet.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(color: sel ? aViolet : Colors.white10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      g,
                      style: TextStyle(
                        color: sel ? aViolet : Colors.blueGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(Function setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel("BIRTHDATE *"),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime(2005),
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
            );
            if (d != null) setDialogState(() => _selectedBirthDate = d);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: aViolet),
                const SizedBox(width: 10),
                Text(
                  _selectedBirthDate == null
                      ? "Select Date"
                      : "${_selectedBirthDate!.month}/${_selectedBirthDate!.day}/${_selectedBirthDate!.year}",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          isExpanded: true,
          dropdownColor: widget.isDarkMode ? surfaceDark : Colors.white,
          style: TextStyle(fontSize: 13, color: textColor),
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: aViolet.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No results found for your search/filter.",
            style: TextStyle(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      color: Colors.blueGrey,
      letterSpacing: 0.5,
    ),
  );
  TextStyle _sectionHeaderStyle() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: aViolet,
    letterSpacing: 1.5,
  );

  Widget _badge(String t, Color bg, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
  Widget _statusBadge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.withOpacity(0.2)),
    ),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
  Widget _infoTag(IconData i, String t) => Row(
    children: [
      Icon(i, size: 12, color: Colors.blueGrey),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
    ],
  );
  Widget _actionButton(
    IconData i,
    Color c,
    String tooltip,
    VoidCallback onTap,
  ) => Container(
    margin: const EdgeInsets.only(left: 8),
    child: IconButton(
      icon: Icon(i, color: c.withOpacity(0.6), size: 18),
      tooltip: tooltip,
      onPressed: onTap,
    ),
  );
}
