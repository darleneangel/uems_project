import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard copy
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class AccountControlPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AccountControlPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AccountControlPanel> createState() => _AccountControlPanelState();
}

class _AccountControlPanelState extends State<AccountControlPanel> {
  final SupabaseService _service = SupabaseService();

  // Tab Controller State
  int _activeTab = 0; // 0: Accounts Directory, 1: System Audit Logs

  // ---------------------------------------------------------------------
  // TAB 0: ACCOUNTS DIRECTORY STATES
  // ---------------------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProfiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isLoadingAccounts = true;
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  // ---------------------------------------------------------------------
  // TAB 1: SYSTEM AUDIT LOGS STATES
  // ---------------------------------------------------------------------
  final TextEditingController _auditSearchController = TextEditingController();
  List<Map<String, dynamic>> _allAuditLogs = [];
  List<Map<String, dynamic>> _filteredAuditLogs = [];
  bool _isLoadingAudits = true;
  String _selectedAuditRoleFilter = 'All';
  String _selectedAuditStatusFilter = 'All'; // All, Active Session, Logged Out

  static const Color pViolet = Color(0xFF1E1033);
  static const Color sViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF160D2B);

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    _fetchAuditLogs();
    _searchController.addListener(_applyFilters);
    _auditSearchController.addListener(_applyAuditFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _auditSearchController.removeListener(_applyAuditFilters);
    _searchController.dispose();
    _auditSearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // DATABASE QUERIES & LOGIC: Accounts
  // ---------------------------------------------------------------------

  /// 🛰️ DATABASE: Load all user profiles from Supabase
  Future<void> _fetchProfiles() async {
    if (!mounted) return;
    setState(() => _isLoadingAccounts = true);
    try {
      final response = await _service.client
          .from('profiles')
          .select('id, user_id_number, fn, mn, ln, email, role, account_status')
          .order('user_id_number', ascending: true);

      if (response != null && mounted) {
        setState(() {
          _allProfiles = List<Map<String, dynamic>>.from(response);
          _filteredProfiles = _allProfiles;
        });
        _applyFilters();
      }
    } catch (e) {
      _showSnackBar("Sync Error: Failed to fetch institutional accounts. $e",
          Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  /// 🛠️ FILTER ENGINE: Filters accounts list
  void _applyFilters() {
    final searchKey = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredProfiles = _allProfiles.where((profile) {
        final role = (profile['role'] ?? '').toString().toLowerCase();
        bool matchesRole = _selectedRoleFilter == 'All' ||
            role == _selectedRoleFilter.toLowerCase();

        final status =
            (profile['account_status'] ?? 'Active').toString().toLowerCase();
        bool matchesStatus = _selectedStatusFilter == 'All' ||
            status == _selectedStatusFilter.toLowerCase();

        final userId =
            (profile['user_id_number'] ?? '').toString().toLowerCase();
        final fullName =
            "${profile['fn'] ?? ''} ${profile['mn'] ?? ''} ${profile['ln'] ?? ''}"
                .toLowerCase();
        final email = (profile['email'] ?? '').toString().toLowerCase();

        bool matchesSearch = searchKey.isEmpty ||
            userId.contains(searchKey) ||
            fullName.contains(searchKey) ||
            email.contains(searchKey);

        return matchesRole && matchesStatus && matchesSearch;
      }).toList();
    });
  }

  /// 🛰️ DATABASE: Toggles user account status in Supabase table
  Future<void> _toggleAccountStatus(
      String profileId, String currentStatus) async {
    final String newStatus = currentStatus == 'Active' ? 'Suspended' : 'Active';

    try {
      await _service.client
          .from('profiles')
          .update({'account_status': newStatus}).eq('id', profileId);

      _showSnackBar(
          "Account successfully updated to $newStatus!", Colors.greenAccent);
      _fetchProfiles();
      _fetchAuditLogs(); // Refresh audit logs too since status might affect them
    } catch (e) {
      _showSnackBar("Database Sync Error: $e", Colors.redAccent);
    }
  }

  // ---------------------------------------------------------------------
  // DATABASE QUERIES & LOGIC: System Audit Logs
  // ---------------------------------------------------------------------

  /// 🛰️ DATABASE: Pull real-time login and logout activity linked to profiles
  Future<void> _fetchAuditLogs() async {
    if (!mounted) return;
    setState(() => _isLoadingAudits = true);
    try {
      final response = await _service.client
          .from('attendance_logs')
          .select(
              'id, check_in_time, check_out_time, profiles(user_id_number, fn, mn, ln, role, email)')
          .order('check_in_time', ascending: false);

      if (response != null && mounted) {
        setState(() {
          _allAuditLogs = List<Map<String, dynamic>>.from(response);
          _filteredAuditLogs = _allAuditLogs;
        });
        _applyAuditFilters();
      }
    } catch (e) {
      debugPrint("Error fetching system audit logs: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAudits = false);
    }
  }

  /// 🛠️ FILTER ENGINE: Filters system audit logs
  void _applyAuditFilters() {
    final searchKey = _auditSearchController.text.trim().toLowerCase();

    setState(() {
      _filteredAuditLogs = _allAuditLogs.where((log) {
        final profile = log['profiles'] as Map<String, dynamic>?;
        if (profile == null) return false;

        // 1. Role Filter
        final role = (profile['role'] ?? '').toString().toLowerCase();
        bool matchesRole = _selectedAuditRoleFilter == 'All' ||
            role == _selectedAuditRoleFilter.toLowerCase();

        // 2. Session Status Filter
        final isCheckedOut = log['check_out_time'] != null;
        bool matchesStatus = true;
        if (_selectedAuditStatusFilter == 'Active Session') {
          matchesStatus = !isCheckedOut;
        } else if (_selectedAuditStatusFilter == 'Logged Out') {
          matchesStatus = isCheckedOut;
        }

        // 3. Search Key
        final userId =
            (profile['user_id_number'] ?? '').toString().toLowerCase();
        final fullName =
            "${profile['fn'] ?? ''} ${profile['mn'] ?? ''} ${profile['ln'] ?? ''}"
                .toLowerCase();
        final email = (profile['email'] ?? '').toString().toLowerCase();

        bool matchesSearch = searchKey.isEmpty ||
            userId.contains(searchKey) ||
            fullName.contains(searchKey) ||
            email.contains(searchKey);

        return matchesRole && matchesStatus && matchesSearch;
      }).toList();
    });
  }

  // ---------------------------------------------------------------------
  // EXPORT PIPELINE: Comma-Separated Values (CSV) Excel Format
  // ---------------------------------------------------------------------
  void _exportLogsToExcel() {
    if (_filteredAuditLogs.isEmpty) {
      _showSnackBar("No log records available to export.", Colors.orangeAccent);
      return;
    }

    try {
      // Create CSV Headers
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln(
          "Audit Log ID,ID Number,Full Name,Role/Department,Login Timestamp,Logout Timestamp,Status");

      // Populate Rows
      for (var log in _filteredAuditLogs) {
        final profile = log['profiles'] as Map<String, dynamic>?;
        final logId = log['id'] ?? '';
        final idNum = profile?['user_id_number'] ?? 'N/A';
        final fullName =
            "${profile?['fn'] ?? ''} ${profile?['mn'] ?? ''} ${profile?['ln'] ?? ''}"
                .trim()
                .replaceAll(',', ' ');
        final role = (profile?['role'] ?? 'Unknown').toString().toUpperCase();

        final loginTime = log['check_in_time'] != null
            ? DateTime.parse(log['check_in_time']).toLocal().toString()
            : 'N/A';

        final logoutTime = log['check_out_time'] != null
            ? DateTime.parse(log['check_out_time']).toLocal().toString()
            : 'N/A';

        final status =
            log['check_out_time'] != null ? "Logged Out" : "Active Session";

        csvBuffer.writeln(
            '"$logId","$idNum","$fullName","$role","$loginTime","$logoutTime","$status"');
      }

      // Copy to Clipboard (Highly reliable cross-platform method for browser & native)
      Clipboard.setData(ClipboardData(text: csvBuffer.toString()));

      _showExportSuccessDialog(
        title: "Excel Data Exported!",
        subtitle:
            "Audit log records were structured and copied to your clipboard.",
        body: "To open in Excel or Google Sheets:\n"
            "1. Open Microsoft Excel or Google Sheets.\n"
            "2. Click a cell and press Paste (Ctrl + V / Cmd + V).\n"
            "3. Select 'Split Text to Columns' using Comma delimitation.",
      );
    } catch (e) {
      _showSnackBar("Export failed: $e", Colors.redAccent);
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT PIPELINE: Printable Auditor Report Preview (PDF-Like)
  // ---------------------------------------------------------------------
  void _openPrintableReport() {
    if (_filteredAuditLogs.isEmpty) {
      _showSnackBar("No log records available to generate a report.",
          Colors.orangeAccent);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _PrintReportModal(
        isDarkMode: widget.isDarkMode,
        auditLogs: _filteredAuditLogs,
        adminName:
            "${widget.userData['fn'] ?? ''} ${widget.userData['ln'] ?? ''}",
      ),
    );
  }

  void _showSnackBar(String m, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showExportSuccessDialog(
      {required String title, required String subtitle, required String body}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.fileSpreadsheet,
                color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                body,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE",
                style: TextStyle(color: aViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color mainBgColor = isDark ? surfaceDark : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color cardBorderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: mainBgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ HEADER BLOCK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Command Security Center",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Manage active system permissions, session locks, and live-audited institutional access logs.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                  ),
                ],
              ),

              // 🎛️ TAB SWAP CHIPS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabSelectorChip("Accounts", 0, LucideIcons.users),
                    _buildTabSelectorChip(
                        "Audit Logs", 1, LucideIcons.shieldCheck),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 🔄 ACTIVE TAB RENDERING
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _activeTab == 0
                  ? _buildAccountsDirectory()
                  : _buildAuditLogsDirectory(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelectorChip(String title, int tabIndex, IconData icon) {
    final bool isActive = _activeTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? Colors.white : Colors.blueGrey, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // VIEW RENDER: Accounts Directory Tab
  // ---------------------------------------------------------------------
  Widget _buildAccountsDirectory() {
    final bool isDark = widget.isDarkMode;
    final Color titleColor = isDark ? Colors.white : Colors.black87;

    return Column(
      key: const ValueKey(0),
      children: [
        // Search and Filters Bar
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: titleColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Search accounts by ID, Name, or Email...",
                    hintStyle: TextStyle(color: Colors.blueGrey),
                    prefixIcon:
                        Icon(LucideIcons.search, color: aViolet, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Role Filter Dropdown
            _buildDropdownFilter(
              label: "Department",
              value: _selectedRoleFilter,
              items: [
                'All',
                'Student',
                'Teacher',
                'Professor',
                'PC_Chair',
                'Admin',
                'Registrar',
                'HR',
                'Accounting'
              ],
              onChanged: (val) {
                setState(() {
                  _selectedRoleFilter = val!;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 16),

            // Status Filter Dropdown
            _buildDropdownFilter(
              label: "Account Status",
              value: _selectedStatusFilter,
              items: ['All', 'Active', 'Suspended'],
              onChanged: (val) {
                setState(() {
                  _selectedStatusFilter = val!;
                  _applyFilters();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Accounts Table
        Expanded(
          child: _isLoadingAccounts
              ? const Center(child: CircularProgressIndicator(color: aViolet))
              : _filteredProfiles.isEmpty
                  ? const Center(
                      child: Text(
                        "No institutional profiles match the selected filters.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.black.withOpacity(0.03)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(isDark
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.02)),
                              columnSpacing: 32,
                              columns: [
                                _buildTableHeader("ID Number"),
                                _buildTableHeader("Full Name"),
                                _buildTableHeader("Institutional Email"),
                                _buildTableHeader("Portal Role"),
                                _buildTableHeader("System Status"),
                                _buildTableHeader("Actions"),
                              ],
                              rows: _filteredProfiles.map((profile) {
                                final String status =
                                    profile['account_status'] ?? 'Active';
                                final String role =
                                    profile['role'] ?? 'Student';
                                final String email =
                                    profile['email'] ?? 'Not set';
                                final String fullName =
                                    "${profile['fn'] ?? ''} ${profile['mn'] ?? ''} ${profile['ln'] ?? ''}"
                                        .trim();

                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                        profile['user_id_number'] ?? '',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold))),
                                    DataCell(Text(fullName,
                                        style: TextStyle(color: titleColor))),
                                    DataCell(Text(email,
                                        style: const TextStyle(
                                            color: Colors.blueGrey))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: aViolet.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: aViolet.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: const TextStyle(
                                              color: aViolet,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ),
                                    DataCell(_buildStatusWidget(status)),
                                    DataCell(
                                      ElevatedButton(
                                        onPressed: () => _toggleAccountStatus(
                                            profile['id'], status),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: status == 'Active'
                                              ? Colors.redAccent
                                                  .withOpacity(0.15)
                                              : Colors.greenAccent
                                                  .withOpacity(0.15),
                                          foregroundColor: status == 'Active'
                                              ? Colors.redAccent
                                              : Colors.greenAccent,
                                          side: BorderSide(
                                              color: status == 'Active'
                                                  ? Colors.redAccent
                                                      .withOpacity(0.4)
                                                  : Colors.greenAccent
                                                      .withOpacity(0.4)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          status == 'Active'
                                              ? "SUSPEND"
                                              : "ACTIVATE",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              letterSpacing: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // VIEW RENDER: Audit Logs Tab
  // ---------------------------------------------------------------------
  Widget _buildAuditLogsDirectory() {
    final bool isDark = widget.isDarkMode;
    final Color titleColor = isDark ? Colors.white : Colors.black87;

    return Column(
      key: const ValueKey(1),
      children: [
        // Controls / Export Actions Bar
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _auditSearchController,
                  style: TextStyle(color: titleColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Search logs by ID, Name, or Email...",
                    hintStyle: TextStyle(color: Colors.blueGrey),
                    prefixIcon:
                        Icon(LucideIcons.search, color: aViolet, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Audit Role Filter Dropdown
            _buildDropdownFilter(
              label: "Role",
              value: _selectedAuditRoleFilter,
              items: [
                'All',
                'Student',
                'Teacher',
                'Professor',
                'PC_Chair',
                'Admin',
                'Registrar',
                'HR',
                'Accounting',
                'Admission'
              ],
              onChanged: (val) {
                setState(() {
                  _selectedAuditRoleFilter = val!;
                  _applyAuditFilters();
                });
              },
            ),
            const SizedBox(width: 12),

            // Audit Status Filter Dropdown
            _buildDropdownFilter(
              label: "Session Type",
              value: _selectedAuditStatusFilter,
              items: ['All', 'Active Session', 'Logged Out'],
              onChanged: (val) {
                setState(() {
                  _selectedAuditStatusFilter = val!;
                  _applyAuditFilters();
                });
              },
            ),
            const SizedBox(width: 12),

            // 📥 EXCEL CONVERTER TRIGGER
            ElevatedButton.icon(
              onPressed: _exportLogsToExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withOpacity(0.15),
                foregroundColor: Colors.greenAccent,
                side: BorderSide(color: Colors.greenAccent.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              label: const Text("EXCEL",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),

            // 📥 PRINT PREVIEW TRIGGER
            ElevatedButton.icon(
              onPressed: _openPrintableReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet.withOpacity(0.15),
                foregroundColor: aViolet,
                side: BorderSide(color: aViolet.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.printer, size: 16),
              label: const Text("PRINT PDF",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Live Logs List Grid
        Expanded(
          child: _isLoadingAudits
              ? const Center(child: CircularProgressIndicator(color: aViolet))
              : _filteredAuditLogs.isEmpty
                  ? const Center(
                      child: Text(
                        "No audit transactions match the current filters.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.black.withOpacity(0.03)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(isDark
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.02)),
                              columnSpacing: 32,
                              columns: [
                                _buildTableHeader("ID Number"),
                                _buildTableHeader("FullName"),
                                _buildTableHeader("Institutional Role"),
                                _buildTableHeader("Login Timestamp"),
                                _buildTableHeader("Logout Timestamp"),
                                _buildTableHeader("Session State"),
                              ],
                              rows: _filteredAuditLogs.map((log) {
                                final profile =
                                    log['profiles'] as Map<String, dynamic>?;
                                final String idNum =
                                    profile?['user_id_number'] ?? 'N/A';
                                final String fullName =
                                    "${profile?['fn'] ?? ''} ${profile?['mn'] ?? ''} ${profile?['ln'] ?? ''}"
                                        .trim();
                                final String role =
                                    profile?['role'] ?? 'Unknown';

                                final String loginTime =
                                    log['check_in_time'] != null
                                        ? DateTime.parse(log['check_in_time'])
                                            .toLocal()
                                            .toString()
                                            .substring(0, 19)
                                        : 'N/A';

                                final String logoutTime =
                                    log['check_out_time'] != null
                                        ? DateTime.parse(log['check_out_time'])
                                            .toLocal()
                                            .toString()
                                            .substring(0, 19)
                                        : 'N/A';

                                final bool isCheckedOut =
                                    log['check_out_time'] != null;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(idNum,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold))),
                                    DataCell(Text(fullName,
                                        style: TextStyle(color: titleColor))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: aViolet.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: aViolet.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: const TextStyle(
                                              color: aViolet,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(loginTime,
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 13))),
                                    DataCell(Text(logoutTime,
                                        style: TextStyle(
                                            color: isCheckedOut
                                                ? Colors.blueGrey
                                                : Colors.greenAccent,
                                            fontSize: 13))),
                                    DataCell(
                                      isCheckedOut
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.checkCircle,
                                                    color: Colors.blueGrey
                                                        .withOpacity(0.5),
                                                    size: 14),
                                                const SizedBox(width: 6),
                                                const Text("Checked Out",
                                                    style: TextStyle(
                                                        color: Colors.blueGrey,
                                                        fontSize: 12)),
                                              ],
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.activity,
                                                    color: Colors.greenAccent,
                                                    size: 14),
                                                const SizedBox(width: 6),
                                                Text("Active Session",
                                                    style: GoogleFonts.inter(
                                                        color:
                                                            Colors.greenAccent,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  DataColumn _buildTableHeader(String label) {
    return DataColumn(
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.blueGrey,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final bool isDark = widget.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? surfaceDark : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold),
          icon: const Icon(LucideIcons.chevronDown, color: aViolet, size: 16),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(String status) {
    final bool isActive = status == 'Active';
    final Color badgeColor = isActive ? Colors.greenAccent : Colors.redAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor,
            boxShadow: [
              BoxShadow(
                  color: badgeColor.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// COMPONENT CLASS: Print Report Preview Overlay Dialog (PDF-Like Layout)
// ---------------------------------------------------------------------
class _PrintReportModal extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> auditLogs;
  final String adminName;

  const _PrintReportModal({
    required this.isDarkMode,
    required this.auditLogs,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    final Color paperBg = isDarkMode ? const Color(0xFF1F1A3A) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    // Calculate quick report parameters
    final totalSessions = auditLogs.length;
    final activeSessions =
        auditLogs.where((l) => l['check_out_time'] == null).length;
    final currentDate = DateTime.now().toLocal().toString().substring(0, 16);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      child: Container(
        width: 900,
        decoration: BoxDecoration(
          color: paperBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5),
          ],
        ),
        child: Column(
          children: [
            // Modal Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.printer, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 12),
                      Text(
                        "Official Auditor Print Preview (UEMSSP Security System)",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // Official Printable Paper Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF16102B)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.blueGrey.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Letterhead Logo & Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BRIGHT FUTURE ACADEMY",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                              const Text(
                                "Unified Education Management System Security core (UEMSSP)",
                                style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                "Official System Audit & Session Tracking Record",
                                style: TextStyle(
                                    color: Colors.blueGrey, fontSize: 10),
                              ),
                            ],
                          ),
                          const Icon(LucideIcons.award,
                              size: 50, color: Color(0xFF8B5CF6)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.blueGrey, thickness: 1.5),
                      const SizedBox(height: 24),

                      // Document Meta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Report Reference: BFA-SEC-${Random().nextInt(90000) + 10000}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.blueGrey)),
                              Text("Generated On: $currentDate",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.blueGrey)),
                              Text("Auditor Operator: $adminName (SysAdmin)",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.blueGrey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Total Logged Sessions: $totalSessions",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.blueGrey)),
                                Text(
                                    "Active Unresolved Sessions: $activeSessions",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Table Header
                      Container(
                        color: Colors.blueGrey.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                                flex: 2,
                                child: Text("ID NUMBER",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.blueGrey))),
                            const Expanded(
                                flex: 3,
                                child: Text("FULL NAME",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.blueGrey))),
                            const Expanded(
                                flex: 2,
                                child: Text("DEPARTMENT",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.blueGrey))),
                            const Expanded(
                                flex: 3,
                                child: Text("LOGIN TIME",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.blueGrey))),
                            const Expanded(
                                flex: 3,
                                child: Text("LOGOUT TIME",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.blueGrey))),
                          ],
                        ),
                      ),

                      // Rows List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: auditLogs.length,
                        itemBuilder: (ctx, idx) {
                          final log = auditLogs[idx];
                          final profile =
                              log['profiles'] as Map<String, dynamic>?;
                          final String idNum =
                              profile?['user_id_number'] ?? 'N/A';
                          final String fullName =
                              "${profile?['fn'] ?? ''} ${profile?['ln'] ?? ''}"
                                  .trim();
                          final String role = (profile?['role'] ?? 'Unknown')
                              .toString()
                              .toUpperCase();

                          final String loginTime = log['check_in_time'] != null
                              ? DateTime.parse(log['check_in_time'])
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16)
                              : 'N/A';

                          final String logoutTime =
                              log['check_out_time'] != null
                                  ? DateTime.parse(log['check_out_time'])
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16)
                                  : 'Active Session';

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color:
                                          Colors.blueGrey.withOpacity(0.08))),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(idNum,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: textColor))),
                                Expanded(
                                    flex: 3,
                                    child: Text(fullName,
                                        style: TextStyle(
                                            fontSize: 11, color: textColor))),
                                Expanded(
                                    flex: 2,
                                    child: Text(role,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 3,
                                    child: Text(loginTime,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blueGrey))),
                                Expanded(
                                    flex: 3,
                                    child: Text(logoutTime,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: log['check_out_time'] != null
                                                ? Colors.blueGrey
                                                : Colors.green,
                                            fontWeight:
                                                log['check_out_time'] == null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal))),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // Signoff Watermark and Lines
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 150,
                                height: 1,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(height: 8),
                              const Text("PREPARED BY: SYSTEM AUDITOR",
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 150,
                                height: 1,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(height: 8),
                              const Text("VERIFIED BY: ACADEMIC REGISTRAR",
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Print Trigger Footer Bar
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor.withOpacity(0.3)),
                    ),
                    child: const Text("CANCEL"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "PDF Command triggered! Report exported successfully."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6)),
                    icon: const Icon(LucideIcons.printer),
                    label: const Text("PRINT SYSTEM REPORT"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
