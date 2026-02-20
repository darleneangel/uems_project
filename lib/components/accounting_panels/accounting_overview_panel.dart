import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountingOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onNavigateToFeeManagement;
  final VoidCallback? onGenerateDailyReport;

  const AccountingOverviewPanel({
    super.key,
    required this.isDarkMode,
    this.onNavigateToFeeManagement,
    this.onGenerateDailyReport,
  });

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
<<<<<<< HEAD
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
=======
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),
          // Quick Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onNavigateToFeeManagement ?? () {},
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text("NEW PAYMENT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onGenerateDailyReport ?? () {},
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text("GENERATE DAILY REPORT"),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
>>>>>>> ade0bf853b14f953354f82427841c11017197893
              _statCard(
                "Total Revenue",
                "₱4,821,000",
                LucideIcons.trendingUp,
<<<<<<< HEAD
                success,
=======
                const Color(0xFF69F0AE),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
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
<<<<<<< HEAD
=======
                subTextColor,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
              ),
            ],
          ),
          const SizedBox(height: 32),
<<<<<<< HEAD

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
=======
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent Transactions",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _transactionRow(
                  "Tuition Payment - BSCS 2A",
                  "Student #2024-001",
                  "+ ₱15,000.00",
                  const Color(0xFF69F0AE),
                  textColor,
                  subTextColor,
                ),
                _transactionRow(
                  "Vendor Payment - IT Supplies",
                  "PC Express Inc.",
                  "- ₱42,000.00",
                  Colors.redAccent,
                  textColor,
                  subTextColor,
                ),
                _transactionRow(
                  "Tuition Payment - BSIT 1B",
                  "Student #2024-089",
                  "+ ₱8,500.00",
                  const Color(0xFF69F0AE),
                  textColor,
                  subTextColor,
                ),
                _transactionRow(
                  "Payroll Disbursement",
                  "Faculty Dept.",
                  "- ₱1,200,000.00",
                  Colors.redAccent,
                  textColor,
                  subTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildPieChartCard(cardColor, textColor, subTextColor),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: _buildBarGraphCard(cardColor, textColor, subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 350,
            child: _buildHistogramCard(cardColor, textColor, subTextColor),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildTrendCard(cardColor, textColor, subTextColor),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildPerformanceCard(cardColor, textColor, subTextColor),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
              ),
            ],
          ),
        ],
      ),
<<<<<<< HEAD
=======
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.barChart3, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Financial Overview Dashboard",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Real-time financial metrics and analytics",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
<<<<<<< HEAD
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
=======
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
        ),
        child: Column(
          children: [
<<<<<<< HEAD
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
=======
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 24,
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
<<<<<<< HEAD
    String sub,
    String amt,
    Color amtColor,
    Color text,
    Color subText,
=======
    String subtitle,
    String amount,
    Color color,
    Color textColor,
    Color subTextColor,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
<<<<<<< HEAD
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
=======
>>>>>>> ade0bf853b14f953354f82427841c11017197893
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
<<<<<<< HEAD
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(sub, style: TextStyle(color: subText, fontSize: 12)),
=======
                  style: GoogleFonts.inter(color: textColor),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
              ],
            ),
          ),
          Text(
            amt,
            style: GoogleFonts.inter(
<<<<<<< HEAD
              fontWeight: FontWeight.w900,
              color: amtColor,
              fontSize: 14,
=======
              color: color,
              fontWeight: FontWeight.bold,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildPieChartCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
<<<<<<< HEAD
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
=======
            "Revenue Distribution",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _PieChartPainter(isDarkMode),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _legendItem("Tuition Fees", const Color(0xFF8B5CF6)),
          _legendItem("Laboratory Fees", const Color(0xFF69F0AE)),
          _legendItem("Miscellaneous", Colors.orangeAccent),
>>>>>>> ade0bf853b14f953354f82427841c11017197893
        ],
      ),
    );
  }
<<<<<<< HEAD
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
=======

  Widget _buildBarGraphCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Revenue",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _BarGraphPainter(isDarkMode),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistogramCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transaction Volume Analysis",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _HistogramPainter(isDarkMode),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenue Trend",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _TrendLinePainter(isDarkMode),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "↑ 12.5%",
                style: GoogleFonts.inter(
                  color: const Color(0xFF69F0AE),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "vs last month",
                style: GoogleFonts.inter(
                  color: subTextColor,
                  fontSize: 12,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

<<<<<<< HEAD
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
=======
  Widget _buildPerformanceCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Collection Performance",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _PerformanceBarPainter(isDarkMode),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "85.2% Rate",
                style: GoogleFonts.inter(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
>>>>>>> ade0bf853b14f953354f82427841c11017197893
                ),
              ),
              Text(
                "Excellent",
                style: GoogleFonts.inter(
                  color: subTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
<<<<<<< HEAD
          )
          .toList(),
    );
  }
=======
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final bool isDarkMode;
  
  _PieChartPainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    final sections = [
      {'value': 0.6, 'color': const Color(0xFF8B5CF6)},
      {'value': 0.3, 'color': const Color(0xFF69F0AE)},
      {'value': 0.1, 'color': Colors.orangeAccent},
    ];
    
    double startAngle = -math.pi / 2;
    
    for (final section in sections) {
      final sweepAngle = (section['value'] as double) * 2 * math.pi;
      final paint = Paint()
        ..color = section['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarGraphPainter extends CustomPainter {
  final bool isDarkMode;
  
  _BarGraphPainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 8;
    final data = [0.8, 0.6, 0.9, 0.7, 0.85, 0.75];
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFF69F0AE),
      Colors.orangeAccent,
      const Color(0xFF8B5CF6),
      const Color(0xFF69F0AE),
      Colors.orangeAccent,
    ];
    
    for (int i = 0; i < data.length; i++) {
      final height = data[i] * size.height * 0.8;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * barWidth + barWidth * 0.5,
            size.height - height,
            barWidth * 0.8,
            height,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HistogramPainter extends CustomPainter {
  final bool isDarkMode;
  
  _HistogramPainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 20;
    final data = [
      0.3, 0.5, 0.8, 0.6, 0.9, 0.7, 0.4, 0.8, 0.6, 0.7,
      0.5, 0.9, 0.8, 0.6, 0.7, 0.8, 0.9, 0.7, 0.6, 0.8
    ];
    
    for (int i = 0; i < data.length; i++) {
      final height = data[i] * size.height * 0.8;
      final paint = Paint()
        ..color = isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF2E1065)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - height,
          barWidth * 0.8,
          height,
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrendLinePainter extends CustomPainter {
  final bool isDarkMode;
  
  _TrendLinePainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF2E1065)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width, size.height * 0.3),
    ];
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF2E1065)
      ..style = PaintingStyle.fill;
    
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerformanceBarPainter extends CustomPainter {
  final bool isDarkMode;
  
  _PerformanceBarPainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 6;
    final colors = [
      const Color(0xFF69F0AE),
      const Color(0xFF8B5CF6),
      const Color(0xFFFF6B35),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];
    
    for (int i = 0; i < 6; i++) {
      final height = [0.8, 0.95, 0.6, 0.75, 0.9, 0.65][i] * size.height;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * barWidth, size.height - height, barWidth - 4, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
>>>>>>> ade0bf853b14f953354f82427841c11017197893
}
