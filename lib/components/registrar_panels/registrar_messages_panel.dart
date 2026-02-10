import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RegistrarMessagesPanel extends StatelessWidget {
  final bool isDarkMode;
  const RegistrarMessagesPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    final messages = [
      {
        "sender": "Darlene Angel",
        "subject": "Grade Concern",
        "time": "10:30 AM",
        "unread": true,
      },
      {
        "sender": "Juan Dela Cruz",
        "subject": "TOR Pickup Request",
        "time": "Yesterday",
        "unread": false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Student Inquiry Inbox",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final m = messages[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m['unread'] == true
                        ? const Color(0xFF8B5CF6)
                        : Colors.white10,
                    child: const Icon(
                      LucideIcons.mail,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    m['sender'] as String,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: m['unread'] == true
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    m['subject'] as String,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  trailing: Text(
                    m['time'] as String,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
