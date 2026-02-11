import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcademicAccountManagementPanel extends StatefulWidget {
  const AcademicAccountManagementPanel({super.key});

  @override
  State<AcademicAccountManagementPanel> createState() => _AcademicAccountManagementPanelState();
}

class _AcademicAccountManagementPanelState extends State<AcademicAccountManagementPanel> {
  final List<Map<String, String>> _accounts = [];
  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _studentIdCtl;
  late TextEditingController _departmentCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _roleCtl;
  late TextEditingController _specializationCtl;
  int? _editingIndex;

  final List<String> _departments = ['Computer Science', 'Business Administration', 'Mathematics', 'Engineering', 'Arts & Sciences'];
  final List<String> _roles = ['Program Chair', 'Teacher', 'Student'];
  final List<String> _statuses = ['Active', 'Inactive', 'Suspended', 'Graduated'];

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _emailCtl = TextEditingController();
    _studentIdCtl = TextEditingController();
    _departmentCtl = TextEditingController();
    _phoneCtl = TextEditingController();
    _roleCtl = TextEditingController();
    _specializationCtl = TextEditingController();
    _seedDemoAccounts();
  }

  void _seedDemoAccounts() {
    _accounts.addAll([
      {
        'name': 'Dr. Robert Anderson',
        'email': 'robert.anderson@uems.edu',
        'studentId': 'STF001',
        'department': 'Computer Science',
        'phone': '+1-555-0201',
        'role': 'Program Chair',
        'specialization': 'Artificial Intelligence',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 45)).toString(),
      },
      {
        'name': 'Prof. Maria Rodriguez',
        'email': 'maria.rodriguez@uems.edu',
        'studentId': 'STF002',
        'department': 'Mathematics',
        'phone': '+1-555-0202',
        'role': 'Teacher',
        'specialization': 'Calculus',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 40)).toString(),
      },
      {
        'name': 'James Wilson',
        'email': 'james.wilson@uems.edu',
        'studentId': 'STD001',
        'department': 'Business Administration',
        'phone': '+1-555-0203',
        'role': 'Student',
        'specialization': 'Finance',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 35)).toString(),
      },
      {
        'name': 'Lisa Thompson',
        'email': 'lisa.thompson@uems.edu',
        'studentId': 'STD002',
        'department': 'Engineering',
        'phone': '+1-555-0204',
        'role': 'Student',
        'specialization': 'Mechanical Engineering',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 30)).toString(),
      },
      {
        'name': 'Dr. David Kim',
        'email': 'david.kim@uems.edu',
        'studentId': 'STF003',
        'department': 'Arts & Sciences',
        'phone': '+1-555-0205',
        'role': 'Program Chair',
        'specialization': 'Literature',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 25)).toString(),
      },
    ]);
  }

  void _clearForm() {
    _nameCtl.clear();
    _emailCtl.clear();
    _studentIdCtl.clear();
    _departmentCtl.clear();
    _phoneCtl.clear();
    _roleCtl.clear();
    _specializationCtl.clear();
    setState(() => _editingIndex = null);
  }

  void _addAccount() {
    if (_nameCtl.text.isEmpty || _emailCtl.text.isEmpty || _studentIdCtl.text.isEmpty || 
        _departmentCtl.text.isEmpty || _phoneCtl.text.isEmpty || _roleCtl.text.isEmpty || _specializationCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newAccount = {
      'name': _nameCtl.text,
      'email': _emailCtl.text,
      'studentId': _studentIdCtl.text,
      'department': _departmentCtl.text,
      'phone': _phoneCtl.text,
      'role': _roleCtl.text,
      'specialization': _specializationCtl.text,
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
      SnackBar(content: Text(_editingIndex == null ? 'Account created' : 'Account updated', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  void _startEdit(int idx) {
    final account = _accounts[idx];
    setState(() {
      _nameCtl.text = account['name'] ?? '';
      _emailCtl.text = account['email'] ?? '';
      _studentIdCtl.text = account['studentId'] ?? '';
      _departmentCtl.text = account['department'] ?? '';
      _phoneCtl.text = account['phone'] ?? '';
      _roleCtl.text = account['role'] ?? '';
      _specializationCtl.text = account['specialization'] ?? '';
      _editingIndex = idx;
    });
  }

  void _deleteAccount(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text('Delete Account?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone. The account will be permanently deleted.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
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
      SnackBar(content: Text('Account status updated to $newStatus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF69F0AE);
      case 'Inactive':
        return Colors.grey;
      case 'Suspended':
        return Colors.orange;
      case 'Graduated':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Program Chair':
        return const Color(0xFFDC2626);
      case 'Teacher':
        return const Color(0xFF3B82F6);
      case 'Student':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  Widget _buildAccountDetails(Map<String, String> account) {
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
                decoration: BoxDecoration(color: _getStatusColor(account['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(account['status'] ?? 'Active', style: GoogleFonts.inter(color: _getStatusColor(account['status'] ?? 'Active'), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getRoleColor(account['role'] ?? 'Student').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(account['role'] ?? '', style: GoogleFonts.inter(color: _getRoleColor(account['role'] ?? 'Student'), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Name: ${account['name']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Email: ${account['email']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('ID: ${account['studentId']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Department: ${account['department']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Phone: ${account['phone']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Specialization: ${account['specialization']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('Created: ${account['timestamp']}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Account Management', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., Dr. Robert Anderson',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., robert.anderson@uems.edu',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _studentIdCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'ID Number',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., STF001 or STD001',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _departmentCtl.text.isEmpty ? null : _departmentCtl.text,
                          items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) => setState(() => _departmentCtl.text = v ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Department',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Select Department',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF1E1033),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., +1-555-0201',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _roleCtl.text.isEmpty ? null : _roleCtl.text,
                          items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) => setState(() => _roleCtl.text = v ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Select Role',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF1E1033),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _specializationCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Specialization',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., Artificial Intelligence, Calculus',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          ElevatedButton(
                            onPressed: _addAccount,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                            child: Text(_editingIndex == null ? 'Create Account' : 'Update Account', style: GoogleFonts.inter(color: Colors.white)),
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
                // Right panel: Accounts List
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Accounts (${_accounts.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                          child: _accounts.isEmpty
                              ? Center(child: Text('No accounts yet', style: GoogleFonts.inter(color: Colors.white54)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _accounts.length,
                                  itemBuilder: (ctx, idx) {
                                    final account = _accounts[idx];
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
                                                Text(account['name'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                                Text('${account['email']} • ${account['studentId']}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
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
                                                  decoration: BoxDecoration(color: _getRoleColor(account['role'] ?? 'Student').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(account['role'] ?? '', style: GoogleFonts.inter(color: _getRoleColor(account['role'] ?? 'Student'), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                              ]),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('${account['department']} • ${account['specialization']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(account['timestamp'] ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: const Color(0xFF1E1033),
                                                        title: Text('Account Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                                                        content: SizedBox(width: 400, child: _buildAccountDetails(account)),
                                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)))],
                                                      ),
                                                    ),
                                                    icon: const Icon(Icons.info, color: Colors.white54, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _startEdit(idx), icon: const Icon(Icons.edit, color: Colors.white54, size: 18)),
                                                  PopupMenuButton(
                                                    onSelected: (status) => _updateStatus(idx, status),
                                                    itemBuilder: (ctx) => _statuses.map((s) => PopupMenuItem(value: s, child: Text(s, style: GoogleFonts.inter()))).toList(),
                                                    child: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _deleteAccount(idx), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
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
    _studentIdCtl.dispose();
    _departmentCtl.dispose();
    _phoneCtl.dispose();
    _roleCtl.dispose();
    _specializationCtl.dispose();
    super.dispose();
  }
}
