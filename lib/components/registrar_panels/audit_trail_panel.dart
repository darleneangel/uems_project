import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

/// 📊 CSV FORMATTING ENGINE
class ListToCsvConverter {
  const ListToCsvConverter();

  String convert(List<List<dynamic>> rows) {
    if (rows.isEmpty) return "";
    // FIXED: Corrected the mapping and joining logic to prevent type errors
    return rows.map((row) {
      return row.map((item) {
        String value = item?.toString() ?? "";
        if (value.contains(',') ||
            value.contains('\n') ||
            value.contains('"')) {
          value = '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(',');
    }).join('\n');
  }
}

class AuditTrailPanel extends StatefulWidget {
  final bool isDarkMode;
  const AuditTrailPanel({super.key, required this.isDarkMode});

  @override
  State<AuditTrailPanel> createState() => _AuditTrailPanelState();
}

class _AuditTrailPanelState extends State<AuditTrailPanel> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _service = SupabaseService();

  // Filter States
  String _statusFilter = 'All Status';
  String _docTypeFilter = 'All Documents';
  bool _isArchivedView = false;
  bool _isActionLoading = false;

  // Theme Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA EXTRACTION HELPERS ---

  String _formatDT(dynamic raw) {
    if (raw == null) return "---";
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('MM/dd/yy hh:mm a').format(dt);
    } catch (e) {
      return raw.toString();
    }
  }

  int _calculateAge(dynamic rawDate) {
    if (rawDate == null) return 0;
    try {
      final submittedDate = DateTime.parse(rawDate.toString());
      return DateTime.now().difference(submittedDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  // --- EXPORT ENGINE: CSV ---

  Future<void> _exportAuditCSV(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      _showToast("No records available to export.", Colors.orangeAccent);
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final List<List<dynamic>> csvRows = [];

      // 1. Official Institutional Header Row
      csvRows.add([
        'STUDENT NAME',
        'ID NUMBER',
        'DOCUMENT TYPE',
        'AGE (DAYS)',
        'DATE SUBMITTED',
        'DATE PAID',
        'DATE RELEASED',
        'CURRENT STATUS'
      ]);

      // 2. Map Ledger Entries to Rows
      for (var t in data) {
        final p = t['profiles'] ?? {};
        csvRows.add([
          "${p['fn'] ?? ''} ${p['ln'] ?? ''}".toUpperCase(),
          (p['user_id_number'] ?? 'N/A').toString(),
          (t['request_type'] ?? 'N/A').toString(),
          _calculateAge(t['date_applied']),
          _formatDT(t['date_applied']),
          _formatDT(t['paid_at']),
          _formatDT(t['released_at']),
          (t['request_status'] ?? 'N/A').toString().toUpperCase(),
        ]);
      }

      // 3. Convert and Save
      const converter = ListToCsvConverter();
      final String csvString = converter.convert(csvRows);

      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName =
          "Audit_Ledger_${DateTime.now().millisecondsSinceEpoch}.csv";
      final String path = "${directory.path}/$fileName";
      final File file = File(path);

      await file.writeAsString(csvString);

      // 4. Interaction Feedback
      if (mounted) {
        _showToast("Audit CSV generated successfully.", success);
        await OpenFile.open(path);
      }
    } catch (e) {
      _showToast("CSV Export Failed: Institutional error.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // --- UI BUILDERS ---

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
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildSmartFilterBar(cardColor, textColor),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: widget.isDarkMode
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
              ),
              child: _buildLedgerStream(textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Institutional Audit Ledger",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: t,
                    letterSpacing: -1)),
            const Text(
                "Real-time tracking and forensic audit of scholastic document fulfillment.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ]),
          Row(
            children: [
              _filterToggle("Active", !_isArchivedView,
                  () => setState(() => _isArchivedView = false)),
              _filterToggle("Archived", _isArchivedView,
                  () => setState(() => _isArchivedView = true)),
            ],
          ),
        ],
      );

  Widget _buildSmartFilterBar(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          // 1. SMART SEARCH
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Search Name, ID, or Transaction...",
                prefixIcon:
                    Icon(LucideIcons.search, color: aViolet, size: 18),
                border: InputBorder.none,
                hintStyle:
                    TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ),
          ),
          const VerticalDivider(width: 32, color: Colors.white10),

          // 2. STATUS DROPDOWN
          _buildDropdownFilter(
              _statusFilter,
              [
                'All Status',
                'Pending',
                'In Process',
                'Ready for Pickup',
                'Released',
                'Rejected'
              ],
              (v) => setState(() => _statusFilter = v!)),
          const SizedBox(width: 12),

          // 3. DOC TYPE DROPDOWN
          _buildDropdownFilter(
              _docTypeFilter,
              [
                'All Documents',
                'Transcript of Records',
                'Certificate of Good Moral',
                'Certificate of Enrollment',
                'Curriculum Certification'
              ],
              (v) => setState(() => _docTypeFilter = v!)),
        ],
      ),
    );
  }

  Widget _buildLedgerStream(Color text) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.client
          .from('office_requests')
          .stream(primaryKey: ['id']).order('date_applied', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: aViolet));
        }

        return FutureBuilder<List<dynamic>>(
            future: _service.client
                .from('office_requests')
                .select(
                    '*, profiles(*, student_details(courses(code), year_levels(definition)))')
                .order('date_applied', ascending: false),
            builder: (context, futureSnap) {
              if (!futureSnap.hasData) {
                return const Center(
                    child: LinearProgressIndicator(color: aViolet));
              }

              final rawData = List<Map<String, dynamic>>.from(futureSnap.data!);

              // --- SMART FILTER & ARCHIVAL LOGIC ---
              final filtered = rawData.where((t) {
                final String reqStatus = (t['request_status'] ?? '').toString();
                final String reqType = (t['request_type'] ?? '').toString();
                final profile = t['profiles'] ?? {};
                final String fullName =
                    "${profile['fn'] ?? ''} ${profile['ln'] ?? ''}"
                        .toLowerCase();
                final String idNum =
                    (profile['user_id_number'] ?? '').toString().toLowerCase();
                final String query = _searchController.text.toLowerCase();

                // 📐 AUTOMATED ARCHIVAL CALCULATION
                final int ageInDays = _calculateAge(t['date_applied']);
                final bool isSystemArchived = ageInDays > 30;

                // Logic:
                // - Archives view shows: Status is 'Archived' OR it is older than 30 days
                // - Active view shows: Status is NOT 'Archived' AND it is newer than 30 days
                if (_isArchivedView) {
                  if (!(reqStatus == 'Archived' || isSystemArchived)) {
                    return false;
                  }
                } else {
                  if (reqStatus == 'Archived' || isSystemArchived) return false;
                }

                if (reqType == 'Registration Fee') return false;

                final bool matchesSearch =
                    fullName.contains(query) || idNum.contains(query);
                if (!matchesSearch) return false;

                if (_statusFilter != 'All Status' && reqStatus != _statusFilter) {
                  return false;
                }
                if (_docTypeFilter != 'All Documents' &&
                    reqType != _docTypeFilter) {
                  return false;
                }

                return true;
              }).toList();

              if (filtered.isEmpty) return _buildEmptyState(text);

              return Column(
                children: [
                  _buildActionStrip(filtered, text),
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, i) =>
                          _buildAuditRow(filtered[i], text),
                    ),
                  ),
                ],
              );
            });
      },
    );
  }

  Widget _buildActionStrip(List<Map<String, dynamic>> data, Color text) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(
          children: [
            Text("SYSTEM ENTRIES: ${data.length}",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                    letterSpacing: 1.5)),
            const Spacer(),
            _exportBtn(LucideIcons.fileSpreadsheet, "EXPORT AS CSV (EXCEL)",
                () => _exportAuditCSV(data), success),
          ],
        ),
      );

  Widget _buildTableHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFF8FAFC),
        child: Row(
          children: [
            _hCell("STUDENT IDENTITY", 4),
            _hCell("DOCUMENT TYPE", 3),
            _hCell("AGE", 1),
            _hCell("LOG SUBMITTED", 3),
            _hCell("FULFILLMENT LOGS", 4),
            _hCell("STATUS", 3),
            _hCell("ARCHIVE", 1),
          ],
        ),
      );

  Widget _buildAuditRow(Map<String, dynamic> t, Color text) {
    final p = t['profiles'] ?? {};
    final String studentName = "${p['fn'] ?? 'TBA'} ${p['ln'] ?? ''}".trim();
    final String idNum = (p['user_id_number'] ?? 'N/A').toString();
    final int age = _calculateAge(t['date_applied']);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // 1. Identity
          Expanded(
              flex: 4,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName.toUpperCase(),
                        style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text("LRN: $idNum",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 11)),
                  ])),
          // 2. Document
          Expanded(
              flex: 3,
              child: Text((t['request_type'] ?? 'N/A').toString(),
                  style: TextStyle(
                      color: text, fontSize: 13, fontWeight: FontWeight.w500))),
          // 3. Age Column (New)
          Expanded(
              flex: 1,
              child: Text("${age}d",
                  style: TextStyle(
                      color: age > 25 ? Colors.orange : Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
          // 4. Submitted
          Expanded(
              flex: 3,
              child: Text(_formatDT(t['date_applied']),
                  style:
                      const TextStyle(color: Colors.blueGrey, fontSize: 11))),
          // 5. Processing Logs
          Expanded(
              flex: 4,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t['paid_at'] != null)
                      _miniLog("PAID", t['paid_at'], Colors.blueAccent),
                    if (t['released_at'] != null)
                      _miniLog("RELE", t['released_at'], success),
                    if (t['paid_at'] == null && t['released_at'] == null)
                      const Text("---",
                          style: TextStyle(color: Colors.white10)),
                  ])),
          // 6. Status
          Expanded(
              flex: 3,
              child:
                  _statusBadge((t['request_status'] ?? 'Pending').toString())),
          // 7. Archive Action
          Expanded(
              flex: 1,
              child: _isArchivedView
                  ? const Icon(LucideIcons.lock,
                      color: Colors.white10, size: 16)
                  : IconButton(
                      icon: const Icon(LucideIcons.archive,
                          size: 18, color: Colors.blueGrey),
                      onPressed: () => _archiveRecord(t['id'].toString()))),
        ],
      ),
    );
  }

  // --- SUB-WIDGET UTILS ---

  Widget _buildDropdownFilter(
          String value, List<String> items, ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: surfaceDark,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _filterToggle(String l, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: active ? aViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? Colors.transparent : Colors.white10)),
          child: Text(l,
              style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ),
      );

  Widget _miniLog(String label, dynamic time, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
              width: 32,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(label,
                  style: TextStyle(
                      color: c, fontSize: 7, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Text(_formatDT(time),
              style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
        ]),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Widget _statusBadge(String s) {
    Color c = s == 'Released'
        ? success
        : (s == 'Archived' ? Colors.blueGrey : Colors.orangeAccent);
    return UnconstrainedBox(
        alignment: Alignment.centerLeft,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(s.toUpperCase(),
                style: TextStyle(
                    color: c, fontSize: 9, fontWeight: FontWeight.w900))));
  }

  Widget _buildEmptyState(Color t) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.fileX, size: 48, color: t.withOpacity(0.05)),
        const SizedBox(height: 16),
        const Text("No records match your audit criteria.",
            style:
                TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))
      ]));

  void _archiveRecord(String id) async {
    setState(() => _isActionLoading = true);
    try {
      await _service.client
          .from('office_requests')
          .update({'request_status': 'Archived'}).eq('id', id);
      _showToast("Record archived successfully.", success);
    } catch (e) {
      _showToast("Sync Error.", Colors.redAccent);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(32),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
