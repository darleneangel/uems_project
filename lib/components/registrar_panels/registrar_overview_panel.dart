import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RegistrarOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  const RegistrarOverviewPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registrar Intelligence Overview",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statCard(
                "Active Students",
                "4,291",
                LucideIcons.users,
                const Color(0xFF8B5CF6),
                cardColor,
                textColor,
              ),
              _statCard(
                "Pending Graduation",
                "856",
                LucideIcons.graduationCap,
                const Color(0xFF69F0AE),
                cardColor,
                textColor,
              ),
              _statCard(
                "Requests Pending",
                "24",
                LucideIcons.fileText,
                Colors.orangeAccent,
                cardColor,
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Additional quick actions or recent activity can go here
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color cardBg,
    Color text,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
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
}
