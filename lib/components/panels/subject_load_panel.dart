import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SubjectLoadPanelState extends State<SubjectLoadPanel> {
  static const Color aViolet = Color(0xFF7C3AED);
  static const Color success = Color(0xFF69F0AE);

  // --- DATA SOURCE ---
  final List<Map<String, dynamic>> subjects = [
    {
      "code": "IT210",
      "title": "Advanced Database Systems *",
      "room": "COMPLAB2",
      "days": "M.W.F",
      "time": "10:00AM-12:00PM",
      "units": "5 / 3.00",
      "section": "ABSIT3A",
    },
    {
      "code": "IT203",
      "title": "Quantitative Methods *",
      "room": "SJ204",
      "days": "F",
      "time": "01:00PM-06:00PM",
      "units": "3 / 3.00",
      "section": "ABSIT3A",
    },
    {
      "code": "IT217",
      "title": "System Integration and Architecture 2 *",
      "room": "COMPLAB1",
      "days": "M.T.TH",
      "time": "01:00PM-03:00PM",
      "units": "5 / 3.00",
      "section": "ABSIT3A",
    },
    {
      "code": "IT214",
      "title": "Information Assurance and Security 2 *",
      "room": "COMPLAB1",
      "days": "M.TH",
      "time": "09:00AM-10:30AM",
      "units": "5 / 3.00",
      "section": "BBSIT3A",
    },
    {
      "code": "IT218",
      "title": "Integrative Programming and Technologies 2 *",
      "room": "COMPLAB1",
      "days": "M.T.TH",
      "time": "03:00PM-05:00PM",
      "units": "5 / 3.00",
      "section": "BBSIT3A",
    },
    {
      "code": "IT302",
      "title": "IT Elective 2 *",
      "room": "COMPLAB2",
      "days": "W",
      "time": "01:00PM-04:00PM",
      "units": "5 / 3.00",
      "section": "WSBSIT3A",
    },
    {
      "code": "RF103",
      "title": "RECOLETOS FORMATION 3",
      "room": "GYM",
      "days": "W",
      "time": "05:00PM-06:00PM",
      "units": "1 / 1.00",
      "section": "WSBSIT3A",
    },
  ];

  final Map<String, String> studentHeaderInfo = {
    "Student Number": "202350031",
    "Course": "BSIT - BS INFORMATION TECHNOLOGY",
    "Level": "College Yr 3",
    "S.Y.": "2025-2026",
    "Name": "CUSTODIO, DARLENE ANGEL LUSTRE",
    "Semester": "2",
  };

  final Map<String, String> summaryFees = {
    "Tuition Fee": "P23,171.00",
    "Miscellaneous Fees": "P9,168.00",
    "Laboratory Fee": "P10,865.00",
    "Other Fees": "P1,680.00",
    "Total Fees": "P44,884.00",
  };

  final List<Map<String, String>> miscBreakdown = [
    {"name": "ATHLETICS AND SPORTS DEVELOPMENT FEE", "amount": "522.00"},
    {"name": "CEAP", "amount": "53.00"},
    {"name": "CULTURE AND ARTS", "amount": "279.00"},
    {"name": "DEVELOPMENT FEE", "amount": "423.00"},
    {"name": "EDUCATIONAL TECHNOLOGY FEE/AVR FEE", "amount": "1,164.00"},
    {"name": "FOUNDATION SHIRT", "amount": "450.00"},
    {"name": "FOUNDATION WEEK FEE", "amount": "212.00"},
    {"name": "GUIDANCE FEE", "amount": "774.00"},
    {"name": "INTERNET FEE", "amount": "247.00"},
    {"name": "LIBRARY FEE", "amount": "1,758.00"},
    {"name": "MEDICAL AND DENTAL", "amount": "627.00"},
    {"name": "ONE MANAGEMENT SYSTEM FEE", "amount": "265.00"},
    {"name": "OUTREACH FEE", "amount": "100.00"},
    {"name": "PLAGIARISM CHECKER FEE", "amount": "212.00"},
    {"name": "PUBLICATION FEE", "amount": "223.00"},
    {"name": "REAP", "amount": "200.00"},
    {"name": "REGISTRATION FEE", "amount": "469.00"},
    {"name": "RESEARCH FEE", "amount": "106.00"},
    {"name": "STUDENT ACTIVITY FEE", "amount": "375.00"},
    {"name": "SUPREME STUDENT COUNCIL", "amount": "106.00"},
    {"name": "TEST PAPERS", "amount": "524.00"},
    {"name": "WEB SERVICE FEE", "amount": "79.00"},
  ];

  final Map<String, String> otherFeesBreakdown = {
    "ENERGY FEE": "490.00",
    "INSURANCE": "0.00",
    "LEARNING MANAGEMENT SYSTEM": "1,190.00",
    "RECOLLECTION": "0.00",
    "RETREAT": "0.00",
  };

  // --- PDF EXPORT ENGINE ---
  Future<void> _exportStudyLoad(BuildContext context) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      // Path updated to assets/image/logo (2).png as requested
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // Fallback if the image cannot be found
      logoImage = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (pw.Context context) => _buildPdfHeader(brandViolet, logoImage),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 15),
            _buildPdfStudentInfoGrid(),
            pw.SizedBox(height: 20),
            pw.Text(
              "OFFICIAL COURSE LOAD & SCHEDULE",
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: brandViolet,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildPdfSubjectTable(brandViolet),
            pw.SizedBox(height: 25),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildPdfFinancialSummary(brandViolet),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 5,
                  child: _buildPdfMiscBreakdown(brandViolet),
                ),
              ],
            ),
            pw.SizedBox(height: 25),
            _buildPdfPaymentOptions(brandViolet),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "STATUS: FINALIZED & APPROVED",
                  style: pw.TextStyle(
                    color: PdfColors.green700,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  "System generated reference: $timestamp",
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/UEMSSP_Matriculation_${studentHeaderInfo['Student Number']}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PDF Generation Failed: $e")));
    }
  }

  // --- PDF BUILDERS ---
  pw.Widget _buildPdfHeader(PdfColor color, pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Container(
                width: 45,
                height: 45,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "U",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            pw.SizedBox(width: 15),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "UEMSSP",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: color,
                  ),
                ),
                pw.Text(
                  "UNIFIED EDUCATION MANAGEMENT SYSTEM AND STUDENT PORTAL",
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              "CERTIFICATE OF MATRICULATION",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "S.Y. ${studentHeaderInfo['S.Y.']} | Semester ${studentHeaderInfo['Semester']}",
              style: pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfStudentInfoGrid() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfMetaItem("FULL NAME", studentHeaderInfo['Name']!),
              ),
              pw.Expanded(
                child: _pdfMetaItem(
                  "STUDENT NUMBER",
                  studentHeaderInfo['Student Number']!,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfMetaItem(
                  "COURSE / PROGRAM",
                  studentHeaderInfo['Course']!,
                ),
              ),
              pw.Expanded(
                child: _pdfMetaItem("YEAR LEVEL", studentHeaderInfo['Level']!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetaItem(String label, String val) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSubjectTable(PdfColor color) {
    return pw.Table.fromTextArray(
      headers: [
        "CODE",
        "DESCRIPTION",
        "ROOM",
        "DAYS",
        "TIME",
        "HRS/UNITS",
        "SECTION",
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 7,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: color),
      cellStyle: pw.TextStyle(fontSize: 7),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2.5),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
      },
      data: subjects
          .map(
            (s) => [
              s['code'],
              s['title'],
              s['room'],
              s['days'],
              s['time'],
              s['units'],
              s['section'],
            ],
          )
          .toList(),
    );
  }

  pw.Widget _buildPdfFinancialSummary(PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "FEES SUMMARY",
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 8),
        ...summaryFees.entries.map(
          (e) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  e.key,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: e.key.contains("Total")
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  e.value,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: e.key.contains("Total")
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          "OTHER FEES BREAKDOWN",
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 0.5),
        ...otherFeesBreakdown.entries.map(
          (e) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key, style: pw.TextStyle(fontSize: 6.5)),
              pw.Text(e.value, style: pw.TextStyle(fontSize: 6.5)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfMiscBreakdown(PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "MISCELLANEOUS FEES ITEMIZATION",
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey200),
          ),
          child: pw.Column(
            children: miscBreakdown
                .map(
                  (m) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            m['name']!,
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                        pw.Text(
                          m['amount']!,
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfPaymentOptions(PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "CASH OPTION",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Fees:", style: pw.TextStyle(fontSize: 8)),
                    pw.Text("P44,884.00", style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Discount (Full):",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.Text(
                      "-P1,159.00",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL AMOUNT:",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "P43,725.00",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "INSTALLMENT OPTION",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
                pw.SizedBox(height: 5),
                _instRow("Upon Registration", "P15,000.00"),
                _instRow("Midterm A", "P7,470.00"),
                _instRow("Finals A", "P7,470.00"),
                _instRow("Midterm B", "P7,470.00"),
                _instRow("Finals B", "P7,474.00"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _instRow(String label, String val) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

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
        _buildSummaryHeader(textColor, subTextColor),
        const SizedBox(height: 24),

        // --- UNIFIED VIEW: SUBJECT TABLE + FINANCIAL BREAKDOWN ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Official Course Roster",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildSubjectTable(textColor, subTextColor),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Divider(color: Colors.white10),
              ),
              _buildFinancialSections(textColor, subTextColor),
            ],
          ),
        ),
      ],
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
          _statItem(LucideIcons.layers, "Total Units", "19.0", textColor),
          _verticalDivider(),
          _statItem(
            LucideIcons.bookOpen,
            "Subjects",
            subjects.length.toString(),
            textColor,
          ),
          _verticalDivider(),
          _statItem(LucideIcons.wallet, "Assessment", "P44,884.00", textColor),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportStudyLoad(context),
            icon: const Icon(LucideIcons.fileDown, size: 16),
            label: const Text("EXPORT OFFICIAL LOAD"),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW UNIFIED SUBJECT TABLE ---
  Widget _buildSubjectTable(Color textColor, Color subTextColor) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2.5),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: aViolet.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _tableHeaderCell("CODE"),
            _tableHeaderCell("DESCRIPTION"),
            _tableHeaderCell("ROOM"),
            _tableHeaderCell("DAYS/TIME"),
            _tableHeaderCell("UNITS"),
            _tableHeaderCell("BLOCK"),
          ],
        ),
        ...subjects
            .map(
              (s) => TableRow(
                children: [
                  _tableDataCell(
                    s['code'],
                    textColor,
                    isBold: true,
                    color: aViolet,
                  ),
                  _tableDataCell(s['title'], textColor),
                  _tableDataCell(s['room'], subTextColor),
                  _tableDataCell(
                    "${s['days']}\n${s['time']}",
                    textColor,
                    isSmall: true,
                  ),
                  _tableDataCell(s['units'], textColor),
                  _tableDataCell(s['section'], subTextColor, isBold: true),
                ],
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _tableHeaderCell(String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: aViolet,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _tableDataCell(
    String text,
    Color textColor, {
    bool isBold = false,
    bool isSmall = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: TextStyle(
        color: color ?? textColor,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: isSmall ? 11 : 13,
      ),
    ),
  );

  // --- NEW FINANCIAL SECTION INTEGRATION ---
  Widget _buildFinancialSections(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ledger Summary
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Institution Assessment",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...summaryFees.entries
                      .map((e) => _feeRow(e.key, e.value, textColor))
                      .toList(),
                  const SizedBox(height: 32),
                  Text(
                    "Payment Schedules",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _paymentOptionCard(
                    "Cash Option (10% Disc.)",
                    "Full settlement: P43,725.00",
                    success,
                    textColor,
                  ),
                  const SizedBox(height: 8),
                  _paymentOptionCard(
                    "Installment Option",
                    "Upon Registration: P15,000.00",
                    aViolet,
                    textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Misc Breakdown
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Itemized Miscellaneous Fees",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: miscBreakdown.length,
                      separatorBuilder: (c, i) =>
                          const Divider(color: Colors.white10, height: 12),
                      itemBuilder: (c, i) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              miscBreakdown[i]['name']!,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            miscBreakdown[i]['amount']!,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _feeRow(String label, String amount, Color textColor) {
    bool isTotal = label.contains("Total");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? textColor : textColor.withOpacity(0.6),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? aViolet : textColor,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              fontSize: isTotal ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionCard(
    String title,
    String sub,
    Color color,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: color, size: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: aViolet, size: 18),
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
}
