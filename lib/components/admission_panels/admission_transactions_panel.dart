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

class AdmissionTransactionsPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AdmissionTransactionsPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<AdmissionTransactionsPanel> createState() =>
      _AdmissionTransactionsPanelState();
}

class _AdmissionTransactionsPanelState
    extends State<AdmissionTransactionsPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;

  // --- FILTER STATES ---
  String _statusFilter = "All";
  final List<String> _filterOptions = [
    "All",
    "Pending",
    "Verified",
    "Admitted",
    "Rejected",
    "Archived"
  ];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  /// 🛰️ DATABASE: Fetch every applicant record with course metadata
  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('*, courses(name, code)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allTransactions = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Transaction Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📐 SMART FILTER ENGINE: Handles search components and 30-day archival logic
  List<Map<String, dynamic>> get _filteredList {
    final now = DateTime.now();
    return _allTransactions.where((item) {
      final String fn = (item['fn'] ?? '').toString().toLowerCase();
      final String ln = (item['ln'] ?? '').toString().toLowerCase();
      final String appNo =
          (item['application_no'] ?? '').toString().toLowerCase();
      final String query = _searchController.text.toLowerCase();

      // 1. Multi-component Search
      final bool matchesSearch =
          fn.contains(query) || ln.contains(query) || appNo.contains(query);
      if (!matchesSearch) return false;

      // 2. Archival Logic (Records > 30 days old)
      final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? now;
      final int ageInDays = now.difference(createdAt).inDays;
      final bool isArchived = ageInDays > 30;

      if (_statusFilter == "Archived") {
        return isArchived;
      } else {
        // Exclude archived from active views
        if (isArchived) return false;
        if (_statusFilter == "All") return true;

        return (item['status'] ?? 'Pending').toString().toLowerCase() ==
            _statusFilter.toLowerCase();
      }
    }).toList();
  }

  /// 📄 REPORT ENGINE: Generates a professional PDF using normalized name fields
  Future<void> _generateMasterReport() async {
    final pdf = pw.Document();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final reportData = _filteredList;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for dense data
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BRIGHT FUTURE ACADEMY",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.indigo900)),
                    pw.Text("Institutional Admissions Transaction Ledger",
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text("Generated: $timestamp",
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: [
              "REF NO",
              "APPLICANT NAME",
              "PROGRAM",
              "ADMISSION TYPE",
              "STATUS"
            ],
            data: reportData.map((item) {
              final name =
                  "${item['ln'] ?? 'TBA'}, ${item['fn'] ?? ''} ${item['suffix'] == 'N/A' ? '' : (item['suffix'] ?? '')}"
                      .trim();
              return [
                item['application_no'] ?? 'N/A',
                name.toUpperCase(),
                item['courses']?['code'] ?? 'N/A',
                item['applicant_type'] ?? 'Standard',
                item['status'].toString().toUpperCase(),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                    "Authorized by Ledger Admin: ${widget.userData['fn']} ${widget.userData['ln']}",
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text("Total Records Processed: ${reportData.length}",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final path =
          "${dir.path}/Admissions_Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(path);
    } catch (e) {
      debugPrint("PDF Generation Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admission Transactions",
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1)),
                  const Text(
                      "Comprehensive historical record of institutional admissions activities.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _generateMasterReport,
                icon: const Icon(LucideIcons.fileDown, size: 18),
                label: const Text("GENERATE LEDGER REPORT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFilterBar(cardColor, textColor),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: aViolet))
                : Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: _filteredList.isEmpty
                        ? _buildEmptyState()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: ListView.separated(
                              itemCount: _filteredList.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Colors.white10),
                              itemBuilder: (context, i) {
                                final item = _filteredList[i];
                                final name =
                                    "${item['ln'] ?? 'TBA'}, ${item['fn'] ?? ''} ${item['suffix'] == 'N/A' ? '' : (item['suffix'] ?? '')}"
                                        .toUpperCase();

                                return ListTile(
                                  contentPadding: const EdgeInsets.all(24),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _getStatusColor(item['status'])
                                            .withOpacity(0.1),
                                    child: Icon(LucideIcons.history,
                                        color: _getStatusColor(item['status']),
                                        size: 18),
                                  ),
                                  title: Text(name,
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  subtitle: Text(
                                      "${item['application_no']} • ${item['courses']?['name'] ?? 'UNDECLARED'}",
                                      style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _statusBadge(item['status'] ?? 'Pending'),
                                      const SizedBox(height: 4),
                                      Text(
                                          DateFormat('MMM dd, yyyy').format(
                                              DateTime.parse(
                                                  item['created_at'])),
                                          style: TextStyle(
                                              color: textColor.withOpacity(0.2),
                                              fontSize: 10)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(LucideIcons.search, color: aViolet, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: text),
              decoration: const InputDecoration(
                  hintText: "Search name or reference...",
                  border: InputBorder.none),
            ),
          ),
          const VerticalDivider(color: Colors.white10, indent: 8, endIndent: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((f) => _filterChip(f)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool active = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: active ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? Colors.transparent : Colors.white10),
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                color: active ? Colors.white : Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color c = _getStatusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.searchX,
            size: 48, color: Colors.blueGrey.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text("No transactions found in $_statusFilter view.",
            style: const TextStyle(color: Colors.blueGrey))
      ]));

  Color _getStatusColor(String? s) {
    switch (s) {
      case 'Verified':
        return const Color(0xFF69F0AE);
      case 'Admitted':
        return Colors.blueAccent;
      case 'Enrolled':
        return Colors.greenAccent;
      case 'Rejected':
        return Colors.redAccent;
      case 'Conditional':
        return Colors.orangeAccent;
      default:
        return Colors.orangeAccent;
    }
  }
}
