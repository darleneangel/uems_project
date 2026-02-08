import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class SubjectLoadPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const SubjectLoadPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<SubjectLoadPanel> createState() => _SubjectLoadPanelState();
}

class _SubjectLoadPanelState extends State<SubjectLoadPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedDayFilter = 'All';
  String _selectedSemester = "2nd Semester 2025-2026";
  final List<String> _semesters = [
    "2nd Semester 2025-2026",
    "1st Semester 2025-2026",
    "Summer 2025",
    "2nd Semester 2024-2025",
  ];

  // --- MOCK SUBJECT DATA ---
  final List<Map<String, dynamic>> subjects = [
    {
      "code": "ITCC 411",
      "title": "Systems Integration & Architecture",
      "units": 3,
      "faculty": "Prof. R. Manalastas",
      "schedule": "Mon/Wed 08:00AM - 09:30AM",
      "room": "CL 102",
      "status": "Approved",
      "desc":
          "Study of enterprise architecture frameworks and integration patterns.",
    },
    {
      "code": "ITCC 412",
      "title": "Information Assurance & Security",
      "units": 3,
      "faculty": "Dr. A. De Silva",
      "schedule": "Mon/Wed 10:00AM - 11:30AM",
      "room": "CL 103",
      "status": "Approved",
      "desc":
          "Fundamentals of information security, risk management, and compliance.",
    },
    {
      "code": "ITCP 413",
      "title": "Capstone Project 1",
      "units": 3,
      "faculty": "Prof. L. Bautista",
      "schedule": "Tue/Thu 01:00PM - 02:30PM",
      "room": "LAB 4",
      "status": "Approved",
      "desc": "Proposal stage of the capstone project for IT students.",
    },
    {
      "code": "ITEE 414",
      "title": "Mobile Applications Development",
      "units": 3,
      "faculty": "Prof. J. Cruz",
      "schedule": "Fri 08:00AM - 11:00AM",
      "room": "CL 101",
      "status": "Approved",
      "desc":
          "Development of applications for mobile devices using modern frameworks.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    return subjects.where((s) {
      final matchesSearch =
          s['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['code'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDay =
          _selectedDayFilter == 'All' ||
          s['schedule'].contains(_selectedDayFilter);
      return matchesSearch && matchesDay;
    }).toList();
  }

  // --- PDF EXPORT ENGINE ---
  Future<void> _exportStudyLoad(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                "OFFICIAL STUDENT STUDY LOAD",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Student: ${widget.studentData['name']} (${widget.studentData['id']})",
              ),
              pw.Text(
                "Program: ${widget.studentData['program']} | Block: BSCS-4A",
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Code", "Title", "Units", "Faculty", "Schedule"],
                data: subjects
                    .map(
                      (s) => [
                        s['code'],
                        s['title'],
                        s['units'],
                        s['faculty'],
                        s['schedule'],
                      ],
                    )
                    .toList(),
              ),
              pw.Spacer(),
              pw.Text(
                "Status: FINALIZED AND APPROVED",
                style: pw.TextStyle(
                  color: PdfColors.green,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text("Generated on: ${DateTime.now()}"),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/study_load_${widget.studentData['id']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSemesterSelector(textColor, cardColor),
        const SizedBox(height: 24),

        // 1. DASHBOARD SUMMARY HEADER
        _buildSummaryHeader(textColor, subTextColor),
        const SizedBox(height: 24),

        _buildSearchAndFilter(textColor, cardColor),
        const SizedBox(height: 24),

        // 2. INTERACTIVE TAB BAR
        _buildTabBar(textColor),
        const SizedBox(height: 24),

        // 3. MAIN CONTENT (SWITCHABLE)
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListView(cardColor, textColor, subTextColor),
              _buildTimetableView(cardColor, textColor, subTextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterSelector(Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ACADEMIC PERIOD",
                style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSemester,
                  dropdownColor: cardColor,
                  icon: Icon(
                    LucideIcons.chevronDown,
                    color: textColor,
                    size: 16,
                  ),
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSemester = newValue;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Retrieving schedule for $newValue...",
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      });
                    }
                  },
                  items: _semesters.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.history,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          _statItem(LucideIcons.layers, "Total Units", "12.0", textColor),
          _verticalDivider(),
          _statItem(
            LucideIcons.bookOpen,
            "Subjects",
            subjects.length.toString(),
            textColor,
          ),
          _verticalDivider(),
          _statItem(LucideIcons.layoutGrid, "Block", "BSCS-4A", textColor),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportStudyLoad(context),
            icon: const Icon(LucideIcons.printer, size: 16),
            label: const Text("PRINT LOAD"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color textColor, Color cardColor) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(color: textColor),
            decoration: InputDecoration(
              hintText: "Search subjects...",
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              prefixIcon: Icon(
                LucideIcons.search,
                color: textColor.withOpacity(0.5),
              ),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Mon", "Tue", "Wed", "Thu", "Fri"].map((day) {
                final isSelected = _selectedDayFilter == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDayFilter = day);
                    },
                    selectedColor: const Color(0xFF8B5CF6),
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : textColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _exportStudyLoad(context),
          icon: const Icon(LucideIcons.printer),
          color: textColor,
          tooltip: "Print Load",
        ),
      ],
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF8B5CF6),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: "DETAILED LIST"),
          Tab(text: "WEEKLY TIMETABLE"),
        ],
      ),
    );
  }

  Widget _buildListView(Color cardColor, Color textColor, Color subTextColor) {
    final filtered = _filteredSubjects;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "No subjects found.",
          style: TextStyle(color: subTextColor),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (context, index) =>
            Divider(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        itemBuilder: (context, index) {
          final sub = filtered[index];
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: Border.all(color: Colors.transparent),
            childrenPadding: const EdgeInsets.only(top: 16, bottom: 8),
            title: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.book,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub['code'],
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        sub['title'],
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub['faculty'],
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusBadge("APPROVED", const Color(0xFF69F0AE)),
                    const SizedBox(height: 8),
                    Text(
                      "${sub['units']} Units",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub['desc'] ?? "No description available.",
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimetableView(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "Class Schedule",
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: _filteredSubjects
                  .map((s) => _scheduleEntry(s, textColor, subTextColor))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleEntry(
    Map<String, dynamic> sub,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              sub['schedule'].split(' ')[0],
              style: GoogleFonts.inter(
                color: const Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['schedule'].split(' ')[1] +
                      " " +
                      sub['schedule'].split(' ')[2] +
                      " " +
                      sub['schedule'].split(' ')[3],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${sub['title']} • ${sub['room']}",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI ATOMS ---

  Widget _statItem(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(
    height: 30,
    width: 1,
    color: Colors.white10,
    margin: const EdgeInsets.symmetric(horizontal: 24),
  );

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E1B4B)
            : Colors.white,
        title: Text(
          "Add Subject",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          "This feature allows you to request additional subjects for your load. Approval is subject to the Program Chair.",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Proceed to Selection"),
          ),
        ],
      ),
    );
  }
}
