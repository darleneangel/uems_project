// c:\Users\Darlene Angel\uems_project\lib\components\accounting_panels\accounting_overview_panel.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountingOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  const AccountingOverviewPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartDescription(cardColor, textColor, subTextColor),
        const SizedBox(height: 24),
        // Quick Actions
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {}, // Navigate to Fee Management
              icon: const Icon(LucideIcons.plusCircle, size: 16),
              label: const Text("NEW PAYMENT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.fileText, size: 16),
              label: const Text("GENERATE DAILY REPORT"),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _statCard(
              "Total Revenue",
              "₱4,821,000",
              LucideIcons.trendingUp,
              const Color(0xFF69F0AE),
              cardColor,
              textColor,
              subTextColor,
            ),
            const SizedBox(width: 16),
            _statCard(
              "Outstanding Fees",
              "₱240,500",
              LucideIcons.alertCircle,
              Colors.orangeAccent,
              cardColor,
              textColor,
              subTextColor,
            ),
            const SizedBox(width: 16),
            _statCard(
              "Active Grants",
              "152",
              LucideIcons.award,
              Colors.blueAccent,
              cardColor,
              textColor,
              subTextColor,
            ),
          ],
        ),
        const SizedBox(height: 32),
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
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Expanded(
      child: Container(
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionRow(
    String title,
    String subtitle,
    String amount,
    Color amountColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              amount.startsWith('+')
                  ? LucideIcons.arrowDownLeft
                  : LucideIcons.arrowUpRight,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartDescription(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial Analytics & Chart Breakdown",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "This dashboard visualizes key financial metrics. The Pie Chart details revenue sources dominated by Tuition (70%). "
            "The Bar Graph tracks monthly expenses showing stability. The Histogram analyzes fee collection frequency, peaking in the 1k-5k range.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: subTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _breakdownItem(
                "Revenue Dominance",
                "Tuition (70%)",
                Colors.deepPurpleAccent,
                textColor,
                subTextColor,
              ),
              _breakdownItem(
                "Expense Trend",
                "Stable / Low Variance",
                Colors.orangeAccent,
                textColor,
                subTextColor,
              ),
              _breakdownItem(
                "Peak Collection",
                "1k - 5k Range",
                Colors.tealAccent,
                textColor,
                subTextColor,
              ),
              _breakdownItem(
                "Net Cash Flow",
                "Positive (+15%)",
                const Color(0xFF69F0AE),
                textColor,
                subTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownItem(
    String label,
    String value,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(LucideIcons.activity, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: subTextColor),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildPieChartCard(
  Color cardColor,
  Color textColor,
  Color subTextColor,
) {
  return Container(
    height: 350,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: cardColor == Colors.white ? Colors.black12 : Colors.white10,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Revenue Sources",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _PieChartPainter(),
                child: Center(
                  child: Text(
                    "₱4.8M",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _chartLegend("Tuition", Colors.deepPurpleAccent),
            _chartLegend("Misc.", Colors.blueAccent),
            _chartLegend("Other", Colors.orangeAccent),
          ],
        ),
      ],
    ),
  );
}

Widget _buildBarGraphCard(
  Color cardColor,
  Color textColor,
  Color subTextColor,
) {
  return Container(
    height: 350,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: cardColor == Colors.white ? Colors.black12 : Colors.white10,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Expenses",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CustomPaint(
            painter: _BarGraphPainter(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHistogramCard(
  Color cardColor,
  Color textColor,
  Color subTextColor,
) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: cardColor == Colors.white ? Colors.black12 : Colors.white10,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fee Collection Frequency (Histogram)",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          "Distribution of payment amounts processed today",
          style: GoogleFonts.inter(fontSize: 12, color: subTextColor),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CustomPaint(
            painter: _HistogramPainter(),
          ),
        ),
      ],
    ),
  );
}

Widget _chartLegend(String label, Color color) {
  return Row(
    children: [
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey),
      ),
    ],
  );
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    // Background Circle
    paint.color = Colors.blueGrey.withOpacity(0.1);
    canvas.drawCircle(center, radius, paint);

    // Data segments
    double startAngle = -math.pi / 2;

    // Tuition (70%)
    paint.color = Colors.deepPurpleAccent;
    double sweepAngle = 2 * math.pi * 0.7;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
    startAngle += sweepAngle;

    // Misc (20%)
    paint.color = Colors.blueAccent;
    sweepAngle = 2 * math.pi * 0.2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
    startAngle += sweepAngle;

    // Other (10%)
    paint.color = Colors.orangeAccent;
    sweepAngle = 2 * math.pi * 0.1;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  @override
  bool hitTest(Offset position) => false;
  
  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}

class _HistogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Mock data: frequency of payments in ranges [0-1k, 1k-5k, 5k-10k, 10k-20k, >20k]
    final frequencies = [0.3, 0.8, 0.5, 0.2, 0.1];
    final barWidth = size.width / frequencies.length;

    for (int i = 0; i < frequencies.length; i++) {
      final barHeight = size.height * frequencies[i];
      final left = i * barWidth + (barWidth * 0.1); // 10% gap
      final width = barWidth * 0.8;
      final top = size.height - barHeight;

      final rect = Rect.fromLTWH(left, top, width, barHeight);

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.tealAccent, Colors.teal.withOpacity(0.3)],
      ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  @override
  bool hitTest(Offset position) => false;
  
  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}

class _BarGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barData = [0.8, 0.6, 0.9, 0.5, 0.7]; // Mock data for 5 bars
    final barWidth = size.width / (barData.length * 2);

    for (int i = 0; i < barData.length; i++) {
      final barHeight = size.height * barData[i];
      final left = i * barWidth * 2 + barWidth / 2;
      final top = size.height - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      // Create a gradient for each bar
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B5CF6),
          const Color(0xFF8B5CF6).withOpacity(0.3),
        ],
      ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  @override
  bool hitTest(Offset position) => false;
  
  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}
