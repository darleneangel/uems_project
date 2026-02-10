import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessagingPanel extends StatefulWidget {
  final bool isDarkMode;
  const MessagingPanel({super.key, required this.isDarkMode});

  @override
  State<MessagingPanel> createState() => _MessagingPanelState();
}

class _MessagingPanelState extends State<MessagingPanel> {
  // Mock data for conversations
  final List<Map<String, dynamic>> _conversations = [
    {
      "id": "REQ-2026-9005",
      "title": "Darlene Angel",
      "subtitle": "Promissory Note",
      "time": "10:30 AM",
      "unread": 1,
      "messages": [
        {
          "sender": "Darlene Angel",
          "text":
              "Hello, I submitted my promissory note. Is there anything else needed?",
          "time": "Mar 25, 01:16 PM",
        },
        {
          "sender": "You",
          "text": "We are currently reviewing it. We will let you know.",
          "time": "Mar 26, 08:46 AM",
        },
        {
          "sender": "Darlene Angel",
          "text": "Okay, thank you for the update!",
          "time": "Mar 26, 10:30 AM",
        },
      ],
    },
    {
      "id": "REQ-2026-8821",
      "title": "Darlene Angel",
      "subtitle": "Transcript of Records",
      "time": "Yesterday",
      "unread": 0,
      "messages": [
        {
          "sender": "You",
          "text": "Your document is ready for pickup.",
          "time": "Feb 14, 08:01 AM",
        },
        {
          "sender": "Darlene Angel",
          "text": "Thank you! I will get it tomorrow.",
          "time": "Feb 14, 09:15 AM",
        },
      ],
    },
    {
      "id": "ADMIN-COMMS-01",
      "title": "System Admin",
      "subtitle": "System Maintenance Notice",
      "time": "Mar 20",
      "unread": 0,
      "messages": [
        {
          "sender": "System Admin",
          "text":
              "Please be advised of the scheduled system maintenance this weekend.",
          "time": "Mar 20, 03:00 PM",
        },
      ],
    },
  ];

  int _selectedConversationIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.blueGrey;
    final selectedColor = widget.isDarkMode
        ? const Color(0xFF8B5CF6).withOpacity(0.15)
        : const Color(0xFFEDE9FE);

    return Container(
      height: 700, // Fixed height for the messaging panel
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left: Conversation List
          _buildConversationList(
            cardColor,
            textColor,
            subTextColor,
            selectedColor,
          ),

          // Right: Chat View
          _buildChatView(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color selectedColor,
  ) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          final isSelected = _selectedConversationIndex == index;
          return ListTile(
            tileColor: isSelected ? selectedColor : null,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
              child: Icon(
                convo['title'] == 'System Admin'
                    ? LucideIcons.shield
                    : LucideIcons.user,
                size: 18,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            title: Text(
              convo['title'],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Text(
              convo['subtitle'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
            trailing: convo['unread'] > 0
                ? CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF8B5CF6),
                    child: Text(
                      convo['unread'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                : null,
            onTap: () => setState(() => _selectedConversationIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildChatView(Color cardColor, Color textColor, Color subTextColor) {
    final selectedConvo = _conversations[_selectedConversationIndex];
    final inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return Expanded(
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  selectedConvo['title'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${selectedConvo['subtitle']})",
                  style: TextStyle(color: subTextColor),
                ),
              ],
            ),
          ),
          // Message List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children:
                  (selectedConvo['messages'] as List<Map<String, dynamic>>)
                      .map(
                        (msg) => _buildMessageBubble(
                          msg['sender'],
                          msg['text'],
                          msg['sender'] == 'You',
                        ),
                      )
                      .toList(),
            ),
          ),
          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : cardColor,
              border: Border(
                top: BorderSide(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.send, color: Color(0xFF8B5CF6)),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String sender, String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF8B5CF6)
              : (widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (widget.isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
