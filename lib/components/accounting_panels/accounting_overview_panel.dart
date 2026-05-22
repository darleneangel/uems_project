import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class AccountingOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onNavigateToFeeManagement;
  final VoidCallback? onGenerateDailyReport;

  const AccountingOverviewPanel({
    super.key,
    required this.isDarkMode,
    this.onNavigateToFeeManagement,
    this.onGenerateDailyReport,
  });

  @override
  State<AccountingOverviewPanel> createState() =>
      _AccountingOverviewPanelState();
}

class _AccountingOverviewPanelState extends State<AccountingOverviewPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;

  // Analytics State
  double _totalCollections = 0;
  double _pendingReceivables = 0;
  int _pendingClearances = 0;
  List<Map<String, dynamic>> _monthlyTrends = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color.fromARGB(255, 9, 70, 41);
  static const Color surfaceDark = Color(0xFF0F071D);

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Total Successful Payments (Collections)
      final paymentsRes = await _service.client
          .from('payments')
          .select('amount, status, created_at');

      // 2. Fetch Pending Clearances
      final clearanceRes = await _service.client
          .from('office_requests')
          .select('id')
          .eq('request_type', 'Financial Clearance')
          .eq('status', 'Pending');

      // 3. Process Collections Data
      double total = 0;
      double pending = 0;
      Map<String, double> monthlyMap = {};

      for (var p in paymentsRes) {
        double amt = (p['amount'] ?? 0).toDouble();
        if (p['status'] == 'Success') {
          total += amt;
          String month =
              DateFormat('MMM').format(DateTime.parse(p['created_at']));
          monthlyMap[month] = (monthlyMap[month] ?? 0) + amt;
        } else if (p['status'] == 'Pending') {
          pending += amt;
        }
      }

      // 4. Fetch Recent Activity
      final recentRes = await _service.client
          .from('payments')
          .select('*, profiles(fn, ln)')
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _totalCollections = total;
          _pendingReceivables = pending;
          _pendingClearances = clearanceRes.length;
          _recentTransactions = List<Map<String, dynamic>>.from(recentRes);

          // Convert Map to sorted list for the graph
          _monthlyTrends = monthlyMap.entries
              .map((e) => {'month': e.key, 'value': e.value})
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF1E1B4B);
    final secondaryTextColor =
        widget.isDarkMode ? Colors.white70 : Colors.blueGrey.shade700;
    final mutedTextColor = widget.isDarkMode ? Colors.white60 : Colors.blueGrey;
    final dividerColor = widget.isDarkMode ? Colors.white10 : Colors.black12;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor, secondaryTextColor),
          const SizedBox(height: 32),
          _buildStatGrid(textColor),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 3,
                  child: _buildFinancialGraph(
                      cardColor, textColor, mutedTextColor)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 2,
                  child: _buildRecentActivity(
                      cardColor, textColor, mutedTextColor, dividerColor)),
            ],
          ),
          const SizedBox(height: 32),
          _buildClearanceSection(cardColor, textColor, secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Accounting Dashboard",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5)),
            Text(
                "Institutional financial health and real-time ledger analytics.",
                style: TextStyle(color: secondaryTextColor, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _refreshDashboard,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text("SYNC DATA"),
          style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        )
      ],
    );
  }

  Widget _buildStatGrid(Color textColor) {
    return Row(
      children: [
        _statCard("Total Collections", _totalCollections,
            LucideIcons.trendingUp, success),
        const SizedBox(width: 20),
        _statCard("Receivables", _pendingReceivables, LucideIcons.clock,
            Colors.orangeAccent),
        const SizedBox(width: 20),
        _statCard("Pending Clearances", _pendingClearances.toDouble(),
            LucideIcons.fileCheck, aViolet,
            isCurrency: false),
      ],
    );
  }

  Widget _statCard(String label, double val, IconData icon, Color color,
      {bool isCurrency = true}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              widget.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(
              isCurrency
                  ? "₱${NumberFormat('#,###').format(val)}"
                  : val.toInt().toString(),
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
            Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialGraph(
      Color cardColor, Color textColor, Color mutedTextColor) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Collection Trends (Monthly)",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: textColor)),
              const Icon(LucideIcons.barChart3, color: aViolet, size: 20),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _monthlyTrends.isEmpty
                ? Center(
                    child: Text("Insufficient data for trends.",
                        style: TextStyle(color: mutedTextColor)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _monthlyTrends.map((data) {
                      double heightFactor =
                          (data['value'] / _totalCollections).clamp(0.1, 1.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message:
                                "₱${NumberFormat('#,###').format(data['value'])}",
                            child: Container(
                              width: 40,
                              height: 180 * heightFactor,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [aViolet, Color(0xFFC084FC)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(data['month'],
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: mutedTextColor)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Color cardColor, Color textColor,
      Color mutedTextColor, Color dividerColor) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recent Transactions",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, __) =>
                  Divider(color: dividerColor, height: 24),
              itemBuilder: (context, i) {
                final tx = _recentTransactions[i];
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tx['status'] == 'Success'
                          ? success.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      radius: 18,
                      child: Icon(
                          tx['status'] == 'Success'
                              ? LucideIcons.check
                              : LucideIcons.clock,
                          color: tx['status'] == 'Success'
                              ? success
                              : Colors.orange,
                          size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${tx['profiles']['fn']} ${tx['profiles']['ln']}",
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text(
                              DateFormat('MMMM dd')
                                  .format(DateTime.parse(tx['created_at'])),
                              style: TextStyle(
                                  color: mutedTextColor, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text("₱${tx['amount']}",
                        style: GoogleFonts.inter(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceSection(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: aViolet.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: aViolet),
              const SizedBox(width: 12),
              Text("Financial Clearance Queue",
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const Spacer(),
              Text("$_pendingClearances PENDING",
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
              "Verify student eligibility based on real-time academic standing and account balances.",
              style: TextStyle(color: secondaryTextColor, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: 250,
            child: ElevatedButton(
              onPressed: widget.onNavigateToFeeManagement,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(31, 91, 22, 105),
                  foregroundColor: Colors.white),
              child: const Text("OPEN CLEARANCE MODULE"),
            ),
          )
        ],
      ),
    );
  }

  void _showToast(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }
}
