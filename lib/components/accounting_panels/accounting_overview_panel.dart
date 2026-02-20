import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountingOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  const AccountingOverviewPanel({super.key, required this.isDarkMode});

  // Standardized Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF7C3AED);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? surfaceDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : pViolet;
    final subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER DESCRIPTION & QUICK ACTIONS
          _buildTopBanner(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),

          // 2. STAT CARDS ROW
          Row(
            children: [
              _statCard(
                "Total Revenue",
                "₱4,821,000",
                LucideIcons.trendingUp,
                success,
                cardColor,
                textColor,
              ),
              const SizedBox(width: 16),
              _statCard(
                "Outstanding Fees",
                "₱240,500",
                LucideIcons.alertCircle,
                Colors.orangeAccent,
                cardColor,
                textColor,
              ),
              const SizedBox(width: 16),
              _statCard(
                "Active Grants",
                "152",
                LucideIcons.award,
                Colors.blueAccent,
                cardColor,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 3. RECENT TRANSACTIONS TABLE
          _buildTransactionsCard(cardColor, textColor, subTextColor),
          const SizedBox(height: 32),

          // 4. ANALYTICS GRID (Charts)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildChartCard(
                  "Revenue Sources",
                  "Distribution of institutional income",
                  _PieChart(textColor: textColor),
                  cardColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: _buildChartCard(
                  "Monthly Expenses",
                  "Operational and salary disbursements",
                  _BarGraph(),
                  cardColor,
                  textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartCard(
            "Fee Collection Frequency",
            "Distribution of payment amounts processed today",
            _Histogram(),
            cardColor,
            textColor,
            height: 250,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Financial Intelligence Overview",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Real-time visibility into revenue streams, outstanding accountabilities, and institutional disbursements. Use the analytics below to monitor fiscal health.",
                  style: TextStyle(
                    color: subTextColor,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text(
                  "NEW PAYMENT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text(
                  "DAILY REPORT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: textColor.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color cardBg,
    Color text,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsCard(Color cardBg, Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Ledger Activity",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: text,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          _transactionRow(
            "Tuition Settlement - BSCS 4A",
            "Darlene Angel (OR#8821)",
            "+ ₱15,000.00",
            success,
            text,
            subText,
          ),
          _transactionRow(
            "Vendor: Campus IT Supplies",
            "PC Express Disbursement",
            "- ₱42,000.00",
            Colors.redAccent,
            text,
            subText,
          ),
          _transactionRow(
            "Student Enrollment Fee - BSIT",
            "Juan Dela Cruz (OR#9012)",
            "+ ₱8,500.00",
            success,
            text,
            subText,
          ),
        ],
      ),
    );
  }

  Widget _transactionRow(
    String title,
    String sub,
    String amt,
    Color amtColor,
    Color text,
    Color subText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: amtColor.withOpacity(0.1),
            radius: 18,
            child: Icon(
              amt.startsWith('+')
                  ? LucideIcons.arrowDownLeft
                  : LucideIcons.arrowUpRight,
              color: amtColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(sub, style: TextStyle(color: subText, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amt,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              color: amtColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    String sub,
    Widget chart,
    Color cardBg,
    Color text, {
    double height = 200,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: text,
              fontSize: 16,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}

// --- VISUALIZATION COMPONENTS ---

class _PieChart extends StatelessWidget {
  final Color textColor;
  const _PieChart({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(painter: PiePainter()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "70%",
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AccountingOverviewPanel.aViolet,
                ),
              ),
              const Text(
                "TUITION",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    // Background
    paint.color = Colors.blueGrey.withOpacity(0.05);
    canvas.drawCircle(center, radius, paint);

    // Tuition segment
    paint.color = AccountingOverviewPanel.aViolet;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.4, false, paint);

    // Misc segment
    paint.color = Colors.blueAccent;
    canvas.drawArc(rect, math.pi * 0.9, math.pi * 0.4, false, paint);

    // Others
    paint.color = Colors.orangeAccent;
    canvas.drawArc(rect, math.pi * 1.3, math.pi * 0.2, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class _BarGraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<double> values = [0.4, 0.9, 0.6, 0.8, 0.5];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values
          .map(
            (h) => Container(
              width: 35,
              height: 180 * h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AccountingOverviewPanel.aViolet,
                    AccountingOverviewPanel.aViolet.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Histogram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<double> values = [0.3, 0.8, 0.5, 0.2, 0.1];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values
          .map(
            (val) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 200 * val,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
