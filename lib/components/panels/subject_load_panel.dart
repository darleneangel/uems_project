import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

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

  List<Map<String, dynamic>> _subjects = [];
  Map<String, String> _summaryFees = {
    "Tuition Fee": "P0.00",
    "Miscellaneous Fees": "P0.00",
    "Total Fees": "P0.00",
  };
  List<Map<String, String>> _miscBreakdownList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveLoadData();
  }

  /// DATABASE ENGINE: Fetches study loads, assessments, and fee structures
  Future<void> _fetchLiveLoadData() async {
    setState(() => _isLoading = true);
    final client = SupabaseService().client;
    final String profileId = widget.studentData['id'];

    final now = DateTime.now();
    final timeOnly =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    try {
      // 1. Fetch official Study Load (Joined with Subjects)
      final List<dynamic> loadData = await client
          .from('study_loads')
          .select(
              'room_number, day_schedule, time_start, time_end, section_block, subjects(code, name, hours_per_week, units)')
          .eq('student_id', profileId);

      final List<Map<String, dynamic>> subjectResults = loadData.map((sl) {
        final s = sl['subjects'] as Map<String, dynamic>;
        return {
          'code': s['code'],
          'title': s['name'],
          'room': sl['room_number'] ?? 'TBA',
          'days': sl['day_schedule'] ?? 'TBA',
          'time': "${sl['time_start'] ?? ''} - ${sl['time_end'] ?? ''}",
          'hrs/units': "${s['hours_per_week']} / ${s['units']}",
          'section': sl['section_block'] ?? 'N/A',
          'units': double.tryParse(s['units'].toString()) ?? 0.0,
        };
      }).toList();

      // 2. Fetch the current semester's Assessment from Accounting
      final assessment = await client
          .from('assessments')
          .select()
          .eq('student_id', profileId)
          .maybeSingle();

      // 3. Fetch the institutional Miscellaneous Fee library
      final List<dynamic> miscLibrary =
          await client.from('miscellaneous_fees').select('name, price');

      if (mounted) {
        setState(() {
          _subjects = subjectResults;
          if (assessment != null) {
            _summaryFees["Tuition Fee"] =
                "P${assessment['total_tuition']?.toString() ?? '0.00'}";
            _summaryFees["Miscellaneous Fees"] =
                "P${assessment['total_misc']?.toString() ?? '0.00'}";
            _summaryFees["Total Fees"] =
                "P${assessment['grand_total']?.toString() ?? '0.00'}";
          }
          _miscBreakdownList = miscLibrary
              .map((m) => {
                    "name": m['name'].toString(),
                    "amount": m['price'].toString()
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Subject Load Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalUnits =>
      _subjects.fold(0.0, (sum, item) => sum + (item['units'] as double));

  // --- PDF EXPORT ENGINE ---
  Future<void> _exportStudyLoad(BuildContext context) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

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
            pw.Text("OFFICIAL COURSE LOAD & SCHEDULE",
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: brandViolet)),
            pw.SizedBox(height: 8),
            _buildPdfSubjectTable(brandViolet),
            pw.SizedBox(height: 25),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    flex: 5, child: _buildPdfFinancialSummary(brandViolet)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                    flex: 5, child: _buildPdfMiscBreakdown(brandViolet)),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("AUTHENTICATED DIGITAL MATRICULATION",
                    style: pw.TextStyle(
                        color: PdfColors.green700,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8)),
                pw.Text("Ref: $timestamp",
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/UEMS_Matriculation_${widget.studentData['user_id_number']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("PDF Generation Failed: $e")));
    }
  }

  pw.Widget _buildPdfHeader(PdfColor color, pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          if (logo != null)
            pw.Container(
                width: 45,
                height: 45,
                child: pw.Image(logo, fit: pw.BoxFit.contain))
          else
            pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                    color: color, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Center(
                    child: pw.Text("U",
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 24)))),
          pw.SizedBox(width: 15),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("UEMSSP",
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: color)),
            pw.Text("Institutional Core System",
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ]),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text("CERTIFICATE OF MATRICULATION",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text("Term: 2nd Semester SY 2025-2026",
              style: pw.TextStyle(fontSize: 8)),
        ]),
      ],
    );
  }

  pw.Widget _buildPdfStudentInfoGrid() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(
              child: _pdfMetaItem("FULL NAME",
                  "${widget.studentData['ln']}, ${widget.studentData['fn']}")),
          pw.Expanded(
              child: _pdfMetaItem("STUDENT NUMBER",
                  widget.studentData['user_id_number'] ?? "N/A")),
        ]),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Expanded(
              child: _pdfMetaItem(
                  "CATEGORY", widget.studentData['student_type'] ?? "Regular")),
          pw.Expanded(
              child: _pdfMetaItem(
                  "YEAR LEVEL", widget.studentData['year_level'] ?? "N/A")),
        ]),
      ]),
    );
  }

  pw.Widget _pdfMetaItem(String label, String val) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold)),
        pw.Text(val,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))
      ]);

  pw.Widget _buildPdfSubjectTable(PdfColor color) {
    return pw.Table.fromTextArray(
      headers: [
        "CODE",
        "DESCRIPTION",
        "ROOM",
        "DAYS",
        "TIME",
        "HRS/UNITS",
        "SECTION"
      ],
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: color),
      cellStyle: pw.TextStyle(fontSize: 7),
      data: _subjects
          .map((s) => [
                s['code'],
                s['title'],
                s['room'],
                s['days'],
                s['time'],
                s['hrs/units'],
                s['section']
              ])
          .toList(),
    );
  }

  pw.Widget _buildPdfFinancialSummary(PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("ASSESSMENT SUMMARY",
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 8),
        ..._summaryFees.entries.map((e) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key,
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: e.key.contains("Total")
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
                pw.Text(e.value,
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: e.key.contains("Total")
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPdfMiscBreakdown(PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("ITEMIZED MISCELLANEOUS",
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 8),
        ..._miscBreakdownList
            .take(8)
            .map((m) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text(m['name']!,
                            style: pw.TextStyle(fontSize: 6))),
                    pw.Text(m['amount']!,
                        style: pw.TextStyle(
                            fontSize: 6, fontWeight: pw.FontWeight.bold)),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildPdfPaymentOptions(PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(
          "Note: Settlement can be processed via GCash/PayMongo using the student portal QR.",
          style: pw.TextStyle(fontSize: 8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryHeader(textColor, subTextColor),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Official Course Load & Schedule",
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
              const SizedBox(height: 20),
              _buildSubjectTable(textColor, subTextColor),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Divider(color: Colors.white10)),
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
              color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      child: Row(
        children: [
          _statItem(LucideIcons.layers, "Total Units",
              _totalUnits.toStringAsFixed(1), textColor),
          _verticalDivider(),
          _statItem(LucideIcons.bookOpen, "Subjects",
              _subjects.length.toString(), textColor),
          _verticalDivider(),
          _statItem(LucideIcons.wallet, "Assessment",
              _summaryFees["Total Fees"]!, textColor),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportStudyLoad(context),
            icon: const Icon(LucideIcons.fileDown, size: 16),
            label: const Text("EXPORT OFFICIAL LOAD"),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )
        ],
      ),
    );
  }

  Widget _buildSubjectTable(Color textColor, Color subTextColor) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2.5),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.2)
      },
      children: [
        TableRow(
            decoration: BoxDecoration(
                color: aViolet.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8)),
            children: [
              _tableHeaderCell("CODE"),
              _tableHeaderCell("DESCRIPTION"),
              _tableHeaderCell("ROOM"),
              _tableHeaderCell("DAYS/TIME"),
              _tableHeaderCell("UNITS"),
              _tableHeaderCell("BLOCK"),
            ]),
        ..._subjects
            .map((s) => TableRow(children: [
                  _tableDataCell(s['code'], textColor,
                      isBold: true, color: aViolet),
                  _tableDataCell(s['title'], textColor),
                  _tableDataCell(s['room'], subTextColor),
                  _tableDataCell(s['time'], textColor, isSmall: true),
                  _tableDataCell(s['hrs/units'], textColor),
                  _tableDataCell(s['section'], subTextColor, isBold: true),
                ]))
            .toList(),
      ],
    );
  }

  Widget _tableHeaderCell(String text) => Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: aViolet,
              letterSpacing: 1)));
  Widget _tableDataCell(String text, Color textColor,
          {bool isBold = false, bool isSmall = false, Color? color}) =>
      Padding(
          padding: const EdgeInsets.all(12),
          child: Text(text,
              style: TextStyle(
                  color: color ?? textColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSmall ? 11 : 13)));

  Widget _buildFinancialSections(Color textColor, Color subTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 4,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Assessment Summary",
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 20),
              ..._summaryFees.entries
                  .map((e) => _feeRow(e.key, e.value, textColor))
                  .toList(),
            ])),
        const SizedBox(width: 48),
        Expanded(
            flex: 5,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Miscellaneous Items",
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 20),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: ListView.separated(
                  itemCount: _miscBreakdownList.length,
                  separatorBuilder: (c, i) =>
                      const Divider(color: Colors.white10, height: 12),
                  itemBuilder: (c, i) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(_miscBreakdownList[i]['name']!,
                                style: TextStyle(
                                    color: subTextColor, fontSize: 11))),
                        Text("P${_miscBreakdownList[i]['amount']!}",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ]),
                ),
              ),
            ])),
      ],
    );
  }

  Widget _feeRow(String label, String amount, Color textColor) {
    bool isTotal = label.contains("Total");
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? textColor : textColor.withOpacity(0.6),
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(amount,
              style: TextStyle(
                  color: isTotal ? aViolet : textColor,
                  fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                  fontSize: isTotal ? 16 : 13)),
        ]));
  }

  Widget _statItem(
          IconData icon, String label, String value, Color textColor) =>
      Row(children: [
        Icon(icon, color: aViolet, size: 18),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: textColor, fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold))
        ])
      ]);
  Widget _verticalDivider() => Container(
      height: 30,
      width: 1,
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 24));
}
