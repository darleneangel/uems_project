import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class HRPanel extends StatefulWidget {
  const HRPanel({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<HRPanel> createState() => _HRPanelState();
}

class _HRPanelState extends State<HRPanel> {
  final List<Map<String, String>> _employees = [];
  final _nameCtl = TextEditingController();
  final _deptCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _empIdCtl = TextEditingController();
  final _roleCtl = TextEditingController();
  int? _editingIndex;
  final TextEditingController _importCtl = TextEditingController();

  // Theme colors
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color lCard = Color(0xFFFFFFFF);
  static const Color secondaryViolet = Color(0xFF4C1D95);

  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _deptCtl.dispose();
    _emailCtl.dispose();
    _empIdCtl.dispose();
    _roleCtl.dispose();
    super.dispose();
  }

  void _addEmployee() {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    final record = {
      'name': name,
      'department': _deptCtl.text.trim(),
      'email': _emailCtl.text.trim(),
      'employeeId': _empIdCtl.text.trim(),
      'role': _roleCtl.text.trim(),
    };
    setState(() {
      if (_editingIndex != null) {
        _employees[_editingIndex!] = record;
        _editingIndex = null;
      } else {
        _employees.insert(0, record);
      }
    });
    _clearForm();
  }

  void _clearForm() {
    _nameCtl.clear();
    _deptCtl.clear();
    _emailCtl.clear();
    _empIdCtl.clear();
    _roleCtl.clear();
    _editingIndex = null;
  }

  void _startEdit(int index) {
    final e = _employees[index];
    _nameCtl.text = e['name'] ?? '';
    _deptCtl.text = e['department'] ?? '';
    _emailCtl.text = e['email'] ?? '';
    _empIdCtl.text = e['employeeId'] ?? '';
    _roleCtl.text = e['role'] ?? '';
    setState(() {
      _editingIndex = index;
    });
  }

  void _deleteEmployee(int index) {
    final dialogTextColor = _isDarkMode ? Colors.white : pViolet;
    final dialogSubTextColor = _isDarkMode ? Colors.white70 : Colors.black87;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1033) : lCard,
        title: Text(
          'Confirm Delete',
          style: GoogleFonts.inter(color: dialogTextColor),
        ),
        content: Text(
          'Delete ${_employees[index]['name']}?',
          style: GoogleFonts.inter(color: dialogSubTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: dialogSubTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _employees.removeAt(index));
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _exportCsv() {
    final sb = StringBuffer();
    sb.writeln('name,department,email,employeeId,role');
    for (final e in _employees) {
      final row = [
        e['name'],
        e['department'],
        e['email'],
        e['employeeId'],
        e['role'],
      ].map((s) => '"${(s ?? '').replaceAll('"', '""')}"').join(',');
      sb.writeln(row);
    }
    return sb.toString();
  }

  void _showExportDialog() {
    final csv = _exportCsv();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text(
          'Export CSV',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: Text('Copy', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    _importCtl.clear();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text(
          'Import CSV',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: _importCtl,
            maxLines: 10,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Paste CSV here',
              hintStyle: TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white10,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = _importCtl.text.trim();
              if (raw.isNotEmpty) {
                final lines = raw
                    .split(RegExp(r'\r?\n'))
                    .where((l) => l.trim().isNotEmpty)
                    .toList();
                if (lines.isNotEmpty) {
                  // assume header present
                  final start = lines.first.toLowerCase().contains('name,')
                      ? 1
                      : 0;
                  for (int i = start; i < lines.length; i++) {
                    final cols = _parseCsvLine(lines[i]);
                    if (cols.length >= 5) {
                      setState(() {
                        _employees.insert(0, {
                          'name': cols[0],
                          'department': cols[1],
                          'email': cols[2],
                          'employeeId': cols[3],
                          'role': cols[4],
                        });
                      });
                    }
                  }
                }
              }
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: Text(
              'Import',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseCsvLine(String line) {
    // Very small CSV parser that handles quoted fields
    final List<String> out = [];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        out.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    out.add(sb.toString());
    return out.map((s) => s.trim()).toList();
  }

  void _showEmployeeDetails(Map<String, String> emp) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text(
          emp['name'] ?? '',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department: ${emp['department'] ?? ''}',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${emp['email'] ?? ''}',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Employee ID: ${emp['employeeId'] ?? ''}',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${emp['role'] ?? ''}',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final cardColor = _isDarkMode ? surfaceDark : lCard;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E1033) : lCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Employee Record',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _showImportDialog,
                        icon: Icon(Icons.file_upload, color: subTextColor),
                        label: Text(
                          'Import',
                          style: GoogleFonts.inter(color: subTextColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showExportDialog,
                        icon: Icon(Icons.file_download, color: subTextColor),
                        label: Text(
                          'Export',
                          style: GoogleFonts.inter(color: subTextColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _deptCtl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Department',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Personal Email',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _empIdCtl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Employee ID',
                        hintStyle: TextStyle(
                          color: subTextColor.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _roleCtl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Role',
                        hintStyle: TextStyle(
                          color: subTextColor.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _addEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: Text(
                      _editingIndex == null ? 'Create' : 'Save',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(color: subTextColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Employee Directory',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E1033) : lCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: _employees.isEmpty
              ? Text(
                  'No employees added.',
                  style: GoogleFonts.inter(color: subTextColor),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _employees.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor),
                  itemBuilder: (context, idx) {
                    final e = _employees[idx];
                    return ListTile(
                      onTap: () => _showEmployeeDetails(e),
                      title: Text(
                        e['name'] ?? '',
                        style: GoogleFonts.inter(color: textColor),
                      ),
                      subtitle: Text(
                        e['department'] ?? '',
                        style: GoogleFonts.inter(
                          color: subTextColor.withOpacity(0.8),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e['employeeId'] ?? '',
                            style: GoogleFonts.inter(
                              color: subTextColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _startEdit(idx),
                            icon: Icon(
                              Icons.edit,
                              color: subTextColor.withOpacity(0.8),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteEmployee(idx),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
