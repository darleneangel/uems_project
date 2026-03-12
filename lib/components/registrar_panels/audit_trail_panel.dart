import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';

class AuditTrailPanel extends StatefulWidget {
  final bool isDarkMode;
  const AuditTrailPanel({super.key, required this.isDarkMode});

  @override
  State<AuditTrailPanel> createState() => _AuditTrailPanelState();
}

class _AuditTrailPanelState extends State<AuditTrailPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _isArchiving = false;
  String _filterType = "Active"; // Active vs Archived

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// HELPER: Robustly extracts details Map from joined Supabase data
  Map<String, dynamic>? _extractDetails(Map<String, dynamic> profile) {
    final dynamic raw = profile['student_details'];
    if (raw == null) return null;
    if (raw is List && raw.isNotEmpty) return raw[0] as Map<String, dynamic>;
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  /// HELPER: Formats timestamp for UI display
  String _formatDateTime(dynamic raw) {
    if (raw == null) return "---";
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return "${dt.month}/${dt.day}/${dt.year} ${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      return raw.toString();
    }
  }

  // --- EXPORT ENGINE: PDF ---
  Future<void> _generateAuditPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    final timestamp = DateTime.now().toString().split('.')[0];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("INSTITUTIONAL AUDIT LEDGER - SSCR CAVITE",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text("Generated: $timestamp",
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'STUDENT NAME',
              'DOCUMENT',
              'REQUESTED',
              'ACCEPTED (PAID)',
              'RELEASED',
              'STATUS'
            ],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            data: data.map((item) {
              final p = item['profiles'] as Map<String, dynamic>;
              final d = _extractDetails(p);
              return [
                "${p['fn']} ${p['ln']}",
                item['request_type'] ?? 'N/A',
                _formatDateTime(item['date_applied']),
                _formatDateTime(item['paid_at']),
                _formatDateTime(item['released_at']),
                item['request_status'] ?? 'N/A',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/UEMS_Audit_Report.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showToast("PDF Export Interrupted.", Colors.redAccent);
    }
  }

  // --- EXPORT ENGINE: CSV ---
  Future<void> _generateAuditCSV(List<Map<String, dynamic>> data) async {
    String csvData =
        "Student Name,ID,Document,Requested,Accepted/Paid,Released,Status\n";

    for (var item in data) {
      final p = item['profiles'] as Map<String, dynamic>;
      final d = _extractDetails(p);

      csvData += "${p['fn']} ${p['ln']},"
          "${p['user_id_number']},"
          "${item['request_type']},"
          "${_formatDateTime(item['date_applied'])},"
          "${_formatDateTime(item['paid_at'])},"
          "${_formatDateTime(item['released_at'])},"
          "${item['request_status']}\n";
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Institutional_Audit_Log.csv");
      await file.writeAsString(csvData);
      await OpenFile.open(file.path);
      _showToast("CSV Exported to local storage.", success);
    } catch (e) {
      _showToast("CSV Export Failed.", Colors.redAccent);
    }
  }

  Future<void> _archiveTransaction(String id) async {
    setState(() => _isArchiving = true);
    try {
      await SupabaseService()
          .client
          .from('office_requests')
          .update({'request_status': 'Archived'}).eq('id', id);
      _showToast("Record moved to institutional archives.", success);
    } catch (e) {
      _showToast("Sync Error.", Colors.redAccent);
    } finally {
      setState(() => _isArchiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(textColor),
        const SizedBox(height: 32),
        _buildSearchBar(cardColor, textColor),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10)),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService().client.from('office_requests').stream(
                  primaryKey: ['id']).order('date_applied', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));

                return FutureBuilder<List<dynamic>>(
                    future: SupabaseService()
                        .client
                        .from('office_requests')
                        .select(
                            '*, profiles(*, student_details(*, courses(code, name)))')
                        .order('date_applied', ascending: false),
                    builder: (context, futureSnap) {
                      if (!futureSnap.hasData)
                        return const Center(child: CircularProgressIndicator());

                      final allData =
                          List<Map<String, dynamic>>.from(futureSnap.data!);

                      final filtered = allData.where((t) {
                        final matchesStatus = _filterType == "Archived"
                            ? t['request_status'] == 'Archived'
                            : t['request_status'] != 'Archived';
                        final query = _searchController.text.toLowerCase();
                        final matchesSearch = t['profiles']['fn']
                                .toString()
                                .toLowerCase()
                                .contains(query) ||
                            t['profiles']['ln']
                                .toString()
                                .toLowerCase()
                                .contains(query) ||
                            t['profiles']['user_id_number']
                                .toString()
                                .contains(query);
                        return matchesStatus && matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) return _buildEmptyState(textColor);

                      return Column(
                        children: [
                          _buildSubHeader(filtered, textColor),
                          const SizedBox(height: 24),
                          _buildTableHeader(textColor),
                          const Divider(color: Colors.white10, height: 1),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const Divider(
                                  color: Colors.white10, height: 1),
                              itemBuilder: (context, i) =>
                                  _buildAuditRow(filtered[i], textColor),
                            ),
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Institutional Audit & Ledger",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: t,
                    letterSpacing: -1)),
            const Text(
                "Comprehensive tracking of all student transactions and document clearances.",
                style: TextStyle(color: Colors.blueGrey)),
          ]),
          _buildFilterToggle(),
        ],
      );

  Widget _buildSearchBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          style: TextStyle(color: text),
          decoration: const InputDecoration(
            hintText: "Search by Student Name or Institutional ID...",
            prefixIcon: Icon(LucideIcons.search, color: aViolet),
            border: InputBorder.none,
          ),
        ),
      );

  Widget _buildSubHeader(List<Map<String, dynamic>> data, Color text) => Row(
        children: [
          Text("SYSTEM ENTRIES (${data.length})",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                  letterSpacing: 1.5)),
          const Spacer(),
          _exportBtn(LucideIcons.fileText, "PDF", () => _generateAuditPDF(data),
              aViolet),
          const SizedBox(width: 12),
          _exportBtn(LucideIcons.fileSpreadsheet, "CSV",
              () => _generateAuditCSV(data), success),
        ],
      );

  Widget _buildTableHeader(Color t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            _hCell("STUDENT IDENTITY", 4),
            _hCell("DOCUMENT", 3),
            _hCell("REQUESTED", 3),
            _hCell("PROCESSED LOGS", 4),
            _hCell("STATUS", 3),
            _hCell("ACTION", 1),
          ],
        ),
      );

  Widget _buildAuditRow(Map<String, dynamic> t, Color text) {
    final p = t['profiles'] as Map<String, dynamic>;
    final details = _extractDetails(p);
    bool isArchived = t['request_status'] == 'Archived';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 1. Identity
          Expanded(
              flex: 4,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${p['fn']} ${p['ln']}",
                        style: TextStyle(
                            color: text, fontWeight: FontWeight.bold)),
                    Text(p['user_id_number'] ?? "N/A",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 11)),
                  ])),
          // 2. Document
          Expanded(
              flex: 3,
              child: Text(t['request_type'] ?? "Document",
                  style: TextStyle(color: text, fontSize: 13))),
          // 3. Requested Time
          Expanded(
              flex: 3,
              child: Text(_formatDateTime(t['date_applied']),
                  style:
                      TextStyle(color: text.withOpacity(0.7), fontSize: 11))),
          // 4. Status
          Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t['paid_at'] != null)
                    _miniLog("PAID", t['paid_at'], Colors.blueAccent),
                  if (t['released_at'] != null)
                    _miniLog("RELE", t['released_at'], success),
                  if (t['paid_at'] == null && t['released_at'] == null)
                    const Text("No process logs yet",
                        style: TextStyle(
                            color: Colors.white10,
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                ],
              )),
          // 5. Status Badge
          Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusBadge(t['request_status'] ?? "Pending"),
                ],
              )),
          // 6. Action
          Expanded(
              flex: 1,
              child: !isArchived
                  ? IconButton(
                      icon: const Icon(LucideIcons.archive,
                          size: 18, color: Colors.blueGrey),
                      onPressed: () => _archiveTransaction(t['id']))
                  : const Icon(LucideIcons.lock,
                      size: 14, color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _miniLog(String label, dynamic time, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Container(
              width: 35,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(width: 6),
            Text(_formatDateTime(time),
                style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
          ],
        ),
      );

  Widget _hCell(String t, int f) => Expanded(
      flex: f,
      child: Text(t,
          style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)));

  Widget _exportBtn(IconData i, String l, VoidCallback o, Color c) =>
      ElevatedButton.icon(
        onPressed: o,
        icon: Icon(i, size: 14),
        label: Text(l,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: c.withOpacity(0.1),
            foregroundColor: c,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );

  Widget _buildFilterToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: ["Active", "Archived"].map((l) {
            bool sel = _filterType == l;
            return GestureDetector(
              onTap: () => setState(() => _filterType = l),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: sel ? aViolet : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(l,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      );

  Widget _statusBadge(String s) {
    Color c = s == 'Released'
        ? success
        : (s == 'Archived' ? Colors.blueGrey : Colors.orangeAccent);
    return UnconstrainedBox(
        alignment: Alignment.centerLeft,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(s.toUpperCase(),
                style: TextStyle(
                    color: c, fontSize: 8, fontWeight: FontWeight.w900))));
  }

  Widget _buildEmptyState(Color t) => Center(
      child: Text("No records match your criteria.",
          style: TextStyle(color: t.withOpacity(0.1))));
  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }
}
