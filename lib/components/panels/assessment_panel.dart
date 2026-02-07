import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssessmentPanel extends StatelessWidget {
  final bool isDarkMode;
  const AssessmentPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);

    final assessments = [
      ('Data Structures', 0.92, '92%'),
      ('Web Development', 0.88, '88%'),
      ('Database Admin', 0.85, '85%'),
      ('Software Engineering', 0.90, '90%'),
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Assessments",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Real-time performance tracking per course",
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 32),
          ...assessments.map(
            (item) => _buildProgressRow(item.$1, item.$2, item.$3, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String title,
    double val,
    String percent,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                percent,
                style: const TextStyle(
                  color: Color(0xFF69F0AE),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: val,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF69F0AE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
