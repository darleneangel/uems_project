import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class CurriculumReviewPanel extends StatefulWidget {
  final bool isDarkMode;
  const CurriculumReviewPanel({super.key, required this.isDarkMode});

  @override
  State<CurriculumReviewPanel> createState() => _CurriculumReviewPanelState();
}

class _CurriculumReviewPanelState extends State<CurriculumReviewPanel> {
  final TextEditingController _searchController = TextEditingController();

  // Controllers for Manual Subject Input
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();

  int _activeStep = 0; // 0: Queue, 1: Loading, 2: Review, 3: Accounting Sync
  Map<String, dynamic>? _selectedStudent; // Used for single mode
  final Set<String> _selectedStudentIds = {}; // Used for bulk mode

  // --- DROPDOWN SELECTIONS ---
  String? _selectedSubject;
  String? _selectedFaculty;
  String? _selectedBlock;
  String? _selectedDay;
  String? _selectedTime;
  String? _selectedTemplate;

  // --- MOCK DATA LISTS ---
  final List<String> _facultyList = [
    "Prof. R. Manalastas",
    "Dr. A. De Silva",
    "Prof. L. Bautista",
    "Prof. J. Cruz",
    "TBA",
  ];

  final List<Map<String, String>> _subjectCatalog = [
    {
      "code": "ITCC 411",
      "title": "Systems Integration & Architecture",
      "units": "3.0",
    },
    {
      "code": "ITCC 412",
      "title": "Information Assurance & Security",
      "units": "3.0",
    },
    {"code": "ITCP 413", "title": "Capstone Project 1", "units": "3.0"},
    {
      "code": "ITEE 414",
      "title": "Mobile Applications Development",
      "units": "3.0",
    },
    {"code": "CUSTOM", "title": "Add Custom Subject...", "units": "0.0"},
  ];

  final List<String> _blockList = [
    "BSCS-4A",
    "BSCS-4B",
    "BSIT-3A",
    "BSIT-3B",
    "IRREGULAR",
  ];
  final List<String> _daysList = [
    "M/W",
    "T/TH",
    "MON",
    "TUE",
    "WED",
    "THU",
    "FRI",
    "SAT",
  ];
  final List<String> _timeSlots = [
    "07:30 AM - 09:00 AM",
    "09:00 AM - 10:30 AM",
    "10:30 AM - 12:00 PM",
    "01:00 PM - 02:30 PM",
    "02:30 PM - 04:00 PM",
    "04:00 PM - 05:30 PM",
    "08:00 AM - 11:00 AM",
    "01:00 PM - 04:00 PM",
    "05:30 PM - 08:30 PM",
  ];

  // --- TEMPLATE ENGINE ---
  final Map<String, List<Map<String, dynamic>>> _savedTemplates = {
    "BSCS 4th Year - Core": [
      {
        "code": "ITCC 411",
        "title": "Systems Integration",
        "units": "3.0",
        "faculty": "Prof. R. Manalastas",
        "block": "BSCS-4A",
        "timeDay": "M/W 08:00 AM - 09:30 AM",
      },
      {
        "code": "ITCC 412",
        "title": "Information Security",
        "units": "3.0",
        "faculty": "Dr. A. De Silva",
        "block": "BSCS-4A",
        "timeDay": "M/W 10:30 AM - 12:00 PM",
      },
      {
        "code": "ITCP 413",
        "title": "Capstone 1",
        "units": "3.0",
        "faculty": "Prof. L. Bautista",
        "block": "BSCS-4A",
        "timeDay": "T/TH 01:00 PM - 02:30 PM",
      },
    ],
  };

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  // --- WORKFLOW DATA STATE ---
  final List<Map<String, dynamic>> _enrollmentQueue = [
    {
      "id": "2024-00001",
      "name": "DARLENE ANGEL",
      "program": "BS Computer Science",
      "year": "4th Year",
      "status": "Ready",
      "step": 0,
    },
    {
      "id": "2024-00005",
      "name": "MICHAEL CHEN",
      "program": "BS Information Technology",
      "year": "3rd Year",
      "status": "Ready",
      "step": 0,
    },
    {
      "id": "2024-00012",
      "name": "SARAH JENKINS",
      "program": "BS Computer Science",
      "year": "4th Year",
      "status": "Ready",
      "step": 0,
    },
    {
      "id": "2024-00015",
      "name": "JUAN DELA CRUZ",
      "program": "BS Computer Science",
      "year": "4th Year",
      "status": "Ready",
      "step": 0,
    },
  ];

  List<Map<String, dynamic>> _assignedSubjects = [];
  double get _totalUnits => _assignedSubjects.fold(
    0.0,
    (sum, item) => sum + (double.tryParse(item['units'].toString()) ?? 0.0),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    _titleController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  // --- PDF GENERATION ENGINE ---
  Future<void> _generateAndSendSubjectLoad() async {
    if (_assignedSubjects.isEmpty) return;

    final targetIds = _selectedStudentIds.isNotEmpty
        ? _selectedStudentIds.toList()
        : [_selectedStudent!['id']];

    // In a real app, this would loop and generate multiple or a merged PDF
    // For this demo, we simulate the processing for all selected students
    final studentName = _selectedStudentIds.length > 1
        ? "Selected Batch (${_selectedStudentIds.length} Students)"
        : _selectedStudent!['name'];

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "OFFICE OF THE PROGRAM CHAIR",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                "OFFICIAL STUDY LOAD",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text("Target: $studentName"),
              pw.SizedBox(height: 25),
              pw.Table.fromTextArray(
                headers: [
                  "Code",
                  "Subject Title",
                  "Units",
                  "Professor",
                  "Schedule",
                ],
                data: _assignedSubjects
                    .map(
                      (s) => [
                        s['code'],
                        s['title'],
                        s['units'],
                        s['faculty'],
                        "${s['timeDay']} (${s['block']})",
                      ],
                    )
                    .toList(),
              ),
              pw.Spacer(),
              pw.Text(
                "Validated by: PROGRAM_CHAIR_DIGITAL_SIG",
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/StudyLoad_Batch.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      setState(() => _activeStep = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success,
          content: Text("Study Load for $studentName finalized and synced."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text("Error: $e")),
      );
    }
  }

  void _addSubjectManually() {
    String code, title, units;
    if (_selectedSubject == "CUSTOM") {
      code = _codeController.text.toUpperCase();
      title = _titleController.text;
      units = _unitsController.text;
    } else {
      final sub = _subjectCatalog.firstWhere(
        (s) => s['code'] == _selectedSubject,
      );
      code = sub['code']!;
      title = sub['title']!;
      units = sub['units']!;
    }

    if (code.isEmpty ||
        title.isEmpty ||
        units.isEmpty ||
        _selectedFaculty == null ||
        _selectedBlock == null ||
        _selectedDay == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all subject details.")),
      );
      return;
    }

    setState(() {
      _assignedSubjects.add({
        "code": code,
        "title": title,
        "units": units,
        "faculty": _selectedFaculty,
        "block": _selectedBlock,
        "timeDay": "$_selectedDay $_selectedTime",
      });
      _codeController.clear();
      _titleController.clear();
      _unitsController.clear();
      _selectedSubject = null;
      _selectedFaculty = null;
      _selectedBlock = null;
      _selectedDay = null;
      _selectedTime = null;
    });
  }

  void _applyTemplate(String templateName) {
    setState(() {
      _assignedSubjects = List<Map<String, dynamic>>.from(
        _savedTemplates[templateName]!,
      );
      _selectedTemplate = templateName;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Applied '$templateName' load to current session."),
      ),
    );
  }

  void _saveCurrentAsTemplate() {
    if (_assignedSubjects.isEmpty) return;
    TextEditingController templateNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text(
          "Save as General Load Template",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: templateNameCtrl,
          decoration: const InputDecoration(
            hintText: "Template Name (e.g. BSCS-4A Standard)",
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (templateNameCtrl.text.isNotEmpty) {
                setState(
                  () => _savedTemplates[templateNameCtrl.text] = List.from(
                    _assignedSubjects,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("General load template saved.")),
                );
              }
            },
            child: const Text("SAVE TEMPLATE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color bgColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            "Academic Command Center",
            "Facilitating the workflow from Subject Assignment to Accounting Integration.",
            textColor,
          ),
          const SizedBox(height: 32),
          _buildWorkflowStepper(textColor),
          const SizedBox(height: 32),
          _buildFilterBar(textColor),
          const SizedBox(height: 24),
          _buildActiveModuleContent(textColor, bgColor),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
          ],
        ),
        _headerActionButton(LucideIcons.shieldCheck, "Policy Audit", aViolet),
      ],
    );
  }

  Widget _buildWorkflowStepper(Color textColor) {
    final steps = [
      "Student Queue",
      "Subject Loading",
      "Curriculum Review",
      "Finance Handover",
    ];
    return Row(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index < _activeStep;
        bool isActive = index == _activeStep;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeStep = index),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? success
                        : (isActive ? aViolet : Colors.white10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            LucideIcons.check,
                            color: Colors.black,
                            size: 16,
                          )
                        : Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.isDarkMode || isActive)
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive ? aViolet : Colors.blueGrey,
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                if (index != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? success.withOpacity(0.3)
                          : Colors.white10,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActiveModuleContent(Color textColor, Color bgColor) {
    switch (_activeStep) {
      case 0:
        return _buildStudentQueue(textColor, bgColor);
      case 1:
        return _buildSubjectLoadingInterface(textColor, bgColor);
      case 2:
        return _buildReviewModule(textColor, bgColor);
      case 3:
        return _buildAccountingHandover(textColor, bgColor);
      default:
        return _buildStudentQueue(textColor, bgColor);
    }
  }

  // --- MODULE: STUDENT ENROLLMENT QUEUE (WITH MULTI-SELECT) ---
  Widget _buildStudentQueue(Color textColor, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedStudentIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _activeStep = 1),
              icon: const Icon(LucideIcons.users, size: 18),
              label: Text(
                "BULK ASSIGN SUBJECTS TO ${_selectedStudentIds.length} STUDENTS",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ..._enrollmentQueue.map((student) {
          bool isSelected = _selectedStudentIds.contains(student['id']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? aViolet : Colors.white10),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: aViolet,
                  onChanged: (val) {
                    setState(() {
                      if (val!) {
                        _selectedStudentIds.add(student['id']);
                      } else {
                        _selectedStudentIds.remove(student['id']);
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${student['id']} • ${student['year']} • ${student['program']}",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStudent = student;
                      _selectedStudentIds.clear();
                      _activeStep = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet.withOpacity(0.1),
                    foregroundColor: aViolet,
                    elevation: 0,
                  ),
                  child: const Text(
                    "Single Assign",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- MODULE: SUBJECT & FACULTY LOADING (WITH TEMPLATES) ---
  Widget _buildSubjectLoadingInterface(Color textColor, Color bgColor) {
    final modeText = _selectedStudentIds.isNotEmpty
        ? "BATCH MODE (${_selectedStudentIds.length} Students)"
        : "SINGLE MODE: ${_selectedStudent?['name']}";

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Subject Load Configuration",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    modeText,
                    style: const TextStyle(
                      color: aViolet,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _badge("WORKFLOW ACTIVE", aViolet),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Load from General Template",
                  _selectedTemplate,
                  _savedTemplates.keys.toList(),
                  (val) => _applyTemplate(val!),
                  hint: "Select saved general load...",
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _saveCurrentAsTemplate,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text("SAVE AS NEW TEMPLATE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: aViolet,
                  side: const BorderSide(color: aViolet),
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "OR ADD MANUALLY",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  "Subject",
                  _selectedSubject,
                  _subjectCatalog.map((s) => s['code']!).toList(),
                  (v) => setState(() => _selectedSubject = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  "Professor",
                  _selectedFaculty,
                  _facultyList,
                  (v) => setState(() => _selectedFaculty = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  "Day",
                  _selectedDay,
                  _daysList,
                  (v) => setState(() => _selectedDay = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  "Time",
                  _selectedTime,
                  _timeSlots,
                  (v) => setState(() => _selectedTime = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  "Block",
                  _selectedBlock,
                  _blockList,
                  (v) => setState(() => _selectedBlock = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _addSubjectManually,
                icon: const Icon(
                  LucideIcons.plusCircle,
                  color: success,
                  size: 36,
                ),
              ),
            ],
          ),
          if (_selectedSubject == "CUSTOM") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildManualTextField(
                    _codeController,
                    "Code",
                    textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildManualTextField(
                    _titleController,
                    "Title",
                    textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildManualTextField(
                    _unitsController,
                    "Units",
                    textColor,
                    isNumber: true,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
          Text(
            "ASSIGNED SUBJECTS",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          if (_assignedSubjects.isEmpty)
            Center(
              child: Text(
                "No subjects assigned.",
                style: TextStyle(color: textColor.withOpacity(0.3)),
              ),
            )
          else
            ...List.generate(
              _assignedSubjects.length,
              (index) =>
                  _subjectEntryRow(index, _assignedSubjects[index], textColor),
            ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Total Units: ${_totalUnits.toStringAsFixed(1)}",
                style: GoogleFonts.orbitron(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: _assignedSubjects.isEmpty
                    ? null
                    : () => setState(() => _activeStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("VALIDATE & REVIEW"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewModule(Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Curriculum Compliance Audit",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _auditItem("Pre-requisite Validation", true),
          _auditItem("Faculty Workload Balancing", true),
          _auditItem("Schedule Collision Audit", true),
          _auditItem("Policy Compliance (No Overloads)", _totalUnits <= 24),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateAndSendSubjectLoad,
              icon: const Icon(LucideIcons.fileSignature, size: 18),
              label: const Text("APPROVE & SEND TO ACCOUNTING"),
              style: ElevatedButton.styleFrom(
                backgroundColor: success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingHandover(Color textColor, Color bgColor) {
    return Center(
      child: Column(
        children: [
          const Icon(LucideIcons.refreshCw, color: success, size: 64),
          const SizedBox(height: 24),
          Text(
            "Sync Active: Forwarding to Accounting",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "The validated load templates have been transmitted to the Finance Portal for immediate fee assessment.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 40),
          _headerActionButton(
            LucideIcons.fileText,
            "Batch Billing Draft",
            Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  // --- UI ATOMS ---
  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint ?? "Select Option",
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              isExpanded: true,
              dropdownColor: surfaceDark,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontSize: 13,
              ),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualTextField(
    TextEditingController ctrl,
    String hint,
    Color textColor, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subjectEntryRow(
    int index,
    Map<String, dynamic> sub,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.book, size: 16, color: aViolet),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['code'],
                  style: const TextStyle(
                    color: aViolet,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  sub['title'],
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FACULTY",
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  sub['faculty'],
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SCHEDULE",
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "${sub['timeDay']} (${sub['block']})",
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _assignedSubjects.removeAt(index)),
            icon: const Icon(
              LucideIcons.trash2,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditItem(String label, bool passed) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(
          passed ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
          color: passed ? success : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.blueGrey)),
        const Spacer(),
        Text(
          passed ? "PASSED" : "REVIEW NEEDED",
          style: TextStyle(
            color: passed ? success : Colors.orange,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildFilterBar(Color textColor) => Container(
    decoration: BoxDecoration(
      color: widget.isDarkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.02),
      borderRadius: BorderRadius.circular(16),
    ),
    child: TextField(
      controller: _searchController,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: const InputDecoration(
        hintText: "Search enrollment queue by student ID or name...",
        hintStyle: TextStyle(color: Colors.blueGrey),
        prefixIcon: Icon(LucideIcons.search, size: 18, color: aViolet),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 15),
      ),
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );

  Widget _headerActionButton(IconData icon, String label, Color color) =>
      OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}
