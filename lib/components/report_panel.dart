import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class ReportPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ReportPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  final SupabaseService _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _officeCtl = TextEditingController();
  final TextEditingController _categoryCtl = TextEditingController();
  final TextEditingController _descCtl = TextEditingController();

  bool _isSubmitting = false;
  String _selectedPriority = 'Medium';

  // Constants
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  final List<String> _offices = [
    'Admissions',
    'Registrar',
    'Accounting',
    'Finance',
    'HR',
    'Academic Affairs'
  ];

  final List<String> _categories = [
    'System Error',
    'Data Issue',
    'Performance',
    'UI/UX',
    'Integration',
    'Security'
  ];

  /// 🛰️ DATABASE: Submits a new incident report to the ledger
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.client.from('system_reports').insert({
        'office': _officeCtl.text,
        'category': _categoryCtl.text,
        'description': _descCtl.text.trim(),
        'priority': _selectedPriority,
        'status': 'Open',
        'reported_by': widget.userData['id'], // Identity Link
      });

      _clearForm();
      _showToast("Incident Logged to System Archives", success);
    } catch (e) {
      _showToast(
          "Critical Ledger Error: Submission Rejected", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 🛰️ DATABASE: Updates the resolution status of an existing report
  Future<void> _updateReportStatus(String id, String status) async {
    try {
      await _service.client.from('system_reports').update({
        'status': status,
        'resolved_at':
            status == 'Resolved' ? DateTime.now().toIso8601String() : null,
      }).eq('id', id);
      _showToast("System Status Synchronized", aViolet);
    } catch (e) {
      _showToast("Sync Error", Colors.redAccent);
    }
  }

  void _clearForm() {
    _officeCtl.clear();
    _categoryCtl.clear();
    _descCtl.clear();
    setState(() => _selectedPriority = 'Medium');
  }

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
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: Submission Terminal
                Expanded(
                    flex: 4,
                    child: _buildReportingTerminal(cardColor, textColor)),
                const SizedBox(width: 24),
                // RIGHT: System Incident Ledger
                Expanded(
                    flex: 6, child: _buildIncidentLedger(cardColor, textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Health & Error Reports",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          const Text(
              "Monitor institutional platform issues, data inconsistencies, and UI performance feedback.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildReportingTerminal(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NEW INCIDENT LOG",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: aViolet,
                    letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildDropdown("Originating Office", _officeCtl, _offices),
            const SizedBox(height: 16),
            _buildDropdown("Incident Category", _categoryCtl, _categories),
            const SizedBox(height: 16),
            _buildPriorityPicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtl,
              maxLines: 5,
              style: TextStyle(color: text),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Description required" : null,
              decoration: _inputStyle(
                  "Detailed problem description...", LucideIcons.fileText),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(LucideIcons.send),
                label: const Text("TRANSMIT ERROR LOG",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: success,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentLedger(Color bg, Color text) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(LucideIcons.activity, color: aViolet, size: 18),
                const SizedBox(width: 12),
                Text("REAL-TIME SYSTEM INCIDENTS",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, color: text)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.client.from('system_reports').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }
                final list = snapshot.data!;

                if (list.isEmpty) return _emptyState();

                return ListView.separated(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final report = list[i];
                    return _buildReportItem(report, text);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> r, Color text) {
    final timestamp = DateFormat('MMM dd, hh:mm a')
        .format(DateTime.parse(r['created_at']).toLocal());
    final status = r['status'] ?? 'Open';
    final priority = r['priority'] ?? 'Medium';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Text(r['office'] ?? 'System',
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 12),
          _priorityChip(priority),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(r['description'] ?? '',
              style: const TextStyle(
                  color: Colors.blueGrey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Text("$timestamp • ID: ${r['id'].toString().substring(0, 8)}",
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (val) => _updateReportStatus(r['id'], val),
        color: surfaceDark,
        child: _statusChip(status),
        itemBuilder: (context) => ['Open', 'In Progress', 'Resolved', 'Closed']
            .map((s) => PopupMenuItem(
                value: s,
                child: Text(s,
                    style: const TextStyle(color: Colors.white, fontSize: 12))))
            .toList(),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDropdown(
      String label, TextEditingController c, List<String> items) {
    return DropdownButtonFormField<String>(
      dropdownColor: surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: _inputStyle(label, LucideIcons.building),
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: (v) => setState(() => c.text = v ?? ''),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildPriorityPicker() {
    return Row(
      children: ['Low', 'Medium', 'High'].map((p) {
        bool isSelected = _selectedPriority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds:
                      200), // Keep animation duration for smooth transition
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getPriorityColor(p)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(p,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : widget.isDarkMode ? Colors.blueGrey : Colors.black54, // Ensure visibility in light mode
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey),
        hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: aViolet, width: 1)),
      );

  Widget _priorityChip(String p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: _getPriorityColor(p).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(p.toUpperCase(),
            style: TextStyle(
                color: _getPriorityColor(p),
                fontSize: 8,
                fontWeight: FontWeight.w900)),
      );

  Widget _statusChip(String s) {
    Color c = s == 'Resolved'
        ? success
        : (s == 'Open' ? Colors.orangeAccent : Colors.blueAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Color _getPriorityColor(String p) {
    if (p == 'High') return Colors.redAccent;
    if (p == 'Medium') return Colors.orange;
    return Colors.green;
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shieldCheck,
                size: 48, color: Colors.blueGrey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text("System Core is currently stable.",
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
