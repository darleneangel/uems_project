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

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
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
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

  Widget _transactionRow(
    String title,
    String subtitle,
    String amount,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: textColor),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Color cardColor, Color textColor, Color subTextColor) {
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
        ],
      ),
    );
  }

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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
}
