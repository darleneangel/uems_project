import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class CredentialsCertificationPanel extends StatefulWidget {
  final bool isDarkMode;
  const CredentialsCertificationPanel({super.key, required this.isDarkMode});

  @override
  State<CredentialsCertificationPanel> createState() =>
      _CredentialsCertificationPanelState();
}

class _CredentialsCertificationPanelState
    extends State<CredentialsCertificationPanel> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedId;

  // Mock Database for quick lookup
  final Map<String, Map<String, dynamic>> _studentLookup = {
    "2024-00001": {
      "name": "DARLENE ANGEL",
      "course": "BS Computer Science",
      "year": "4th Year",
      "status": "Candidate for Graduation",
    },
    "2024-00002": {
      "name": "JUAN DELA CRUZ",
      "course": "BS Info Tech",
      "year": "3rd Year",
      "status": "Active / Enrolled",
    },
  };

  // --- PDF GENERATION ENGINE ---
  Future<void> _issueDocument(String type) async {
    if (_selectedId == null) return;
    final student = _studentLookup[_selectedId];
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
                  fontSize: 16,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "OFFICE OF THE REGISTRAR",
                style: pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 50),
            pw.Center(
              child: pw.Text(
                type.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text("TO WHOM IT MAY CONCERN:"),
            pw.SizedBox(height: 20),
            pw.Text(
              "This is to certify that ${student!['name']} is officially recognized by this institution as a student of ${student['course']}.",
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "This document is issued upon the request of the interested party for whatever legal purpose it may serve.",
            ),
            pw.SizedBox(height: 60),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(width: 150, child: pw.Divider()),
                    pw.Text(
                      "Registrar Signature",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Container(
                  width: 60,
                  height: 60,
                  color: PdfColors.grey300,
                  child: pw.Center(
                    child: pw.Text("QR", style: pw.TextStyle(fontSize: 8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/${type.replaceAll(' ', '_')}_${_selectedId}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Export error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 32),

          // 1. STUDENT SEARCH & SELECTION
          _buildSearchSection(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),

          if (_selectedId != null) ...[
            // 2. DOCUMENT ISSUANCE GRID
            _buildIssuanceGrid(cardColor, textColor, subTextColor),
            const SizedBox(height: 24),
            // 3. DIGITAL VERIFICATION PREVIEW
            _buildVerificationPanel(cardColor, textColor, subTextColor),
          ] else
            _buildEmptyState(subTextColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Credentials & Certification",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        Text(
          "Issue official school documents, diplomas, and authenticated digital copies.",
          style: TextStyle(color: subTextColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
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
          Text(
            "Target Student Lookup",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Enter Student ID (e.g. 2024-00001)",
                    prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () =>
                    setState(() => _selectedId = _searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "VERIFY IDENTITY",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedId != null &&
              _studentLookup.containsKey(_selectedId)) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    color: Color(0xFF69F0AE),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${_studentLookup[_selectedId]!['name']} • ${_studentLookup[_selectedId]!['course']}",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _studentLookup[_selectedId]!['status'],
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssuanceGrid(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.8,
      children: [
        _docTypeCard(
          "Certificate of Good Moral",
          LucideIcons.award,
          const Color(0xFF8B5CF6),
          cardColor,
          textColor,
        ),
        _docTypeCard(
          "Certificate of Enrollment",
          LucideIcons.fileCheck,
          const Color(0xFF69F0AE),
          cardColor,
          textColor,
        ),
        _docTypeCard(
          "Transcript of Records (TOR)",
          LucideIcons.fileText,
          Colors.orangeAccent,
          cardColor,
          textColor,
        ),
        _docTypeCard(
          "Official Diploma",
          LucideIcons.graduationCap,
          Colors.blueAccent,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _docTypeCard(
    String title,
    IconData icon,
    Color color,
    Color cardBg,
    Color text,
  ) {
    return InkWell(
      onTap: () => _issueDocument(title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    "CLICK TO GENERATE",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.printer, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPanel(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Digital Authenticated Copies",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enable QR-based verification for digital records. Authenticated documents can be scanned by employers for instant validation.",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 20),
                _actionButton(
                  LucideIcons.shieldCheck,
                  "ENABLE DIGITAL SIGNATURE",
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.qrCode,
              color: Colors.black,
              size: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(LucideIcons.search, color: sub.withOpacity(0.1), size: 64),
            const SizedBox(height: 16),
            Text(
              "Search a student ID to begin document issuance",
              style: TextStyle(color: sub.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color c) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
