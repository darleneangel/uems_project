import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EnrollmentRegistrationPanel extends StatefulWidget {
  final bool isDarkMode;
  const EnrollmentRegistrationPanel({super.key, required this.isDarkMode});

  @override
  State<EnrollmentRegistrationPanel> createState() =>
      _EnrollmentRegistrationPanelState();
}

class _EnrollmentRegistrationPanelState
    extends State<EnrollmentRegistrationPanel> {
  // Mock Data for Enrollment Approvals
  final List<Map<String, dynamic>> _enrollmentQueue = [
    {
      "name": "Alice Johnson",
      "id": "2024-00102",
      "type": "Regular",
      "status": "Pending Approval",
      "section": "BSCS-1A",
    },
    {
      "name": "Mark Vian",
      "id": "2024-00105",
      "type": "Irregular",
      "status": "Under Review",
      "section": "BSIT-2B",
    },
    {
      "name": "Chloe Smith",
      "id": "2024-00110",
      "type": "Regular",
      "status": "Pending Approval",
      "section": "BSBA-1C",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(textColor, subTextColor),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Approval Queue
              Expanded(
                flex: 6,
                child: _buildQueueList(cardColor, textColor, subTextColor),
              ),
              const SizedBox(width: 20),
              // Right Side: Quick Actions & Stats
              Expanded(
                flex: 4,
                child: _buildEnrollmentStats(
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enrollment & Registration Hub",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        Text(
          "Manage course registrations, block assignments, and add/drop requests.",
          style: TextStyle(color: subTextColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildQueueList(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registration Approval Queue",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _enrollmentQueue.length,
              itemBuilder: (context, index) {
                final item = _enrollmentQueue[index];
                return _queueTile(item, textColor, subTextColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueTile(
    Map<String, dynamic> item,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            child: const Icon(
              LucideIcons.user,
              size: 16,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${item['id']} • ${item['section']}",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF69F0AE).withOpacity(0.1),
              foregroundColor: const Color(0xFF69F0AE),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "APPROVE",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentStats(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      children: [
        _actionCard(
          "GENERATE CLASS ROSTER",
          LucideIcons.users,
          const Color(0xFF8B5CF6),
          cardColor,
          textColor,
        ),
        const SizedBox(height: 16),
        _actionCard(
          "ADD/DROP WORKFLOW",
          LucideIcons.gitPullRequest,
          Colors.orangeAccent,
          cardColor,
          textColor,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Statistics",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _statRow("Total Registered", "1,402", textColor),
              _statRow("Pending Clearances", "85", textColor),
              _statRow(
                "Verified for Accounting",
                "1,317",
                const Color(0xFF69F0AE),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    String label,
    IconData icon,
    Color color,
    Color cardBg,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
