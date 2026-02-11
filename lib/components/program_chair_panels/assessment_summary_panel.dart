import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class AssessmentSummaryPanel extends StatefulWidget {
  final bool isDarkMode;
  const AssessmentSummaryPanel({super.key, required this.isDarkMode});

  @override
  State<AssessmentSummaryPanel> createState() => _AssessmentSummaryPanelState();
}

class _AssessmentSummaryPanelState extends State<AssessmentSummaryPanel> {
  // Navigation & Search State
  final TextEditingController _searchController = TextEditingController();
  String _selectedYear = "4th Year";
  String _selectedCategory = "Regular";
  bool _studentFound = false;

  // Modern Tonal Palette Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color success = Color(0xFF69F0AE);

  // --- MOCK DATA ENGINE ---
  final List<String> _yearLevels = [
    "1st Year",
    "2nd Year",
    "3rd Year",
    "4th Year",
  ];
  final List<String> _categories = ["Regular", "Irregular", "Returnee"];

  // Base data that will be "searched"
  Map<String, dynamic>? _activeAssessment;

  void _handleSearch() {
    setState(() {
      if (_searchController.text == "2024-00001" ||
          _searchController.text.isEmpty) {
        _studentFound = true;
        _activeAssessment = {
          "studentName": "DARLENE ANGEL",
          "studentId": _searchController.text.isEmpty
              ? "2024-00001"
              : _searchController.text,
          "program": "BS Computer Science",
          "units": _selectedCategory == "Irregular" ? 15.0 : 21.0,
          "ratePerUnit": _selectedYear == "1st Year" ? 1650.0 : 1550.0,
          "subjects": [
            {"code": "ITCC 411", "fee": 4650.0},
            {"code": "ITCC 412", "fee": 4650.0},
            {"code": "ITCP 413", "fee": 4650.0, "lab": 1200.0},
            if (_selectedCategory != "Irregular") ...[
              {"code": "ITEE 414", "fee": 4650.0},
              {"code": "MATH 201", "fee": 4650.0},
            ],
          ],
          "misc": {
            "Registration": _selectedCategory == "Returnee" ? 1500.0 : 500.0,
            "Library": 800.0,
            "Medical/Dental": 450.0,
            "Athletics": 600.0,
            "Energy Fee": 2500.0,
          },
          "scholarship": "Academic Scholar (20%)",
          "discount": 6510.0,
        };
      } else {
        _studentFound = false;
        _activeAssessment = null;
      }
    });
  }

  double _calculateTotal() {
    if (_activeAssessment == null) return 0.0;
    final double units = _activeAssessment!['units'] as double;
    final double rate = _activeAssessment!['ratePerUnit'] as double;
    double tuition = units * rate;
    double labFees = 1200.0;

    final Map<String, double> misc = Map<String, double>.from(
      _activeAssessment!['misc'],
    );
    double miscTotal = misc.values.fold(0, (sum, val) => sum + val);

    final double discount = _activeAssessment!['discount'] as double;
    return (tuition + labFees + miscTotal) - discount;
  }

  Future<void> _generateBillingPDF(BuildContext context) async {
    if (_activeAssessment == null) return;
    final pdf = pw.Document();
    final timestamp = DateTime.now().toString().split('.')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
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
                  "ACCOUNTING OFFICE - STATEMENT OF ACCOUNT",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Student: ${_activeAssessment!['studentName']}"),
              pw.Text("ID: ${_activeAssessment!['studentId']}"),
              pw.Text("Type: $_selectedCategory | Year: $_selectedYear"),
              pw.SizedBox(height: 30),
              pw.Text(
                "SUMMARY OF FEES",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text("Gross Tuition"), pw.Text("PHP 32,550.00")],
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL DUE: PHP ${_calculateTotal().toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Text(
                "Generated on $timestamp",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/Statement_${_activeAssessment!['studentId']}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
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
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // 1. SEARCH & FILTERS BAR
          _buildSearchAndFilters(bgColor, textColor),
          const SizedBox(height: 32),

          if (_activeAssessment != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. LEFT COLUMN: ITEMIZED SUBJECT LOAD & FEES
                Expanded(
                  flex: 6,
                  child: _buildItemizedSection(bgColor, textColor),
                ),
                const SizedBox(width: 24),
                // 3. RIGHT COLUMN: TOTAL COMPUTATION & ACTIONS
                Expanded(
                  flex: 4,
                  child: _buildSummaryCard(context, bgColor, textColor),
                ),
              ],
            )
          else
            _buildEmptyState(textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Assessment Finalization",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: text,
            letterSpacing: -1,
          ),
        ),
        const Text(
          "Search student and define academic standing to compute final institutional fees.",
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          // Student ID Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                hintText: "Enter Student ID...",
                hintStyle: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: aViolet,
                  size: 20,
                ),
                filled: true,
                fillColor: widget.isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          const SizedBox(width: 16),
          // Year Level Dropdown
          Expanded(
            flex: 2,
            child: _buildDropdownFilter(
              "Year Level",
              _selectedYear,
              _yearLevels,
              (val) {
                setState(() => _selectedYear = val!);
                _handleSearch();
              },
            ),
          ),
          const SizedBox(width: 16),
          // Category Dropdown
          Expanded(
            flex: 2,
            child: _buildDropdownFilter(
              "Category",
              _selectedCategory,
              _categories,
              (val) {
                setState(() => _selectedCategory = val!);
                _handleSearch();
              },
            ),
          ),
          const SizedBox(width: 16),
          _actionIconButton(
            LucideIcons.refreshCw,
            () => _handleSearch(),
            aViolet,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: surfaceDark,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : pViolet,
                fontSize: 13,
                fontWeight: FontWeight.bold,
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

  Widget _buildItemizedSection(Color bg, Color text) {
    final List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(
      _activeAssessment!['subjects'],
    );
    final Map<String, double> misc = Map<String, double>.from(
      _activeAssessment!['misc'],
    );

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ITEMIZED STUDY LOAD & ASSESSMENT",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5,
                ),
              ),
              _statusBadge(_selectedCategory.toUpperCase(), aViolet),
            ],
          ),
          const SizedBox(height: 24),
          ...subjects
              .map(
                (s) => _itemRow(
                  s['code'] as String,
                  "Academic Fee",
                  s['fee'] as double,
                  text,
                ),
              )
              .toList(),
          if (subjects.any((s) => s.containsKey('lab')))
            _itemRow(
              "LAB FEE",
              "ITCP 413 Capstone Project",
              1200.0,
              text,
              isSpecial: true,
            ),
          const Divider(height: 48, color: Colors.white10),
          Text(
            "MISCELLANEOUS BREAKDOWN",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...misc.entries
              .map(
                (e) => _itemRow(
                  e.key,
                  "Administrative Service",
                  e.value,
                  text,
                  isMisc: true,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Color bg, Color text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [pViolet, aViolet.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: aViolet.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "NET ASSESSMENT",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "₱${_calculateTotal().toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _summaryRow(
                "Base Rate",
                "₱${_activeAssessment!['ratePerUnit']}/unit",
              ),
              _summaryRow(
                "Units Enrolled",
                "${_activeAssessment!['units']} Units",
              ),
              _summaryRow("Scholarship", "- ₱6,510.00", isDiscount: true),
              const Divider(height: 32, color: Colors.white24),
              const Row(
                children: [
                  Icon(LucideIcons.award, color: success, size: 16),
                  SizedBox(width: 12),
                  Text(
                    "Academic Scholar (20%) Applied",
                    style: TextStyle(
                      color: success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _actionButton(
          context,
          "RELEASE TO STUDENT PORTAL",
          LucideIcons.send,
          success,
          Colors.black87,
        ),
        const SizedBox(height: 12),
        _actionButton(
          context,
          "DOWNLOAD STATEMENT",
          LucideIcons.fileDown,
          Colors.white.withOpacity(0.05),
          Colors.white,
          isOutline: true,
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Column(
          children: [
            Icon(LucideIcons.user, size: 64, color: text.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text(
              "Search a student ID to begin assessment.",
              style: TextStyle(
                color: text.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Try '2024-00001' or leave blank for demo.",
              style: TextStyle(color: text.withOpacity(0.2), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(
    String code,
    String desc,
    double amount,
    Color text, {
    bool isSpecial = false,
    bool isMisc = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isSpecial ? success : aViolet).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                code,
                style: TextStyle(
                  color: isSpecial ? success : aViolet,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: isMisc ? Colors.blueGrey : text,
                fontSize: 13,
                fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            "₱${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            val,
            style: TextStyle(
              color: isDiscount ? success : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Color text, {
    bool isOutline = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () {
          if (icon == LucideIcons.fileDown) {
            _generateBillingPDF(context);
          }
        },
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: text,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutline
                ? const BorderSide(color: Colors.white10)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _actionIconButton(IconData icon, VoidCallback onTap, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _statusBadge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Text(
        t,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
