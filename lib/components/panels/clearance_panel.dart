import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ClearancePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const ClearancePanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<ClearancePanel> createState() => _ClearancePanelState();
}

class _ClearancePanelState extends State<ClearancePanel> {
  String _selectedSemester = "2nd Semester 2025-2026";
  final List<String> _semesters = [
    "2nd Semester 2025-2026",
    "1st Semester 2025-2026",
    "Summer 2025",
  ];

  // --- MOCK CLEARANCE DATA ---
  final Map<String, List<Map<String, dynamic>>> _clearanceRecords = {
    "2nd Semester 2025-2026": [
      {
        "office": "Accounting Office",
        "status": "Cleared",
        "date": "2026-03-15",
        "officer": "Ms. J. Santos",
        "remarks": "Tuition fully paid",
      },
      {
        "office": "Library",
        "status": "Pending",
        "date": "-",
        "officer": "-",
        "remarks": "Unreturned book: 'Intro to AI'",
      },
      {
        "office": "Registrar",
        "status": "On Hold",
        "date": "-",
        "officer": "Mr. R. Diaz",
        "remarks": "Lacking Form 137",
      },
      {
        "office": "Program Chair",
        "status": "Cleared",
        "date": "2026-03-10",
        "officer": "Dr. A. Lim",
        "remarks": "Advising complete",
      },
      {
        "office": "Guidance Office",
        "status": "Cleared",
        "date": "2026-03-12",
        "officer": "Ms. L. Cruz",
        "remarks": "Interview done",
      },
      {
        "office": "Clinic",
        "status": "Pending",
        "date": "-",
        "officer": "-",
        "remarks": "Annual physical exam required",
      },
      {
        "office": "Student Affairs",
        "status": "Cleared",
        "date": "2026-03-14",
        "officer": "Mr. K. Tan",
        "remarks": "No violations",
      },
    ],
    "1st Semester 2025-2026": [
      {
        "office": "Accounting Office",
        "status": "Cleared",
        "date": "2025-10-20",
        "officer": "Ms. J. Santos",
        "remarks": "Paid",
      },
      {
        "office": "Library",
        "status": "Cleared",
        "date": "2025-10-18",
        "officer": "Ms. M. Go",
        "remarks": "No liabilities",
      },
      {
        "office": "Registrar",
        "status": "Cleared",
        "date": "2025-10-22",
        "officer": "Mr. R. Diaz",
        "remarks": "Complete",
      },
      {
        "office": "Program Chair",
        "status": "Cleared",
        "date": "2025-10-15",
        "officer": "Dr. A. Lim",
        "remarks": "Approved",
      },
      {
        "office": "Guidance Office",
        "status": "Cleared",
        "date": "2025-10-16",
        "officer": "Ms. L. Cruz",
        "remarks": "Done",
      },
      {
        "office": "Clinic",
        "status": "Cleared",
        "date": "2025-10-10",
        "officer": "Dr. S. Lee",
        "remarks": "Fit to enroll",
      },
      {
        "office": "Student Affairs",
        "status": "Cleared",
        "date": "2025-10-14",
        "officer": "Mr. K. Tan",
        "remarks": "Cleared",
      },
    ],
    "Summer 2025": [
      {
        "office": "Accounting Office",
        "status": "Cleared",
        "date": "2025-07-10",
        "officer": "Ms. J. Santos",
        "remarks": "Paid",
      },
    ],
  };

  List<Map<String, dynamic>> get _currentRecords =>
      _clearanceRecords[_selectedSemester] ?? [];
  int get _total => _currentRecords.length;
  int get _cleared =>
      _currentRecords.where((r) => r['status'] == 'Cleared').length;
  int get _pending =>
      _currentRecords.where((r) => r['status'] == 'Pending').length;
  int get _onHold =>
      _currentRecords.where((r) => r['status'] == 'On Hold').length;
  bool get _isFullyCleared => _cleared == _total && _total > 0;

  Future<void> _downloadCertificate() async {
    if (!_isFullyCleared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot generate certificate. Pending clearances exist.",
          ),
        ),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "CERTIFICATE OF CLEARANCE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "This is to certify that",
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                widget.studentData['name'].toString().toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.Text("Student ID: ${widget.studentData['id']}"),
              pw.SizedBox(height: 20),
              pw.Text(
                "has been CLEARED of all money and property responsibilities in this institution",
              ),
              pw.Text("for $_selectedSemester."),
              pw.SizedBox(height: 40),
              pw.Table.fromTextArray(
                headers: ["Office", "Status", "Date Cleared", "Officer"],
                data: _currentRecords
                    .map(
                      (r) => [
                        r['office'],
                        r['status'],
                        r['date'],
                        r['officer'],
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.Spacer(),
              pw.Text(
                "Generated on: ${DateTime.now().toString().split('.')[0]}",
              ),
              pw.Text("This is a system-generated document."),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/clearance_${widget.studentData['id']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  void _showAuditTrail(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E1B4B)
            : Colors.white,
        title: Text(
          "Audit Trail: ${record['office']}",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _auditRow("Status", record['status']),
            _auditRow(
              "Date Updated",
              record['date'] == '-' ? 'N/A' : record['date'],
            ),
            _auditRow(
              "Verified By",
              record['officer'] == '-'
                  ? 'Pending Assignment'
                  : record['officer'],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              "Remarks:",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
            Text(
              record['remarks'],
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _auditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
        _buildSemesterSelector(cardColor, textColor),
        const SizedBox(height: 24),
        _buildSummaryStats(cardColor, textColor),
        const SizedBox(height: 24),
        if (_pending > 0 || _onHold > 0) ...[
          _buildAlertBanner(),
          const SizedBox(height: 24),
        ],
        _buildClearanceTable(cardColor, textColor, subTextColor),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isFullyCleared ? _downloadCertificate : null,
            icon: const Icon(LucideIcons.download, size: 18),
            label: const Text("DOWNLOAD CERTIFICATE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF69F0AE),
              foregroundColor: const Color(0xFF1E1B4B),
              disabledBackgroundColor: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black12,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterSelector(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSemester,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: Icon(LucideIcons.chevronDown, color: textColor),
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) setState(() => _selectedSemester = newValue);
          },
          items: _semesters.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(Color cardColor, Color textColor) {
    return Row(
      children: [
        _statCard(
          "Cleared",
          _cleared.toString(),
          const Color(0xFF69F0AE),
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Pending",
          _pending.toString(),
          Colors.redAccent,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "On Hold",
          _onHold.toString(),
          Colors.orangeAccent,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    Color cardColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Action Required",
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "You have pending clearances. Please resolve them before the final exam week.",
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceTable(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      width: double.infinity,
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
          Text(
            "Clearance Status",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2), // Office
              1: FlexColumnWidth(1.2), // Status
              2: FlexColumnWidth(1.5), // Date
              3: FlexColumnWidth(0.5), // Action
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: subTextColor.withOpacity(0.1)),
                  ),
                ),
                children: [
                  _tableHeader("Office", subTextColor),
                  _tableHeader("Status", subTextColor, align: TextAlign.center),
                  _tableHeader(
                    "Date Cleared",
                    subTextColor,
                    align: TextAlign.center,
                  ),
                  _tableHeader("", subTextColor),
                ],
              ),
              ..._currentRecords.map((record) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: subTextColor.withOpacity(0.05)),
                    ),
                  ),
                  children: [
                    _tableCell(record['office'], textColor, isBold: true),
                    Center(child: _statusBadge(record['status'])),
                    _tableCell(
                      record['date'],
                      subTextColor,
                      align: TextAlign.center,
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.info,
                        size: 16,
                        color: subTextColor,
                      ),
                      onPressed: () => _showAuditTrail(record),
                      tooltip: "View Audit Trail",
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(
    String text,
    Color color, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text,
    Color color, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Cleared':
        color = const Color(0xFF69F0AE);
        break;
      case 'Pending':
        color = Colors.redAccent;
        break;
      case 'On Hold':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
