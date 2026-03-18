import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class RegistrarMessagesPanel extends StatefulWidget {
  final bool isDarkMode;
  final String? studentId; // This is the profile UUID
  const RegistrarMessagesPanel(
      {super.key, required this.isDarkMode, this.studentId});

  @override
  State<RegistrarMessagesPanel> createState() => _RegistrarMessagesPanelState();
}

class _RegistrarMessagesPanelState extends State<RegistrarMessagesPanel> {
  int _selectedThreadIndex = 0;
  final TextEditingController _msgController = TextEditingController();
  List<Map<String, dynamic>> _threads = [];
  bool _isInitializing = true;

  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _initMessagingSession();
  }

  /// 🛰️ INITIALIZATION: Ensures a thread exists with the Registrar
  Future<void> _initMessagingSession() async {
    if (widget.studentId == null) return;

    // First, identify the Registrar contact info
    final registrar = await SupabaseService().getRegistrarContact();

    if (registrar != null) {
      _setupMessageStream();
    }

    if (mounted) setState(() => _isInitializing = false);
  }

  /// 📻 LIVE STREAM: Listens for incoming and outgoing messages
  void _setupMessageStream() {
    if (widget.studentId == null) return;

    SupabaseService()
        .client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((data) {
          if (mounted) {
            // Filter only messages belonging to this student
            final myMessages = data
                .where((m) =>
                    m['sender_id'] == widget.studentId ||
                    m['receiver_id'] == widget.studentId)
                .toList();

            final grouped = _groupMessagesIntoThreads(myMessages);
            if (mounted) setState(() => _threads = grouped);
          }
        });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _threads.isEmpty) return;

    final String recipientId = _threads[_selectedThreadIndex]['id'];

    try {
      await SupabaseService().sendMessage({
        'sender_id': widget.studentId,
        'receiver_id': recipientId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _msgController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Transmission Error: $e"),
          backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

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

  List<Map<String, dynamic>> _groupMessagesIntoThreads(
      List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final myId = widget.studentId;
    Map<String, Map<String, dynamic>> threads = {};

    for (var msg in data) {
      final otherId =
          msg['sender_id'] == myId ? msg['receiver_id'] : msg['sender_id'];
      if (otherId == null) continue;

      if (!threads.containsKey(otherId)) {
        threads[otherId] = {
          'id': otherId,
          'name': 'Registrar Office',
          'department': 'Official Records',
          'status': 'Online',
          'unread': false,
          'lastMsg': '',
          'time': '',
          'messages': []
        };
      }

      threads[otherId]!['lastMsg'] = msg['content'];

      try {
        final date = DateTime.parse(msg['created_at']);
        threads[otherId]!['time'] =
            "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        threads[otherId]!['time'] = "Now";
      }

      threads[otherId]!['messages'].add({
        'sender_id': msg['sender_id'],
        'text': msg['content'],
        'time': threads[otherId]!['time'],
      });
    }
    return threads.values.toList();
  }

  Widget _buildThreadSidebar(Color cardBg, Color text, Color subText) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Messages",
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: text)),
                _badge("LIVE", success),
              ],
            ),
          ),
          Expanded(
            child: _threads.isEmpty
                ? Center(
                    child: Text("No conversations yet.",
                        style: TextStyle(color: subText, fontSize: 12)))
                : ListView.builder(
                    itemCount: _threads.length,
                    itemBuilder: (context, index) {
                      final t = _threads[index];
                      bool isSelected = _selectedThreadIndex == index;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedThreadIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: isSelected
                                        ? aViolet
                                        : Colors.transparent,
                                    width: 4)),
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
                                child: const Icon(LucideIcons.building,
                                    size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['name'],
                                        style: TextStyle(
                                            color: text,
                                            fontWeight: FontWeight.bold)),
                                    Text(t['lastMsg'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12)),
                                  ],
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
    if (_threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageSquare,
                size: 64, color: text.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text("Select an administrative contact to begin.",
                style: TextStyle(color: subText)),
          ],
        ),
      );
    }

    final activeThread = _threads[_selectedThreadIndex];
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
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
              Text(t['name'],
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: text)),
              Text(t['department'],
                  style: TextStyle(
                      color: subText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          _badge(t['status'], success),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, Color text) {
    bool isMe = m['sender_id'] == widget.studentId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isMe
              ? aViolet
              : (widget.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(m['text'],
                style:
                    TextStyle(color: isMe ? Colors.white : text, fontSize: 13)),
            const SizedBox(height: 4),
            Text(m['time'],
                style: const TextStyle(color: Colors.white24, fontSize: 9)),
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
              : Colors.grey.shade50),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: text, fontSize: 14),
                decoration: InputDecoration(
                    hintText: "Type your inquiry to the Registrar...",
                    hintStyle: TextStyle(color: subText),
                    border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: aViolet,
            elevation: 0,
            mini: true,
            child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style:
                TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900)),
      );
}
