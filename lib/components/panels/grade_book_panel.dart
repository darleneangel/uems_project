import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GradeBookPanel extends StatelessWidget {
  final bool isDarkMode;
  const GradeBookPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);

    return Column(
      children: [
        _buildExportBar(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableHeader(textColor),
              const Divider(color: Colors.white10, height: 32),
              _gradeRow(
                'CS 101 - Data Structures',
                '90',
                '94',
                '92%',
                textColor,
              ),
              _gradeRow('CS 102 - Web Dev', '85', '91', '88%', textColor),
              _gradeRow('CS 103 - Database', '82', '88', '85%', textColor),
              _gradeRow('CS 104 - SoftEng', '88', '92', '90%', textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _iconButton(LucideIcons.fileText, "Export PDF"),
        const SizedBox(width: 12),
        _iconButton(LucideIcons.fileSpreadsheet, "Excel"),
      ],
    );
  }

  Widget _iconButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
        foregroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTableHeader(Color textColor) {
    return Row(
      children: [
        Expanded(flex: 4, child: Text("SUBJECT", style: _headStyle())),
        Expanded(
          child: Text("MID", textAlign: TextAlign.center, style: _headStyle()),
        ),
        Expanded(
          child: Text("FIN", textAlign: TextAlign.center, style: _headStyle()),
        ),
        Expanded(
          child: Text("TOTAL", textAlign: TextAlign.right, style: _headStyle()),
        ),
      ],
    );
  }

  TextStyle _headStyle() => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: Colors.blueGrey,
    letterSpacing: 1,
  );

  Widget _gradeRow(String sub, String m, String f, String t, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              sub,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              m,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Text(
              f,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Text(
              t,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF69F0AE),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
