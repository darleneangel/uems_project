import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_user_management_service.dart';

class AdministrativeAccountManagementPanel extends StatefulWidget {
  const AdministrativeAccountManagementPanel(
      {super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<AdministrativeAccountManagementPanel> createState() =>
      _AdministrativeAccountManagementPanelState();
}

class _AdministrativeAccountManagementPanelState
    extends State<AdministrativeAccountManagementPanel> {
  final _service = AdminUserManagementService();

  late final TextEditingController _nameCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _employeeIdCtl;
  late final TextEditingController _departmentCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _roleCtl;

  String? _editingId;

  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  late bool _isDarkMode;

  final List<String> _departments = [
    'HR',
    'Accounting',
    'Registrar',
    'Admission'
  ];
  final List<String> _roles = [
    'Administrator',
    'Manager',
    'Supervisor',
    'Staff'
  ];
  final List<String> _statuses = ['Active', 'Inactive', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _nameCtl = TextEditingController();
    _emailCtl = TextEditingController();
    _employeeIdCtl = TextEditingController();
    _departmentCtl = TextEditingController();
    _phoneCtl = TextEditingController();
    _roleCtl = TextEditingController();
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

  List<AdminManagedAccount> get _accounts =>
      _service.getAccounts(category: 'administrative');

  void _clearForm() {
    _nameCtl.clear();
    _emailCtl.clear();
    _employeeIdCtl.clear();
    _departmentCtl.clear();
    _phoneCtl.clear();
    _roleCtl.clear();
    setState(() => _editingId = null);
  }

  void _saveAccount() {
    if (_nameCtl.text.trim().isEmpty ||
        _emailCtl.text.trim().isEmpty ||
        _employeeIdCtl.text.trim().isEmpty ||
        _departmentCtl.text.trim().isEmpty ||
        _phoneCtl.text.trim().isEmpty ||
        _roleCtl.text.trim().isEmpty) {
      _snack('Please fill all fields', isError: true);
      return;
    }

    if (_editingId == null) {
      _service.createAccount(
        fullName: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        idNumber: _employeeIdCtl.text.trim(),
        department: _departmentCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        role: _roleCtl.text.trim(),
        category: 'administrative',
      );
      _snack('Administrative account created');
    } else {
      _service.updateAccount(
        id: _editingId!,
        fullName: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        idNumber: _employeeIdCtl.text.trim(),
        department: _departmentCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        role: _roleCtl.text.trim(),
        category: 'administrative',
      );
      _snack('Administrative account updated');
    }

    _clearForm();
  }

  void _startEdit(AdminManagedAccount account) {
    setState(() {
      _editingId = account.id;
      _nameCtl.text = account.fullName;
      _emailCtl.text = account.email;
      _employeeIdCtl.text = account.idNumber;
      _departmentCtl.text = account.department;
      _phoneCtl.text = account.phone;
      _roleCtl.text = account.role;
    });
  }

  void _deleteAccount(AdminManagedAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? surfaceDark : Colors.white,
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This account will be removed permanently.',
          style: GoogleFonts.inter(
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _service.deleteAccount(account.id);
              Navigator.pop(ctx);
              _snack('Account deleted', isError: true);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _setStatus(AdminManagedAccount account, String status) {
    if (status == 'Suspended') {
      _service.suspendAccount(account.id);
    } else if (status == 'Active') {
      _service.activateAccount(account.id);
    } else {
      _service.setStatus(account.id, status);
    }
    _snack('Account status updated to $status');
  }

  void _snack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : success,
      ),
    );
  }

  Color _statusColor(String status) {
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

  Color _departmentColor(String department) {
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

  @override
  Widget build(BuildContext context) {
    final cardColor = _isDarkMode ? surfaceDark : Colors.white;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;

    return ValueListenableBuilder<List<AdminManagedAccount>>(
      valueListenable: _service.notifier,
      builder: (context, _, __) {
        final accounts = _accounts;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create / Update Administrative Account',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _input(
                              controller: _nameCtl,
                              label: 'Full Name',
                              hint: 'e.g., John Smith',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                            ),
                            const SizedBox(height: 12),
                            _input(
                              controller: _emailCtl,
                              label: 'Email Address',
                              hint: 'e.g., john.smith@uems.edu',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                            ),
                            const SizedBox(height: 12),
                            _input(
                              controller: _employeeIdCtl,
                              label: 'Employee ID',
                              hint: 'e.g., EMP1001',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                            ),
                            const SizedBox(height: 12),
                            _dropdown(
                              value: _departmentCtl.text.isEmpty
                                  ? null
                                  : _departmentCtl.text,
                              items: _departments,
                              label: 'Department',
                              hint: 'Select department',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                              cardColor: cardColor,
                              onChanged: (v) => setState(() {
                                _departmentCtl.text = v ?? '';
                              }),
                            ),
                            const SizedBox(height: 12),
                            _input(
                              controller: _phoneCtl,
                              label: 'Phone Number',
                              hint: 'e.g., +1-555-0101',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                            ),
                            const SizedBox(height: 12),
                            _dropdown(
                              value:
                                  _roleCtl.text.isEmpty ? null : _roleCtl.text,
                              items: _roles,
                              label: 'Role',
                              hint: 'Select role',
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                              fillColor: fillColor,
                              cardColor: cardColor,
                              onChanged: (v) => setState(() {
                                _roleCtl.text = v ?? '';
                              }),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton(
                                  onPressed: _saveAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: aViolet,
                                  ),
                                  child: Text(
                                    _editingId == null
                                        ? 'Create Account'
                                        : 'Update Account',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _clearForm,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: borderColor),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: GoogleFonts.inter(
                                      color: subTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrative Accounts (${accounts.length})',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (accounts.isEmpty)
                              Text(
                                'No accounts found',
                                style: GoogleFonts.inter(color: subTextColor),
                              )
                            else
                              ...accounts.map((account) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  account.fullName,
                                                  style: GoogleFonts.inter(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${account.email} • ${account.idNumber}',
                                                  style: GoogleFonts.inter(
                                                    color: subTextColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: subTextColor,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _startEdit(account);
                                                return;
                                              }
                                              if (value == 'delete') {
                                                _deleteAccount(account);
                                                return;
                                              }
                                              _setStatus(account, value);
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                              const PopupMenuDivider(),
                                              ..._statuses.map(
                                                (s) => PopupMenuItem(
                                                  value: s,
                                                  child: Text(s),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _chip(
                                            account.status,
                                            _statusColor(account.status),
                                          ),
                                          _chip(
                                            account.department,
                                            _departmentColor(
                                                account.department),
                                          ),
                                          _chip(account.role, aViolet),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
      },
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color fillColor,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String label,
    required String hint,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color fillColor,
    required Color cardColor,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      style: TextStyle(color: textColor),
      dropdownColor: cardColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
