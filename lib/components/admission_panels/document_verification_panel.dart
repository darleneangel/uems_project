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

class DocumentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  const DocumentVerificationPanel({super.key, required this.isDarkMode});

  @override
  State<DocumentVerificationPanel> createState() =>
      _DocumentVerificationPanelState();
}

class _DocumentVerificationPanelState extends State<DocumentVerificationPanel> {
  // Theme Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  final Map<String, List<Map<String, dynamic>>> _localDocState = {};

  List<Map<String, dynamic>> _getDefaultDocs() => [
        {"name": "PSA Birth Certificate", "status": false},
        {"name": "Form 138 (Report Card)", "status": false},
        {"name": "Certificate of Good Moral", "status": false},
        {"name": "Medical Certificate", "status": false},
        {"name": "Entrance Exam Results", "status": false},
      ];

  double _calculateProgress(String applicantId) {
    final docs = _localDocState[applicantId] ?? _getDefaultDocs();
    int verified = docs.where((d) => d['status'] == true).length;
    return verified / docs.length;
  }

  void _toggleDoc(String applicantId, int docIndex) {
    setState(() {
      if (!_localDocState.containsKey(applicantId)) {
        _localDocState[applicantId] = _getDefaultDocs();
      }
      _localDocState[applicantId]![docIndex]['status'] =
          !_localDocState[applicantId]![docIndex]['status'];
    });
  }

  // --- DATABASE ACTIONS ---

  /// ACTION: Verification Approved -> Redirect to Accounting
  Future<void> _finalizeVerification(Map<String, dynamic> applicant) async {
    try {
      await SupabaseService()
          .client
          .from('applicants')
          .update({'status': 'For Payment'}).eq('id', applicant['id']);

      await _generateAdmissionSlip(applicant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: success,
              content: Text(
                  "Approved. Student directed to Accounting for Payment.")),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent, content: Text("Error: $e")));
    }
  }

  // --- PDF ENGINE ---
  Future<void> _generateAdmissionSlip(Map<String, dynamic> applicant) async {
    final pdf = pw.Document();
    final String timestamp = DateTime.now().toString().split('.')[0];
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    if (logoImage != null)
                      pw.Container(
                          width: 40, height: 40, child: pw.Image(logoImage)),
                    pw.SizedBox(width: 12),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("UEMSSP",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 22,
                                  color: brandViolet)),
                          pw.Text("OFFICE OF ADMISSIONS",
                              style: pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey700)),
                        ]),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("OFFICIAL DOCUMENT",
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey500)),
                        pw.Text("ADMISSION SLIP",
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: brandViolet, thickness: 1.5),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(children: [
                  pw.Row(children: [
                    pw.Expanded(
                        child: _pdfMetaItem(
                            "STUDENT NAME", applicant['full_name'])),
                    pw.Expanded(
                        child: _pdfMetaItem(
                            "APPLICATION ID", applicant['application_no'])),
                  ]),
                ]),
              ),
              pw.SizedBox(height: 40),
              pw.Text("DOCUMENTATION STATUS: CLEARANCE OBTAINED",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                      fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Text(
                  "The applicant is cleared for final institutional enrollment steps.",
                  style: pw.TextStyle(fontSize: 10)),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("AUTHENTICATED BY ADMISSIONS CORE",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text("Ref: $timestamp",
                        style: pw.TextStyle(fontSize: 7)),
                  ]),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File("${dir.path}/Admission_Slip_${applicant['application_no']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verification Hub",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -1)),
            const Text(
                "Audit applicant requirements before handover to Accounting.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 32),
            SizedBox(
              height: 700,
              child: TabBarView(
                children: [
                  _buildQueueStream(
                      cardColor, textColor, subTextColor, 'Pending'),
                  _buildQueueStream(
                      cardColor, textColor, subTextColor, 'For Payment'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() => Container(
        height: 50,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: aViolet),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: "1. VERIFICATION QUEUE"),
            Tab(text: "2. SENT TO ACCOUNTING")
          ],
        ),
      );

  Widget _buildQueueStream(
      Color cardBg, Color text, Color subText, String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService()
          .client
          .from('applicants')
          .stream(primaryKey: ['id']).eq('status', status),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));
        final list = snapshot.data!;
        if (list.isEmpty) return _emptyState(subText);

        return ListView.builder(
          shrinkWrap: true,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final applicant = list[index];
            final progress = _calculateProgress(applicant['id']);
            return _buildVerificationCard(applicant, progress, cardBg, text,
                subText, status == 'For Payment');
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> applicant, double progress,
      Color cardBg, Color text, Color subText, bool isAccounting) {
    bool isComplete = progress == 1.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
              value: isAccounting ? 1.0 : progress,
              backgroundColor: Colors.white10,
              color: (isAccounting || isComplete) ? success : aViolet),
          if (isAccounting || isComplete)
            const Icon(LucideIcons.check, size: 16, color: success),
        ]),
        title: Text(applicant['full_name'],
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: text)),
        subtitle: Text(
            "${applicant['application_no']} • ${applicant['applicant_type']}",
            style: TextStyle(color: subText, fontSize: 12)),
        trailing: isAccounting
            ? _badge("IN ACCOUNTING", success)
            : _badge("${(progress * 100).toInt()}%", Colors.blueGrey),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32, color: Colors.white10),
                const Text("REQUIREMENT CHECKLIST",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        letterSpacing: 1)),
                const SizedBox(height: 16),
                ...List.generate(
                    5,
                    (i) => _buildDocRow(
                        applicant['id'],
                        i,
                        (_localDocState[applicant['id']] ??
                            _getDefaultDocs())[i],
                        text,
                        isAccounting)),
                if (isComplete && !isAccounting) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                          onPressed: () => _finalizeVerification(applicant),
                          icon: const Icon(LucideIcons.shieldCheck),
                          label: const Text("APPROVE & DIRECT TO ACCOUNTING"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: aViolet))),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDocRow(
      String appId, int i, Map<String, dynamic> doc, Color t, bool readOnly) {
    bool done = readOnly || doc['status'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: readOnly ? null : () => _toggleDoc(appId, i),
        child: Row(children: [
          Icon(done ? LucideIcons.checkCircle : LucideIcons.circle,
              color: done ? success : Colors.blueGrey, size: 18),
          const SizedBox(width: 12),
          Text(doc['name'],
              style: TextStyle(color: done ? t : Colors.blueGrey, fontSize: 13))
        ]),
      ),
    );
  }

  Widget _emptyState(Color sub) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.inbox, size: 48, color: sub.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text("Queue is clear.", style: TextStyle(color: sub))
      ]));
  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
}
