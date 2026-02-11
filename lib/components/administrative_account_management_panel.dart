import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdministrativeAccountManagementPanel extends StatefulWidget {
  const AdministrativeAccountManagementPanel({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<AdministrativeAccountManagementPanel> createState() => _AdministrativeAccountManagementPanelState();
}

class _AdministrativeAccountManagementPanelState extends State<AdministrativeAccountManagementPanel> {
  final List<Map<String, String>> _accounts = [];
  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _employeeIdCtl;
  late TextEditingController _departmentCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _roleCtl;
  int? _editingIndex;

  // Theme colors (matching student dashboard)
  static const Color pViolet = Color(0xFF2E1065);
  static const Color tDark = Color(0xFF0F071D);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);
  
  bool _isDarkMode = false;

  final List<String> _departments = ['HR', 'Accounting', 'Registrar', 'Admission'];
  final List<String> _roles = ['Administrator', 'Manager', 'Supervisor', 'Staff'];
  final List<String> _statuses = ['Active', 'Inactive', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _emailCtl = TextEditingController();
    _employeeIdCtl = TextEditingController();
    _departmentCtl = TextEditingController();
    _phoneCtl = TextEditingController();
    _roleCtl = TextEditingController();
    _isDarkMode = widget.isDarkMode;
    _seedDemoAccounts();
  }

  void _seedDemoAccounts() {
    _accounts.addAll([
      {
        'name': 'Sarah Johnson',
        'email': 'sarah.johnson@uems.edu',
        'employeeId': 'EMP001',
        'department': 'HR',
        'phone': '+1-555-0101',
        'role': 'Administrator',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 30)).toString(),
      },
      {
        'name': 'Michael Chen',
        'email': 'michael.chen@uems.edu',
        'employeeId': 'EMP002',
        'department': 'Accounting',
        'phone': '+1-555-0102',
        'role': 'Manager',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 25)).toString(),
      },
      {
        'name': 'Emily Rodriguez',
        'email': 'emily.rodriguez@uems.edu',
        'employeeId': 'EMP003',
        'department': 'Registrar',
        'phone': '+1-555-0103',
        'role': 'Supervisor',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 20)).toString(),
      },
      {
        'name': 'David Kim',
        'email': 'david.kim@uems.edu',
        'employeeId': 'EMP004',
        'department': 'Admission',
        'phone': '+1-555-0104',
        'role': 'Staff',
        'status': 'Inactive',
        'timestamp': DateTime.now().subtract(const Duration(days: 15)).toString(),
      },
    ]);
  }

  void _clearForm() {
    _nameCtl.clear();
    _emailCtl.clear();
    _employeeIdCtl.clear();
    _departmentCtl.clear();
    _phoneCtl.clear();
    _roleCtl.clear();
    setState(() => _editingIndex = null);
  }

  void _addAccount() {
    if (_nameCtl.text.isEmpty || _emailCtl.text.isEmpty || _employeeIdCtl.text.isEmpty || 
        _departmentCtl.text.isEmpty || _phoneCtl.text.isEmpty || _roleCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newAccount = {
      'name': _nameCtl.text,
      'email': _emailCtl.text,
      'employeeId': _employeeIdCtl.text,
      'department': _departmentCtl.text,
      'phone': _phoneCtl.text,
      'role': _roleCtl.text,
      'status': 'Active',
      'timestamp': DateTime.now().toString(),
    };

    setState(() {
      if (_editingIndex != null) {
        _accounts[_editingIndex!] = newAccount;
        _editingIndex = null;
      } else {
        _accounts.insert(0, newAccount);
      }
    });

    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex == null ? 'Account created' : 'Account updated', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: success),
    );
  }

  void _startEdit(int idx) {
    final account = _accounts[idx];
    setState(() {
      _nameCtl.text = account['name'] ?? '';
      _emailCtl.text = account['email'] ?? '';
      _employeeIdCtl.text = account['employeeId'] ?? '';
      _departmentCtl.text = account['department'] ?? '';
      _phoneCtl.text = account['phone'] ?? '';
      _roleCtl.text = account['role'] ?? '';
      _editingIndex = idx;
    });
  }

  void _deleteAccount(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        title: Text('Delete Account?', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white : pViolet, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone. The account will be permanently deleted.', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white54 : Colors.black54))),
          TextButton(
            onPressed: () {
              setState(() => _accounts.removeAt(idx));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deleted', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(int idx, String newStatus) {
    setState(() => _accounts[idx]['status'] = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account status updated to $newStatus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: success),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return success;
      case 'Inactive':
        return Colors.grey;
      case 'Suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'HR':
        return const Color(0xFF3B82F6);
      case 'Accounting':
        return const Color(0xFF10B981);
      case 'Registrar':
        return const Color(0xFFF59E0B);
      case 'Admission':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Widget _buildAccountDetails(Map<String, String> account) {
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
                decoration: BoxDecoration(color: _getStatusColor(account['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(account['status'] ?? 'Active', style: GoogleFonts.inter(color: _getStatusColor(account['status'] ?? 'Active'), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getDepartmentColor(account['department'] ?? 'HR').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(account['department'] ?? '', style: GoogleFonts.inter(color: _getDepartmentColor(account['department'] ?? 'HR'), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Name: ${account['name']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white : pViolet, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Email: ${account['email']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          Text('Employee ID: ${account['employeeId']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          Text('Phone: ${account['phone']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          Text('Role: ${account['role']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          Text('Created: ${account['timestamp']}', style: GoogleFonts.inter(color: _isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final cardColor = _isDarkMode ? surfaceDark : Colors.white;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel: Create/Edit Account
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Administrative Account Management', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., John Smith',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., john.smith@uems.edu',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _employeeIdCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Employee ID',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., EMP001',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _departmentCtl.text.isEmpty ? null : _departmentCtl.text,
                          items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) => setState(() => _departmentCtl.text = v ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Department',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'Select Department',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                          style: TextStyle(color: textColor),
                          dropdownColor: cardColor,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneCtl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'e.g., +1-555-0101',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _roleCtl.text.isEmpty ? null : _roleCtl.text,
                          items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) => setState(() => _roleCtl.text = v ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(color: subTextColor),
                            hintText: 'Select Role',
                            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                            filled: true,
                            fillColor: _isDarkMode ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          ),
                          style: TextStyle(color: textColor),
                          dropdownColor: cardColor,
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          ElevatedButton(
                            onPressed: _addAccount,
                            style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                            child: Text(_editingIndex == null ? 'Create Account' : 'Update Account', style: GoogleFonts.inter(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _clearForm,
                            style: OutlinedButton.styleFrom(side: BorderSide(color: borderColor)),
                            child: Text('Clear', style: GoogleFonts.inter(color: subTextColor)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Right panel: Accounts List
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Administrative Accounts (${_accounts.length})', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                          child: _accounts.isEmpty
                              ? Center(child: Text('No accounts yet', style: GoogleFonts.inter(color: subTextColor)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _accounts.length,
                                  itemBuilder: (ctx, idx) {
                                    final account = _accounts[idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: _isDarkMode ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(account['name'] ?? '', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                                                Text('${account['email']} • ${account['employeeId']}', style: GoogleFonts.inter(color: subTextColor, fontSize: 12)),
                                              ]),
                                              Row(children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: _getStatusColor(account['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(account['status'] ?? '', style: GoogleFonts.inter(color: _getStatusColor(account['status'] ?? 'Active'), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: _getDepartmentColor(account['department'] ?? 'HR').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(account['department'] ?? '', style: GoogleFonts.inter(color: _getDepartmentColor(account['department'] ?? 'HR'), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                              ]),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('${account['phone']} • ${account['role']}', style: GoogleFonts.inter(color: subTextColor, fontSize: 12)),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(account['timestamp'] ?? '', style: GoogleFonts.inter(color: subTextColor, fontSize: 10)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: cardColor,
                                                        title: Text('Account Details', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700)),
                                                        content: SizedBox(width: 400, child: _buildAccountDetails(account)),
                                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: subTextColor)))],
                                                      ),
                                                    ),
                                                    icon: Icon(Icons.info, color: subTextColor, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _startEdit(idx), icon: Icon(Icons.edit, color: subTextColor, size: 18)),
                                                  PopupMenuButton(
                                                    onSelected: (status) => _updateStatus(idx, status),
                                                    itemBuilder: (ctx) => _statuses.map((s) => PopupMenuItem(value: s, child: Text(s, style: GoogleFonts.inter()))).toList(),
                                                    child: Icon(Icons.more_vert, color: subTextColor, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _deleteAccount(idx), icon: Icon(Icons.delete, color: Colors.redAccent, size: 18)),
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
    _emailCtl.dispose();
    _employeeIdCtl.dispose();
    _departmentCtl.dispose();
    _phoneCtl.dispose();
    _roleCtl.dispose();
    super.dispose();
  }
}
