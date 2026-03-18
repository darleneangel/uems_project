import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class FinancialReportsPanel extends StatelessWidget {
  final bool isDarkMode;
  const FinancialReportsPanel({super.key, required this.isDarkMode});

  // Standardized Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = isDarkMode ? surfaceDark : Colors.white;
    final subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),

          // 1. TOP-LEVEL FISCAL CARDS
          Row(
            children: [
              _reportCard("Income Statement", LucideIcons.trendingUp, cardColor,
                  textColor, "₱4.2M Surplus"),
              _reportCard("Balance Sheet", LucideIcons.layout, cardColor,
                  textColor, "Audited 03/10"),
              _reportCard("Cash Flow", LucideIcons.activity, cardColor,
                  textColor, "Healthy Liquidity"),
            ],
          ),

          const SizedBox(height: 32),

          // 2. THE "HECTIC" LEDGER (Real-time Payment Mirror)
          Text("Institutional Transaction Ledger",
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Text(
              "Live synchronization with GCash/PayMongo settlements and Payroll disbursements.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 24),

          _buildLiveLedger(cardColor, textColor, subTextColor),

          const SizedBox(height: 32),

          // 3. PAYROLL & DISBURSEMENT SUMMARY
          _buildPayrollSummary(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Fiscal Intelligence Hub",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -1)),
          const Text(
              "Consolidated institutional reporting for payroll and collections.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _reportCard(
          String title, IconData icon, Color bg, Color text, String sub) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDarkMode ? Colors.white10 : Colors.black12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: aViolet, size: 32),
              const SizedBox(height: 20),
              Text(title,
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.w900, fontSize: 16)),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text("GENERATE PDF",
                      style: TextStyle(
                          color: aViolet,
                          fontSize: 11,
                          fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      );

  Widget _buildLiveLedger(Color bg, Color text, Color sub) {
    return Container(
      height: 400, // Fixed height prevents the 'mouse_tracker' layout crash
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: isDarkMode ? Colors.white10 : Colors.black12)),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        // REAL-TIME: Mirrors the payments table for transparency
        stream: SupabaseService()
            .client
            .from('payments')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .limit(10),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: aViolet));
          }
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return const Center(
                child: Text("No transactions recorded in current cycle."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: logs.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10),
            itemBuilder: (context, i) {
              final log = logs[i];
              final bool isPositive = log['status'] == 'Paid';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      (isPositive ? success : Colors.orange).withOpacity(0.1),
                  child: Icon(
                      isPositive ? LucideIcons.check : LucideIcons.clock,
                      color: isPositive ? success : Colors.orange,
                      size: 16),
                ),
                title: Text("${log['category']} Settlement",
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                subtitle: Text("Ref: ${log['reference_no'] ?? 'Pending Scan'}",
                    style: TextStyle(color: sub, fontSize: 12)),
                trailing: Text("₱${log['amount_paid']}",
                    style: GoogleFonts.orbitron(
                        color: text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPayrollSummary(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: aViolet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: aViolet.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.users, color: aViolet, size: 40),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Next Faculty Payroll Batch",
                    style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                const Text(
                    "Scheduled for release on March 15. All DTR logs synchronized.",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: aViolet),
              child: const Text("REVIEW DISBURSEMENTS")),
        ],
      ),
    );
  }
}
