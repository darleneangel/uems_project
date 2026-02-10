import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class ReportPanel extends StatefulWidget {
  const ReportPanel({super.key});

  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  final List<Map<String, String>> _reports = [];
  late TextEditingController _officeCtl;
  late TextEditingController _categoryCtl;
  late TextEditingController _descCtl;
  late TextEditingController _importCtl;
  int? _editingIndex;

  final List<String> _offices = ['Admissions', 'Registrar', 'Accounting', 'Finance', 'HR', 'Academic Affairs'];
  final List<String> _categories = ['System Error', 'Data Issue', 'Performance', 'UI/UX', 'Integration', 'Other'];
  final List<String> _statuses = ['Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _officeCtl = TextEditingController();
    _categoryCtl = TextEditingController();
    _descCtl = TextEditingController();
    _importCtl = TextEditingController();
    _seedDemoReports();
  }

  void _seedDemoReports() {
    _reports.addAll([
      {
        'office': 'Admissions',
        'category': 'System Error',
        'description': 'Login page crashes when submitting form with special characters',
        'status': 'Open',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toString(),
        'priority': 'High',
      },
      {
        'office': 'Registrar',
        'category': 'Data Issue',
        'description': 'Course codes not syncing with academic calendar',
        'status': 'In Progress',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toString(),
        'priority': 'Medium',
      },
      {
        'office': 'Accounting',
        'category': 'Performance',
        'description': 'Payment processing takes 5+ minutes to load',
        'status': 'Resolved',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toString(),
        'priority': 'High',
      },
    ]);
  }

  void _clearForm() {
    _officeCtl.clear();
    _categoryCtl.clear();
    _descCtl.clear();
    setState(() => _editingIndex = null);
  }

  void _addReport() {
    if (_officeCtl.text.isEmpty || _categoryCtl.text.isEmpty || _descCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newReport = {
      'office': _officeCtl.text,
      'category': _categoryCtl.text,
      'description': _descCtl.text,
      'status': 'Open',
      'timestamp': DateTime.now().toString(),
      'priority': 'Medium',
    };

    setState(() {
      if (_editingIndex != null) {
        _reports[_editingIndex!] = newReport;
        _editingIndex = null;
      } else {
        _reports.insert(0, newReport);
      }
    });

    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex == null ? 'Report submitted' : 'Report updated', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  void _startEdit(int idx) {
    final report = _reports[idx];
    setState(() {
      _officeCtl.text = report['office'] ?? '';
      _categoryCtl.text = report['category'] ?? '';
      _descCtl.text = report['description'] ?? '';
      _editingIndex = idx;
    });
  }

  void _deleteReport(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text('Delete Report?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() => _reports.removeAt(idx));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report deleted', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(int idx, String newStatus) {
    setState(() => _reports[idx]['status'] = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $newStatus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  String _exportCsv() {
    final headers = 'Office,Category,Description,Status,Priority,Timestamp';
    final rows = _reports.map((r) {
      final desc = (r['description'] ?? '').replaceAll('"', '""');
      return '"${r['office']}","${r['category']}","$desc","${r['status']}","${r['priority']}","${r['timestamp']}"';
    }).join('\n');
    return '$headers\n$rows';
  }

  List<Map<String, String>> _parseCsv(String csv) {
    final lines = csv.split('\n').where((l) => l.isNotEmpty && !l.startsWith('Office,')).toList();
    return lines.map((l) {
      final parts = <String>[];
      var current = '';
      var inQuotes = false;
      for (var i = 0; i < l.length; i++) {
        final char = l[i];
        if (char == '"') {
          inQuotes = !inQuotes;
          if (i + 1 < l.length && l[i + 1] == '"') {
            current += '"';
            i++;
          }
        } else if (char == ',' && !inQuotes) {
          parts.add(current);
          current = '';
        } else {
          current += char;
        }
      }
      parts.add(current);
      return parts.length >= 5
          ? {
              'office': parts[0],
              'category': parts[1],
              'description': parts[2],
              'status': parts[3],
              'priority': parts[4],
              'timestamp': DateTime.now().toString(),
            }
          : {};
    }).where((m) => m.isNotEmpty).toList();
  }

  void _showExportDialog() {
    final csv = _exportCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text('Export Reports as CSV', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('CSV copied to clipboard', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
              );
              Navigator.pop(ctx);
            },
            child: Text('Copy to Clipboard', style: GoogleFonts.inter(color: const Color(0xFF8B5CF6))),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: Colors.white54))),
        ],
      ),
    );
  }

  void _showImportDialog() {
    _importCtl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text('Import Reports from CSV', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500,
          height: 300,
          child: TextField(
            controller: _importCtl,
            maxLines: null,
            expands: true,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Paste CSV data here',
              hintStyle: GoogleFonts.inter(color: Colors.white30),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final imported = _parseCsv(_importCtl.text);
              setState(() => _reports.addAll(imported));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${imported.length} reports imported', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
              );
            },
            child: Text('Import', style: GoogleFonts.inter(color: const Color(0xFF8B5CF6))),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    return priority == 'High'
        ? Colors.redAccent
        : priority == 'Medium'
            ? const Color(0xFFFFD54F)
            : Colors.green;
  }

  Color _getStatusColor(String status) {
    return status == 'Open'
        ? Colors.orange
        : status == 'In Progress'
            ? const Color(0xFF64B5F6)
            : status == 'Resolved'
                ? const Color(0xFF69F0AE)
                : Colors.grey;
  }

  Widget _buildReportDetails(Map<String, String> report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getPriorityColor(report['priority'] ?? 'Medium').withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(report['priority'] ?? 'Medium', style: GoogleFonts.inter(color: _getPriorityColor(report['priority'] ?? 'Medium'), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getStatusColor(report['status'] ?? 'Open').withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(report['status'] ?? 'Open', style: GoogleFonts.inter(color: _getStatusColor(report['status'] ?? 'Open'), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Office: ${report['office']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Category: ${report['category']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('Description:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(report['description'] ?? '', style: GoogleFonts.inter(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 12),
          Text('Submitted: ${report['timestamp']}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: Create/Edit Report
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Submit Error Report', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                    Row(children: [
                      TextButton.icon(
                        onPressed: _showImportDialog,
                        icon: const Icon(Icons.file_upload, color: Colors.white70),
                        label: Text('Import', style: GoogleFonts.inter(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showExportDialog,
                        icon: const Icon(Icons.file_download, color: Colors.white70),
                        label: Text('Export', style: GoogleFonts.inter(color: Colors.white70)),
                      ),
                    ])
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _officeCtl.text.isEmpty ? null : _officeCtl.text,
                  items: _offices.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter()))).toList(),
                  onChanged: (v) => setState(() => _officeCtl.text = v ?? ''),
                  decoration: InputDecoration(
                    hintText: 'Select Office',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1E1033),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoryCtl.text.isEmpty ? null : _categoryCtl.text,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter()))).toList(),
                  onChanged: (v) => setState(() => _categoryCtl.text = v ?? ''),
                  decoration: InputDecoration(
                    hintText: 'Error Category',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1E1033),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtl,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe the error/problem in detail...',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  ElevatedButton(
                    onPressed: _addReport,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                    child: Text(_editingIndex == null ? 'Submit Report' : 'Update Report', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                    child: Text('Clear', style: GoogleFonts.inter(color: Colors.white70)),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right panel: Reports List
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports Directory (${_reports.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Expanded(
                  child: _reports.isEmpty
                      ? Center(child: Text('No reports yet', style: GoogleFonts.inter(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: _reports.length,
                          itemBuilder: (ctx, idx) {
                            final r = _reports[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(r['office'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                        Text(r['category'] ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                      ]),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: _getPriorityColor(r['priority'] ?? 'Medium').withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                          child: Text(r['priority'] ?? '', style: GoogleFonts.inter(color: _getPriorityColor(r['priority'] ?? 'Medium'), fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton(
                                          onSelected: (status) => _updateStatus(idx, status),
                                          itemBuilder: (ctx) => _statuses.map((s) => PopupMenuItem(value: s, child: Text(s, style: GoogleFonts.inter()))).toList(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: _getStatusColor(r['status'] ?? 'Open').withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: Text(r['status'] ?? '', style: GoogleFonts.inter(color: _getStatusColor(r['status'] ?? 'Open'), fontSize: 11, fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(r['description'] ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(r['timestamp'] ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: const Color(0xFF1E1033),
                                                title: Text('Report Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                                                content: SizedBox(width: 400, child: _buildReportDetails(r)),
                                                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)))],
                                              ),
                                            ),
                                            icon: const Icon(Icons.info, color: Colors.white54, size: 18),
                                          ),
                                          IconButton(onPressed: () => _startEdit(idx), icon: const Icon(Icons.edit, color: Colors.white54, size: 18)),
                                          IconButton(onPressed: () => _deleteReport(idx), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _officeCtl.dispose();
    _categoryCtl.dispose();
    _descCtl.dispose();
    _importCtl.dispose();
    super.dispose();
  }
}
