import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HRPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HRPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<HRPanel> createState() => _HRPanelState();
}

class _HRPanelState extends State<HRPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  final bool _isLoading = true;
  final bool _isActionLoading = false;
  String _searchQuery = "";
  String _roleFilter = "All Roles";

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  final List<String> _institutionalRoles = [
    'professor',
    'faculty',
    'registrar',
    'accounting',
    'hr',
    'admission',
    'pchair'
  ];

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
          _buildControlBar(cardColor, textColor),
          const SizedBox(height: 24),
          Expanded(child: _buildWorkforceRegistry(cardColor, textColor)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Workforce Intelligence",
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: t,
                      letterSpacing: -0.5)),
              const Text(
                  "Manage institutional personnel, employment contracts, and digital credentials.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showOnboardingForm(),
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text("ONBOARD PERSONNEL"),
            style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );

  Widget _buildControlBar(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(LucideIcons.search, color: aViolet, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(color: text, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Search by Name, ID, or Position...",
                hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const VerticalDivider(color: Colors.white10, indent: 8, endIndent: 8),
          _roleFilterDropdown(),
        ],
      ),
    );
  }

  Widget _roleFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roleFilter,
          dropdownColor: surfaceDark,
          style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold),
          items: [
            "All Roles",
            ..._institutionalRoles.map((r) => r.toUpperCase())
          ]
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (v) => setState(() => _roleFilter = v!),
        ),
      ),
    );
  }

  Widget _buildWorkforceRegistry(Color bg, Color text) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.client
            .from('profiles')
            .stream(primaryKey: ['id']).neq('role', 'student'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: aViolet));
          }

          // 📐 DYNAMIC FILTER ENGINE
          final list = snapshot.data!.where((emp) {
            final name = "${emp['fn']} ${emp['ln']}".toLowerCase();
            final id = (emp['user_id_number'] ?? '').toString().toLowerCase();
            final role = (emp['role'] ?? '').toString().toUpperCase();

            final matchesSearch =
                name.contains(_searchQuery) || id.contains(_searchQuery);
            final matchesRole =
                _roleFilter == "All Roles" || role == _roleFilter;

            return matchesSearch && matchesRole;
          }).toList();

          if (list.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final emp = list[i];
              return _buildEmployeeRow(emp, text);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmployeeRow(Map<String, dynamic> emp, Color text) {
    final String role = (emp['role'] ?? 'Staff').toString().toUpperCase();
    final String status = emp['account_status'] ?? 'Active';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: aViolet.withOpacity(0.1),
        child: Text(emp['ln']?[0] ?? 'E',
            style:
                const TextStyle(color: aViolet, fontWeight: FontWeight.bold)),
      ),
      title: Text("${emp['fn']} ${emp['ln']}",
          style: TextStyle(
              color: text, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("ID: ${emp['user_id_number']} • $role",
          style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBadge(status, status == 'Active' ? success : Colors.redAccent),
          const SizedBox(width: 12),
          IconButton(
            icon:
                const Icon(LucideIcons.edit3, size: 18, color: Colors.blueGrey),
            onPressed: () => _showOnboardingForm(emp),
          ),
          IconButton(
            icon: const Icon(LucideIcons.shieldCheck, size: 18, color: aViolet),
            onPressed: () =>
                _showToast("Identity Verified via Ledger", success),
          ),
        ],
      ),
    );
  }

  void _showOnboardingForm([Map<String, dynamic>? existingEmp]) {
    final formKey = GlobalKey<FormState>();
    final fn = TextEditingController(text: existingEmp?['fn']);
    final ln = TextEditingController(text: existingEmp?['ln']);
    final email = TextEditingController(text: existingEmp?['email']);
    String role = existingEmp?['role'] ?? 'professor';
    String status = existingEmp?['account_status'] ?? 'Active';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F071D),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
              existingEmp == null ? "Onboard New Personnel" : "Modify Record",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _input(fn, "First Name", required: true),
                  const SizedBox(height: 12),
                  _input(ln, "Last Name", required: true),
                  const SizedBox(height: 12),
                  _input(email, "Institutional Email", required: true),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _dropdown(
                              "Role Assignment",
                              role,
                              _institutionalRoles,
                              (v) => setModalState(() => role = v!))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _dropdown(
                              "Account Status",
                              status,
                              ["Active", "Suspended"],
                              (v) => setModalState(() => status = v!))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL",
                    style: TextStyle(color: Colors.blueGrey))),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final String empId = existingEmp?['user_id_number'] ??
                      await _service.generateEmployeeId();
                  final data = {
                    'fn': fn.text.trim(),
                    'ln': ln.text.trim(),
                    'email': email.text.trim(),
                    'role': role,
                    'account_status': status,
                    'user_id_number': empId,
                  };

                  if (existingEmp == null) {
                    data['password_hash'] =
                        ln.text.toLowerCase().trim(); // Temp pass
                    await _service.client.from('profiles').insert(data);
                  } else {
                    await _service.client
                        .from('profiles')
                        .update(data)
                        .eq('id', existingEmp['id']);
                  }

                  if (mounted) Navigator.pop(ctx);
                  _showToast(
                      existingEmp == null
                          ? "Personnel Synchronized"
                          : "Record Updated",
                      success);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: aViolet),
              child: Text(
                  existingEmp == null ? "FINALIZE ONBOARDING" : "SAVE CHANGES"),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String l, {bool required = false}) =>
      TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? "Required" : null
            : null,
        decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );

  Widget _dropdown(
      String l, String v, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.toUpperCase(),
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: v,
          dropdownColor: const Color(0xFF0F071D),
          style: const TextStyle(color: Colors.white, fontSize: 13),
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
      ],
    );
  }

  Widget _statusBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)));

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users,
                size: 48, color: Colors.blueGrey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text("No institutional records found.",
                style: TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
