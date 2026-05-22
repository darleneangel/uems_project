import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../services/supabase_service.dart';

class EmployeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const EmployeeManagementPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<EmployeeManagementPanel> createState() =>
      _EmployeeManagementPanelState();
}

class _EmployeeManagementPanelState extends State<EmployeeManagementPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  bool _showArchived = false;
  bool _isSalaryMode = false;

  // Visual Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('profiles')
          .select('*, employee_details(*)')
          .neq('role', 'student')
          .order('ln', ascending: true);

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📧 SMTP CREDENTIAL DISPATCH ENGINE
  Future<void> _sendOnboardingEmail({
    required String recipientEmail,
    required String employeeName,
    required String employeeId,
    required String tempPassword,
    required String role,
  }) async {
    const String senderEmail = 'lustredarlene45@gmail.com';
    const String appPassword = 'xzgk bybb hiqh hrxh';
    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = const Address(senderEmail, 'UEMSSP Human Resources')
      ..recipients.add(recipientEmail)
      ..subject = 'Official Employment Credentials - Bright Future Academy'
      ..html = """
        <div style='font-family: sans-serif; max-width: 500px; margin: auto; border: 1px solid #e2e8f0; border-radius: 24px; overflow: hidden;'>
          <div style='background-color: #2E1065; padding: 40px; text-align: center;'>
            <h1 style='color: white; margin: 0; font-size: 24px;'>WELCOME TO THE TEAM</h1>
            <p style='color: #a78bfa; font-size: 12px; margin-top: 10px;'>Official Staff Credentials</p>
          </div>
          <div style='padding: 30px; background-color: #ffffff;'>
            <p>Hello <b>$employeeName</b>,</p>
            <p>Welcome to Bright Future Academy! You have been officially onboarded as <b>${role.toUpperCase()}</b>. Your institutional portal credentials are below:</p>
            
            <div style='background-color: #f8fafc; padding: 20px; border-radius: 12px; margin: 20px 0; border: 1px dashed #cbd5e1;'>
              <p style='margin: 0; font-size: 11px; color: #64748b;'>EMPLOYEE ID NUMBER</p>
              <p style='margin: 5px 0 15px 0; font-size: 22px; font-weight: bold; color: #8B5CF6; letter-spacing: 2px;'>$employeeId</p>
              
              <p style='margin: 0; font-size: 11px; color: #64748b;'>TEMPORARY PASSWORD</p>
              <p style='margin: 5px 0 0 0; font-size: 18px; font-weight: bold; color: #1e293b;'>$tempPassword</p>
            </div>
            
            <p style='font-size: 13px; color: #475569;'>You are <b>required</b> to change this password immediately upon your first login for security compliance.</p>
          </div>
        </div>
      """;
    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP Onboarding Error: $e');
    }
  }

  /// 🛰️ DATABASE: Secure Onboarding Transaction
  Future<void> _finalizeOnboarding(Map<String, dynamic> profileData,
      Map<String, dynamic> detailsData, bool isNew) async {
    setState(() => _isLoading = true);
    try {
      if (isNew) {
        // 1. Generate Employee ID
        final String empId = await _service.generateEmployeeId();
        profileData['user_id_number'] = empId;

        // 2. Generate Temp Password (ln lowercase)
        final String tempPass =
            profileData['ln'].toString().toLowerCase().trim();
        profileData['password_hash'] = tempPass;

        // 3. Atomically Onboard
        await _service.onboardEmployee(
            profileData: profileData, detailsData: detailsData);

        // 4. Dispatch Email
        _sendOnboardingEmail(
            recipientEmail: profileData['email'],
            employeeName: "${profileData['fn']} ${profileData['ln']}",
            employeeId: empId,
            tempPassword: tempPass,
            role: profileData['role']);

        _showSuccessDialog(empId, profileData['fn'], profileData['email']);
      } else {
        // Standard Update logic
        await _service.client
            .from('profiles')
            .update(profileData)
            .eq('id', profileData['id']);
        await _service.client
            .from('employee_details')
            .update(detailsData)
            .eq('profile_id', profileData['id']);
        _showToast("Contract record updated.", success);
      }
      _fetchEmployees();
    } catch (e) {
      _showToast("Onboarding Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  void _showEmployeeForm([Map<String, dynamic>? emp]) {
    final details = emp?['employee_details'];
    final formKey = GlobalKey<FormState>();

    final fn = TextEditingController(text: emp?['fn']);
    final mn = TextEditingController(text: details?['middle_name']);
    final ln = TextEditingController(text: emp?['ln']);
    final email = TextEditingController(text: emp?['email']);
    final tin = TextEditingController(text: details?['tin_number']);
    final sss = TextEditingController(text: details?['sss_number']);
    final phil = TextEditingController(text: details?['philhealth_id']);
    final pagi = TextEditingController(text: details?['pagibig_id']);

    String role = emp?['role'] ?? 'teacher';
    String contractType = details?['contract_type'] ?? 'Probational';
    final pos = TextEditingController(text: details?['position_title']);
    final salary =
        TextEditingController(text: details?['base_salary']?.toString() ?? "0");
    final sssLoan = TextEditingController(
        text: details?['sss_loan_monthly']?.toString() ?? "0");
    final rental = TextEditingController(
        text: details?['rental_deduction']?.toString() ?? "0");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F071D),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Row(
            children: [
              const Icon(LucideIcons.fileSignature, color: aViolet),
              const SizedBox(width: 12),
              Text(emp == null ? "Institutional Onboarding" : "Contract Update",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 900,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("I. PERSONAL IDENTITY"),
                    Row(
                      children: [
                        Expanded(
                            child: _input(fn, "First Name", required: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _input(mn, "Middle Name", required: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _input(ln, "Last Name", required: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _input(email, "Personal Email (For Credential Dispatch)",
                        required: true),
                    const SizedBox(height: 32),
                    _sectionHeader("II. GOVERNMENT IDENTIFIERS"),
                    Row(
                      children: [
                        Expanded(
                            child: _input(tin, "TIN Number", required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _input(sss, "SSS ID", required: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child:
                                _input(phil, "PhilHealth ID", required: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _input(pagi, "Pag-IBIG ID", required: true)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader("III. EMPLOYMENT CONTRACT"),
                    Row(
                      children: [
                        Expanded(
                            child: _dropdown(
                                "Classification",
                                role,
                                [
                                  "teacher",
                                  "registrar",
                                  "accounting",
                                  "hr",
                                  "admin",
                                  "program_chair"
                                ],
                                (v) => setModalState(() => role = v!))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dropdown(
                                "Status",
                                contractType,
                                ["Probational", "Regular", "Part-time"],
                                (v) => setModalState(() => contractType = v!))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _input(pos, "Position Title", required: true),
                    const SizedBox(height: 12),
                    _input(salary, "Base Gross Salary",
                        isNumeric: true, isSalary: true, required: true),
                    const SizedBox(height: 32),
                    _sectionHeader("IV. MONTHLY DEDUCTIONS"),
                    Row(
                      children: [
                        Expanded(
                            child: _input(sssLoan, "SSS Loan",
                                isNumeric: true, required: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _input(rental, "Institutional Rental",
                                isNumeric: true, required: true)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _finalizeOnboarding({
                    if (emp != null) 'id': emp['id'],
                    'fn': fn.text,
                    'mn': mn.text,
                    'ln': ln.text,
                    'email': email.text,
                    'role': role,
                  }, {
                    'middle_name': mn.text,
                    'tin_number': tin.text,
                    'sss_number': sss.text,
                    'philhealth_id': phil.text,
                    'pagibig_id': pagi.text,
                    'contract_type': contractType,
                    'position_title': pos.text,
                    'base_salary': double.tryParse(salary.text) ?? 0.0,
                    'sss_loan_monthly': double.tryParse(sssLoan.text) ?? 0.0,
                    'rental_deduction': double.tryParse(rental.text) ?? 0.0,
                  }, emp == null);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.isDarkMode ? aViolet : const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
              child: Text(
                  emp == null ? "GENERATE ID & ONBOARD" : "UPDATE CONTRACT",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String id, String name, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(LucideIcons.partyPopper, color: success, size: 64),
            const SizedBox(height: 24),
            Text("Onboarding Complete",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white)),
            Text("$name is now part of the institution.",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text("ASSIGNED EMPLOYEE ID",
                      style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(id,
                      style: GoogleFonts.inter(
                          color: aViolet,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Credentials dispatched to $email",
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: aViolet, foregroundColor: Colors.white),
                  child: const Text("DONE")),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final actionButtonColor =
        widget.isDarkMode ? aViolet : const Color(0xFF6D28D9);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _isSalaryMode
                        ? "Contracts & Salary"
                        : "Workforce Directory",
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
                const Text(
                    "Personnel contract management and digital identity vault.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
              ],
            ),
            Row(
              children: [
                _filterChip("Directory", !_isSalaryMode,
                    () => setState(() => _isSalaryMode = false)),
                _filterChip("Salary & Contracts", _isSalaryMode,
                    () => setState(() => _isSalaryMode = true)),
                const VerticalDivider(width: 32, color: Colors.white10),
                _filterChip("Active", !_showArchived,
                    () => setState(() => _showArchived = false)),
                _filterChip("Archived", _showArchived,
                    () => setState(() => _showArchived = true)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showEmployeeForm(),
                  icon: const Icon(LucideIcons.userPlus, color: Colors.white),
                  label: const Text(
                    "ONBOARD STAFF",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: actionButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18)),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),
        _buildSearchBar(cardColor, textColor),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10)),
                  child: _isSalaryMode
                      ? _buildSalarySubmodule(textColor)
                      : _buildDirectoryList(textColor),
                ),
        ),
      ],
    );
  }

  Widget _buildDirectoryList(Color textColor) {
    final list = _filteredList;
    return ListView.separated(
      itemCount: list.length,
      padding: const EdgeInsets.all(24),
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, i) {
        final e = list[i];
        final details = e['employee_details'];
        return ListTile(
          leading: CircleAvatar(
              backgroundColor: aViolet.withOpacity(0.1),
              child: Text(e['ln'][0],
                  style: const TextStyle(
                      color: aViolet, fontWeight: FontWeight.bold))),
          title: Text("${e['fn']} ${e['ln']}",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          subtitle: Text(
              "${details?['position_title'] ?? 'No Position'} • ID: ${e['user_id_number']}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: const Icon(LucideIcons.edit3, size: 18),
                  onPressed: () => _showEmployeeForm(e)),
              IconButton(
                  icon: Icon(
                      _showArchived
                          ? LucideIcons.refreshCcw
                          : LucideIcons.archive,
                      size: 18,
                      color: _showArchived ? success : Colors.orangeAccent),
                  onPressed: () => _toggleArchive(e['id'], !_showArchived)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalarySubmodule(Color textColor) {
    final list = _filteredList;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(flex: 3, child: _tableHead("EMPLOYEE NAME")),
              Expanded(flex: 2, child: _tableHead("POSITION")),
              Expanded(flex: 2, child: _tableHead("GROSS SALARY")),
              const SizedBox(width: 100),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              final details = e['employee_details'];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10))),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text("${e['ln']}, ${e['fn']}",
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13))),
                    Expanded(
                        flex: 2,
                        child: Text(details?['position_title'] ?? 'N/A',
                            style: const TextStyle(
                                color: Colors.blueGrey, fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            "₱${details?['base_salary']?.toStringAsFixed(2) ?? '0.00'}",
                            style: GoogleFonts.orbitron(
                                color: success,
                                fontWeight: FontWeight.bold,
                                fontSize: 14))),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                          onPressed: () => _showEmployeeForm(e),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: aViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          child: const Text(
                            "INCREMENT",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(fontSize: 10),
                          )),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color bg, Color text) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: text),
          decoration: const InputDecoration(
              hintText: "Filter workforce...",
              border: InputBorder.none,
              prefixIcon: Icon(LucideIcons.search, size: 18)),
        ),
      );

  Widget _sectionHeader(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(t,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: aViolet,
              letterSpacing: 1.5)));

  Widget _input(TextEditingController c, String h,
          {bool isNumeric = false,
          bool isSalary = false,
          bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? "Required" : null
              : null,
          decoration: InputDecoration(
            labelText: h,
            prefixText: isSalary ? "₱ " : null,
            labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _dropdown(String label, String value, List<String> items,
          Function(String?) onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: value,
              dropdownColor: surfaceDark,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
              items: items
                  .map((i) =>
                      DropdownMenuItem(value: i, child: Text(i.toUpperCase())))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      );

  Widget _filterChip(String l, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: active ? aViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? Colors.transparent : Colors.white10)),
          child: Text(l,
              style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      );

  Widget _tableHead(String t) => Text(t,
      style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1));

  List<Map<String, dynamic>> get _filteredList {
    return _employees.where((e) {
      final details = e['employee_details'];
      final bool isArchived = details?['employment_status'] == 'Archived';
      final bool matchesArchiveFilter =
          _showArchived ? isArchived : !isArchived;
      final bool matchesSearch = "${e['fn']} ${e['ln']}"
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesArchiveFilter && matchesSearch;
    }).toList();
  }

  Future<void> _toggleArchive(String profileId, bool archive) async {
    try {
      await _service.client
          .from('employee_details')
          .update({'employment_status': archive ? 'Archived' : 'Active'}).eq(
              'profile_id', profileId);
      _fetchEmployees();
    } catch (e) {
      debugPrint("Archive Error: $e");
    }
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
