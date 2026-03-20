import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class HRPayrollBridgePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HRPayrollBridgePanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<HRPayrollBridgePanel> createState() => _HRPayrollBridgePanelState();
}

class _HRPayrollBridgePanelState extends State<HRPayrollBridgePanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _payrollData = [];
  bool _isLoading = true;
  String _activeFilter = 'All';

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  Future<void> _fetchPayrollData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.client
          .from('payroll_inputs')
          .select('*, profiles(fn, ln, user_id_number, role)')
          .order('last_updated', ascending: false);

      setState(() {
        _payrollData = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Payroll Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Payroll Bridge",
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const Text(
                      "Consolidate and submit payroll inputs to Accounting.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  _filterChip("All", _activeFilter == 'All',
                      () => setState(() => _activeFilter = 'All')),
                  _filterChip("Draft", _activeFilter == 'Draft',
                      () => setState(() => _activeFilter = 'Draft')),
                  _filterChip("Submitted", _activeFilter == 'Submitted',
                      () => setState(() => _activeFilter = 'Submitted')),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _fetchPayrollData,
                    icon: const Icon(LucideIcons.refreshCw,
                        size: 20, color: aViolet),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),

          // --- SUMMARY CARDS ---
          _buildSummaryCards(cardColor, textColor),
          const SizedBox(height: 32),

          // --- SEARCH ---
          _buildSearchBar(cardColor, textColor),
          const SizedBox(height: 24),

          // --- TABLE ---
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: widget.isDarkMode
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: aViolet))
                  : _buildPayrollTable(textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Color cardColor, Color textColor) {
    double totalNet = 0;
    int pendingDrafts = 0;

    for (var item in _payrollData) {
      totalNet += (item['net_pay_calculated'] ?? 0).toDouble();
      if (item['status'] == 'Draft') pendingDrafts++;
    }

    return Row(
      children: [
        _statCard(
            "Total Calculated Net",
            "₱${NumberFormat('#,###.00').format(totalNet)}",
            LucideIcons.banknote,
            Colors.blue),
        const SizedBox(width: 20),
        _statCard("Pending Drafts", pendingDrafts.toString(),
            LucideIcons.fileEdit, Colors.orange),
        const SizedBox(width: 20),
        _statCard("Next Pay Period", "Mar 16 - Mar 31", LucideIcons.calendar,
            aViolet),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 16),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(0xFF1E1B4B))),
            Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollTable(Color textColor) {
    final filtered = _payrollData.where((item) {
      final name =
          "${item['profiles']['fn']} ${item['profiles']['ln']}".toLowerCase();
      final matchesSearch = name.contains(_searchController.text.toLowerCase());
      final matchesStatus =
          _activeFilter == 'All' || item['status'] == _activeFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.receipt,
              size: 48, color: Colors.blueGrey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No payroll records found.",
              style: TextStyle(
                  color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ],
      ));
    }

    return Column(
      children: [
        _tableHeader([
          'STAFF',
          'BASE SALARY',
          'OT / ADJ',
          'DEDUCTIONS',
          'NET PAY',
          'STATUS',
          'ACTION'
        ]),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final item = filtered[i];
              final profile = item['profiles'];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${profile['fn']} ${profile['ln']}",
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            Text(profile['role'].toString().toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        )),
                    Expanded(
                        child: Text("₱${item['base_salary']}",
                            style: GoogleFonts.inter(fontSize: 13))),
                    Expanded(
                        child: Text("₱${item['overtime_pay']}",
                            style:
                                const TextStyle(color: success, fontSize: 13))),
                    Expanded(
                        child: Text(
                            "₱${(item['deductions_tax'] + item['deductions_other'])}",
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13))),
                    Expanded(
                        child: Text("₱${item['net_pay_calculated']}",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900, color: aViolet))),
                    Expanded(child: _statusChip(item['status'])),
                    Expanded(
                        child: item['status'] == 'Draft'
                            ? TextButton(
                                onPressed: () =>
                                    _submitToAccounting(item['id']),
                                child: const Text("SUBMIT",
                                    style: TextStyle(
                                        color: aViolet,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              )
                            : const Icon(LucideIcons.checkCircle2,
                                color: success, size: 18)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(List<String> titles) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF8FAFC),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Row(
            children: titles
                .map((t) => Expanded(
                    flex: t == 'STAFF' ? 2 : 1,
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey,
                            letterSpacing: 1.2))))
                .toList()),
      );

  Widget _buildSearchBar(Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05))),
        child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: text),
            decoration: const InputDecoration(
                hintText: "Search payroll entries...",
                border: InputBorder.none,
                prefixIcon: Icon(LucideIcons.search,
                    size: 18, color: Colors.blueGrey))),
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold))),
      );

  Widget _statusChip(String status) {
    Color color = status == 'Processed'
        ? success
        : (status == 'Submitted' ? Colors.blue : Colors.orangeAccent);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontSize: 9, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center));
  }

  Future<void> _submitToAccounting(String id) async {
    try {
      await _service.client
          .from('payroll_inputs')
          .update({'status': 'Submitted'}).eq('id', id);
      _fetchPayrollData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Payroll input submitted to Accounting."),
          backgroundColor: success));
    } catch (e) {
      debugPrint("Submission Error: $e");
    }
  }
}
