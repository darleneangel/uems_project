import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfficesPanel extends StatelessWidget {
  final bool isDarkMode;
  const OfficesPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 2.2,
      children: [
        _clearanceCard("Library", true, LucideIcons.book, cardColor, textColor),
        _clearanceCard(
          "Accounting",
          true,
          LucideIcons.wallet,
          cardColor,
          textColor,
        ),
        _clearanceCard(
          "Registrar",
          false,
          LucideIcons.fileSignature,
          cardColor,
          textColor,
        ),
        _clearanceCard(
          "Dean's Office",
          true,
          LucideIcons.userCheck,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _clearanceCard(
    String title,
    bool isDone,
    IconData icon,
    Color cardColor,
    Color textColor,
  ) {
    final statusColor = isDone
        ? const Color(0xFF69F0AE)
        : const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? statusColor.withOpacity(0.2) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDone ? "Cleared" : "Pending",
                  style: TextStyle(
                    color: isDone ? statusColor : textColor.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isDone ? LucideIcons.checkCircle : LucideIcons.clock,
            color: statusColor.withOpacity(0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
}
