import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DepartmentManagementPanel extends StatefulWidget {
  const DepartmentManagementPanel({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<DepartmentManagementPanel> createState() => _DepartmentManagementPanelState();
}

class _DepartmentManagementPanelState extends State<DepartmentManagementPanel> {
  final List<Map<String, String>> _departments = [];
  late TextEditingController _nameCtl;
  late TextEditingController _codeCtl;
  late TextEditingController _headCtl;
  late TextEditingController _descCtl;
  int? _editingIndex;
  
  // Theme colors
  static const Color pViolet = Color(0xFF2E1065);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);
  static const Color lCard = Color(0xFFFFFFFF);
  
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _codeCtl = TextEditingController();
    _headCtl = TextEditingController();
    _descCtl = TextEditingController();
    _isDarkMode = widget.isDarkMode;
    _seedDemoDepartments();
  }

  void _seedDemoDepartments() {
    _departments.addAll([
      {
        'name': 'Computer Science',
        'code': 'CS',
        'head': 'Dr. John Smith',
        'description': 'Department of Computer Science and Engineering',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 30)).toString(),
      },
      {
        'name': 'Business Administration',
        'code': 'BA',
        'head': 'Dr. Sarah Johnson',
        'description': 'Department of Business and Management Studies',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 25)).toString(),
      },
      {
        'name': 'Mathematics',
        'code': 'MATH',
        'head': 'Dr. Robert Chen',
        'description': 'Department of Mathematical Sciences',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 20)).toString(),
      },
    ]);
  }

  void _clearForm() {
    _nameCtl.clear();
    _codeCtl.clear();
    _headCtl.clear();
    _descCtl.clear();
    setState(() => _editingIndex = null);
  }

  void _addDepartment() {
    if (_nameCtl.text.isEmpty || _codeCtl.text.isEmpty || _headCtl.text.isEmpty || _descCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newDepartment = {
      'name': _nameCtl.text,
      'code': _codeCtl.text.toUpperCase(),
      'head': _headCtl.text,
      'description': _descCtl.text,
      'status': 'Active',
      'timestamp': DateTime.now().toString(),
    };

    setState(() {
      if (_editingIndex != null) {
        _departments[_editingIndex!] = newDepartment;
        _editingIndex = null;
      } else {
        _departments.insert(0, newDepartment);
      }
    });

    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex == null ? 'Department added' : 'Department updated', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  void _startEdit(int idx) {
    final department = _departments[idx];
    setState(() {
      _nameCtl.text = department['name'] ?? '';
      _codeCtl.text = department['code'] ?? '';
      _headCtl.text = department['head'] ?? '';
      _descCtl.text = department['description'] ?? '';
      _editingIndex = idx;
    });
  }

  void _deleteDepartment(int idx) {
    // Theme-aware colors for dialogs
    final dialogBgColor = _isDarkMode ? surfaceDark : lCard;
    final dialogTextColor = _isDarkMode ? Colors.white : pViolet;
    final dialogSubTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text('Delete Department?', style: GoogleFonts.inter(color: dialogTextColor, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.', style: GoogleFonts.inter(color: dialogSubTextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: dialogSubTextColor))),
          TextButton(
            onPressed: () {
              setState(() => _departments.removeAt(idx));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Department deleted', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(int idx) {
    final department = _departments[idx];
    final newStatus = department['status'] == 'Active' ? 'Inactive' : 'Active';
    setState(() => _departments[idx]['status'] = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Department status updated to $newStatus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: success),
    );
  }

  Color _getStatusColor(String status) {
    return status == 'Active' ? success : Colors.grey;
  }

  Widget _buildDepartmentDetails(Map<String, String> department) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _isDarkMode ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getStatusColor(department['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(department['status'] ?? 'Active', style: GoogleFonts.inter(color: _getStatusColor(department['status'] ?? 'Active'), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Department Name: ${department['name']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white : pViolet, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Department Code: ${department['code']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          Text('Department Head: ${department['head']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          Text('Description:', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white : pViolet, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(department['description'] ?? '', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87, height: 1.5)),
          const SizedBox(height: 12),
          Text('Created: ${department['timestamp']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
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
    final borderColor = _isDarkMode ? Colors.white24 : Colors.black45; // Darker border for better visibility
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel: Create/Edit Department
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Department Management', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Department Name',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., Computer Science',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 2.0)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _codeCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Department Code',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., CS',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 2.0)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _headCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Department Head',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., Dr. John Smith',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 2.0)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descCtl,
                          maxLines: 4,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'Describe the department...',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 2.0)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          ElevatedButton(
                            onPressed: _addDepartment,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                            child: Text(_editingIndex == null ? 'Add Department' : 'Update Department', style: GoogleFonts.inter(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _clearForm,
                            style: OutlinedButton.styleFrom(side: BorderSide(color: borderColor, width: 2.0)),
                            child: Text('Clear', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black54)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Right panel: Departments List
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Departments Directory (${_departments.length})', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                          child: _departments.isEmpty
                              ? Center(child: Text('No departments yet', style: GoogleFonts.inter(color: subTextColor)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _departments.length,
                                  itemBuilder: (ctx, idx) {
                                    final dept = _departments[idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(dept['name'] ?? '', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                                                Text('${dept['code']} • ${dept['head']}', style: GoogleFonts.inter(color: subTextColor, fontSize: 12)),
                                              ]),
                                              Row(children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: _getStatusColor(dept['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(dept['status'] ?? '', style: GoogleFonts.inter(color: _getStatusColor(dept['status'] ?? 'Active'), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                              ]),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(dept['description'] ?? '', style: GoogleFonts.inter(color: subTextColor, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(dept['timestamp'] ?? '', style: GoogleFonts.inter(color: subTextColor, fontSize: 10)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: cardColor,
                                                        title: Text('Department Details', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700)),
                                                        content: SizedBox(width: 400, child: _buildDepartmentDetails(dept)),
                                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: subTextColor)))],
                                                      ),
                                                    ),
                                                    icon: Icon(Icons.info, color: subTextColor, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _startEdit(idx), icon: Icon(Icons.edit, color: subTextColor, size: 18)),
                                                  IconButton(onPressed: () => _toggleStatus(idx), icon: Icon(Icons.toggle_on, color: subTextColor, size: 18)),
                                                  IconButton(onPressed: () => _deleteDepartment(idx), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _codeCtl.dispose();
    _headCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }
}
