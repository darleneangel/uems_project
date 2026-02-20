import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentMessagingPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentMessagingPanel({super.key, required this.isDarkMode});

  @override
  State<StudentMessagingPanel> createState() => _StudentMessagingPanelState();
}

class _StudentMessagingPanelState extends State<StudentMessagingPanel> {
  int _selectedThreadIndex = 0;
  final TextEditingController _msgController = TextEditingController();

  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // --- MOCK DATA: THREADS (OFFICES) & MESSAGES ---
  final List<Map<String, dynamic>> _threads = [
    {
      "name": "Admissions Office",
      "department": "Undergraduate Admissions",
      "status": "Online",
      "lastMsg": "Your document review is complete.",
      "time": "5m ago",
      "unread": true,
      "messages": [
        {
          "sender": "Student",
          "text": "Hello, I would like to follow up on my application status.",
          "time": "Yesterday",
        },
        {
          "sender": "Office",
          "text":
              "Good day! Your document review is complete. Please check your portal.",
          "time": "10:30 AM",
        },
      ],
    },
    {
      "name": "Registrar's Office",
      "department": "Records & Registration",
      "status": "Away",
      "lastMsg": "Transcript request processed.",
      "time": "2h ago",
      "unread": false,
      "messages": [
        {
          "sender": "Student",
          "text": "Can I request a copy of my grades?",
          "time": "09:00 AM",
        },
        {
          "sender": "Office",
          "text":
              "Transcript request processed. You may pick it up at Window 2.",
          "time": "11:15 AM",
        },
      ],
    },
    {
      "name": "Accounting Office",
      "department": "Student Accounts",
      "status": "Online",
      "lastMsg": "Payment confirmed.",
      "time": "1d ago",
      "unread": false,
      "messages": [
        {
          "sender": "Student",
          "text": "I've sent the proof of payment for my tuition.",
          "time": "Monday",
        },
        {
          "sender": "Office",
          "text": "Payment confirmed. Your balance is now updated.",
          "time": "Tuesday",
        },
      ],
    },
  ];

  void _sendMessage() {
    final text = _msgController.text;
    if (text.isEmpty) return;

    setState(() {
      _threads[_selectedThreadIndex]['messages'].add({
        "sender": "Student",
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. THREAD LIST SIDEBAR
        _buildThreadSidebar(cardColor, textColor, subTextColor),
        const SizedBox(width: 24),
        // 2. CHAT CONSOLE
        Expanded(child: _buildChatConsole(cardColor, textColor, subTextColor)),
      ],
    );
  }

  Widget _buildThreadSidebar(Color cardBg, Color text, Color subText) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
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
                      "Messages",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    _badge("NEW", aViolet),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search offices...",
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
                          child: Icon(
                            LucideIcons.building,
                            size: 18,
                            color: isSelected ? Colors.white : text,
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
                            color: Colors.blueGrey,
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
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
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
              itemBuilder: (context, index) =>
                  _buildMessageBubble(activeThread['messages'][index], text),
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
                t['department'],
                style: TextStyle(
                  color: subText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          _badge(
            t['status'],
            t['status'] == "Online" ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, Color text) {
    bool isStudent = m['sender'] == 'Student';
    return Align(
      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isStudent
              ? aViolet
              : (widget.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isStudent
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              m['text'],
              style: TextStyle(
                color: isStudent ? Colors.white : text,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              m['time'],
              style: TextStyle(
                color: isStudent ? Colors.white70 : Colors.blueGrey,
                fontSize: 9,
              ),
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
                border: widget.isDarkMode
                    ? null
                    : Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type your message here...",
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
