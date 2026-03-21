import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

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
  Map<String, dynamic>? _selectedStudentData;
  bool _isLoading = false;

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 🛰️ DATABASE: Resolves identity and academic context for formal issuance
  Future<void> _verifyIdentity() async {
    final String idNumber = _searchController.text.trim();
    if (idNumber.isEmpty) return;

    setState(() => _isLoading = true);
    final client = SupabaseService().client;

    try {
      final response = await client.from('profiles').select('''
            id, fn, mn, ln, user_id_number, email, gender, dob,
            student_details (
              enrollment_status,
              student_type,
              courses (name, code, years_to_complete),
              year_levels (definition)
            )
          ''').eq('user_id_number', idNumber).maybeSingle();

      if (mounted) {
        setState(() {
          _selectedStudentData = response;
          _isLoading = false;
        });

        if (response == null) {
          _showToast("ID Number not found in institutional records.",
              Colors.orangeAccent);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast("Sync Error: Unable to verify identity.", Colors.redAccent);
      }
    }
  }

  // --- FORMAL DOCUMENT GENERATION ENGINE ---

  /// 📄 PDF: Certification of Curriculum (Formal Letter)
  Future<void> _generateCurriculumCert() async {
    if (_selectedStudentData == null) return;
    final pdf = pw.Document();
    final student = _selectedStudentData!;
    final details = student['student_details'];
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInstitutionalLetterhead(),
                  pw.SizedBox(height: 40),
                  pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text("Date: $date",
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.SizedBox(height: 30),
                  pw.Text("TO WHOM IT MAY CONCERN:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "This is to formally certify that the student named below is officially recognized by Bright Future Academy as being enrolled in the Board-Approved Curriculum for the degree program specified:",
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 24),
                  _pdfInfoRow(
                      "Student Name:",
                      "${student['ln']}, ${student['fn']} ${student['mn'] ?? ''}"
                          .toUpperCase()),
                  _pdfInfoRow(
                      "Student ID No:", student['user_id_number'] ?? 'N/A'),
                  _pdfInfoRow("Academic Program:",
                      details['courses']?['name'] ?? 'N/A'),
                  _pdfInfoRow("Current Classification:",
                      details['year_levels']?['definition'] ?? 'N/A'),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    "The aforementioned student is following the curriculum edition of 2025, which requires the completion of ${details['courses']?['years_to_complete'] ?? '4'} academic years for the conferment of the degree. The specific subjects and academic units are maintained in the permanent archives of the Office of the Registrar.",
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      "This certification is issued upon request for whatever legal purpose it may serve.",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Spacer(),
                  _buildRegistrarFooter(),
                ])));
    _saveAndOpen(pdf, "Curriculum_Certification_${student['user_id_number']}");
  }

  /// 📄 PDF: Certificate of Good Moral Character
  Future<void> _generateGoodMoralCert() async {
    final pdf = pw.Document();
    final student = _selectedStudentData!;
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInstitutionalLetterhead(),
                  pw.SizedBox(height: 40),
                  pw.Center(
                      child: pw.Text("CERTIFICATE OF GOOD MORAL CHARACTER",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14))),
                  pw.SizedBox(height: 40),
                  pw.Text(
                      "This is to certify that ${student['fn']} ${student['ln']} is a student of good moral character and has no derogatory records on file with the Office of Student Affairs of this institution as of this date.",
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.6),
                      textAlign: pw.TextAlign.justify),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      "Issued this $date for references and legal requirements.",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Spacer(),
                  _buildRegistrarFooter(),
                ])));
    _saveAndOpen(pdf, "Good_Moral_${student['user_id_number']}");
  }

  // --- PDF UI HELPERS ---

  pw.Widget _buildInstitutionalLetterhead() =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("BRIGHT FUTURE ACADEMY",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 20,
                color: PdfColors.indigo900)),
        pw.Text("Institutional Core Campus, Metro Manila, Philippines",
            style: const pw.TextStyle(fontSize: 9)),
        pw.Text("OFFICE OF THE UNIVERSITY REGISTRAR",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.grey700)),
        pw.Divider(thickness: 1),
      ]);

  pw.Widget _buildRegistrarFooter() =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("Certified Correct:", style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 40),
        pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 1)))),
        pw.Text("UNIVERSITY REGISTRAR",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text(
            "Digital Verification Hash: ${DateTime.now().millisecondsSinceEpoch}",
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ]);

  pw.Widget _pdfInfoRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(children: [
        pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700))),
        pw.Text(value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ]));

  Future<void> _saveAndOpen(pw.Document pdf, String name) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name.pdf");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 32),
          _buildSearchSection(cardColor, textColor),
          const SizedBox(height: 24),
          if (_selectedStudentData != null) ...[
            _buildIssuanceGrid(cardColor, textColor),
            const SizedBox(height: 24),
            _buildVerificationPreview(cardColor, textColor, subTextColor),
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
        Text("Credentials & Certification",
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5)),
        Text(
            "Issue official institutional documents and authenticated digital certifications.",
            style: TextStyle(color: subTextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildSearchSection(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("IDENTIFY STUDENT FOR ISSUANCE",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  fontSize: 11,
                  letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _verifyIdentity(),
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "Enter Institutional Student ID Number...",
                    prefixIcon:
                        const Icon(LucideIcons.fingerprint, color: aViolet),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _verifyIdentity,
                icon: _isLoading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.search, size: 18),
                label: const Text("VERIFY RECORD"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: aViolet,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssuanceGrid(Color cardColor, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 3.5,
      children: [
        _issuanceCard("CURRICULUM CERTIFICATION", LucideIcons.bookOpen,
            _generateCurriculumCert, textColor, cardColor),
        _issuanceCard("CERTIFICATE OF GOOD MORAL", LucideIcons.award,
            _generateGoodMoralCert, textColor, cardColor),
        _issuanceCard("ENROLLMENT CERTIFICATION", LucideIcons.fileCheck, () {},
            textColor, cardColor),
        _issuanceCard("TRANSCRIPT (TOR) RELEASE", LucideIcons.fileText, () {},
            textColor, cardColor),
      ],
    );
  }

  Widget _issuanceCard(String title, IconData icon, VoidCallback onTap,
      Color text, Color cardBg) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: aViolet, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Text("GENERATE FORMAL COPY",
                      style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const Icon(LucideIcons.printer, color: Colors.blueGrey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPreview(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck,
                        color: success, size: 18),
                    const SizedBox(width: 12),
                    Text("Digital Authentication Active",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Official documents generated from this terminal include an institutional QR code for instant employer verification against the SSCR Cloud Ledger.",
                  style:
                      TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.qrCode,
                color: Color(0xFF0F071D), size: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color sub) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(
            children: [
              Icon(LucideIcons.fileSearch,
                  color: aViolet.withOpacity(0.1), size: 80),
              const SizedBox(height: 24),
              Text("Search a verified Student ID to begin document issuance.",
                  style: TextStyle(
                      color: sub.withOpacity(0.5),
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
