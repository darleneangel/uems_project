import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InterviewManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const InterviewManagementPanel({super.key, required this.isDarkMode});

  @override
  State<InterviewManagementPanel> createState() =>
      _InterviewManagementPanelState();
}

class _InterviewManagementPanelState extends State<InterviewManagementPanel> {
  // Mock data for students currently in the interview phase
  List<Map<String, dynamic>> _interviewQueue = [
    {
      "id": "APL-2026-004",
      "name": "MICHAEL CHEN",
      "program": "BS INFORMATION TECHNOLOGY",
      "date": "Oct 24, 2025",
      "time": "10:30 AM",
      "interviewer": "Dr. Arnel Reyes",
    },
    {
      "id": "APL-2026-012",
      "name": "SOPHIA RODRIGUEZ",
      "program": "BS NURSING",
      "date": "Oct 24, 2025",
      "time": "02:00 PM",
      "interviewer": "Prof. Maria Clara",
    },
  ];

  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF69F0AE);

  void _handleDecision(int index, bool isApproved) {
    final studentName = _interviewQueue[index]['name'];
    setState(() {
      _interviewQueue.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isApproved ? successGreen : Colors.redAccent,
        content: Text(
          isApproved
              ? "$studentName Approved. Moving to Document Verification."
              : "$studentName Application Rejected.",
          style: const TextStyle(color: pViolet, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor, subTextColor),
          const SizedBox(height: 32),
          Expanded(
            child: _interviewQueue.isEmpty
                ? _buildEmptyState(subTextColor)
                : ListView.builder(
                    itemCount: _interviewQueue.length,
                    itemBuilder: (context, index) {
                      return _buildInterviewCard(
                        index,
                        _interviewQueue[index],
                        cardColor,
                        textColor,
                        subTextColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Interview Evaluation Queue",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1,
          ),
        ),
        Text(
          "Assess applicant performance and finalize admission eligibility.",
          style: TextStyle(color: subTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInterviewCard(
    int index,
    Map<String, dynamic> data,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: aViolet.withOpacity(0.1),
            child: const Icon(LucideIcons.mic, color: aViolet),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                Text(
                  "${data['program']} • ${data['id']}",
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoIcon(LucideIcons.calendar, data['date'], subTextColor),
                    const SizedBox(width: 16),
                    _infoIcon(LucideIcons.clock, data['time'], subTextColor),
                    const SizedBox(width: 16),
                    _infoIcon(
                      LucideIcons.userCheck,
                      "Interviewer: ${data['interviewer']}",
                      subTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _decisionButton(
                label: "REJECT",
                icon: LucideIcons.userX,
                color: Colors.redAccent,
                onTap: () => _handleDecision(index, false),
              ),
              const SizedBox(width: 12),
              _decisionButton(
                label: "APPROVE",
                icon: LucideIcons.checkCircle,
                color: successGreen,
                onTap: () => _handleDecision(index, true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _decisionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Text(
        "No pending interviews in the queue.",
        style: TextStyle(color: subTextColor),
      ),
    );
  }
}
