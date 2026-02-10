import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProgramChairMessagingPanel extends StatefulWidget {
  final bool isDarkMode;
  const ProgramChairMessagingPanel({super.key, required this.isDarkMode});

  @override
  State<ProgramChairMessagingPanel> createState() =>
      _ProgramChairMessagingPanelState();
}

class _ProgramChairMessagingPanelState
    extends State<ProgramChairMessagingPanel> {
  int _selectedThreadIndex = 0;
  final TextEditingController _msgController = TextEditingController();

  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // Mock Data
  final List<Map<String, dynamic>> _threads = [
    {
      "name": "Michael Chen",
      "id": "STU-2026-004",
      "status": "Active",
      "lastMsg": "I have a question about my load.",
      "time": "2m ago",
      "unread": true,
      "messages": [
        {
          "sender": "Student",
          "text":
              "Good day! I have a question about my study load for this semester.",
          "time": "10:30 AM",
        },
        {
          "sender": "User",
          "text": "Please proceed. What seems to be the issue?",
          "time": "10:35 AM",
        },
      ],
    },
  ];

  void _sendMessage() {
    final text = _msgController.text;
    if (text.isEmpty) return;

    setState(() {
      _threads[_selectedThreadIndex]['messages'].add({
        "sender": "User",
        "text": text,
        "time": "Just now",
      });
      _threads[_selectedThreadIndex]['lastMsg'] = text;
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        children: [
          _buildThreadSidebar(cardColor, textColor, subTextColor),
          const SizedBox(width: 24),
          Expanded(
            child: _buildChatConsole(cardColor, textColor, subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadSidebar(Color cardBg, Color text, Color subText) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Inbox",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    _badge("1 UNREAD", aViolet),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search conversations...",
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: widget.isDarkMode
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _threads.length,
              itemBuilder: (context, index) {
                final t = _threads[index];
                bool isSelected = _selectedThreadIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedThreadIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? aViolet : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      color: isSelected
                          ? aViolet.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected
                              ? aViolet
                              : Colors.blueGrey.withOpacity(0.1),
                          child: Text(
                            t['name'][0],
                            style: TextStyle(
                              color: isSelected ? Colors.white : text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name'],
                                style: TextStyle(
                                  color: text,
                                  fontWeight: t['unread']
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                              Text(
                                t['lastMsg'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          t['time'],
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      ],
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

  Widget _buildChatConsole(Color cardBg, Color text, Color subText) {
    final activeThread = _threads[_selectedThreadIndex];
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          _buildChatHeader(activeThread, text, subText),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: activeThread['messages'].length,
              itemBuilder: (context, index) {
                final m = activeThread['messages'][index];
                return _buildMessageBubble(m, text);
              },
            ),
          ),
          _buildInputArea(text, subText),
        ],
      ),
    );
  }

  Widget _buildChatHeader(Map<String, dynamic> t, Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t['name'],
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              Text(
                "${t['id']} • ${t['status']}",
                style: TextStyle(
                  color: subText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.archive, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, Color text) {
    bool isUser = m['sender'] == 'User';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isUser ? aViolet : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              m['text'],
              style: TextStyle(
                color: isUser ? Colors.white : text,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              m['time'],
              style: const TextStyle(color: Colors.white24, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.black.withOpacity(0.1)
            : Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: subText),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: aViolet,
            elevation: 0,
            child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}
