import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class MessagingPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const MessagingPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<MessagingPanel> createState() => _MessagingPanelState();
}

class _MessagingPanelState extends State<MessagingPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _selectedContact;
  List<Map<String, dynamic>> _allProfiles = [];
  Map<String, Map<String, dynamic>> _lastMessagesByContact = {};
  String? _lastNotifiedMessageId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMessaging();
  }

  Future<void> _initMessaging() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('profiles')
          .select('id, fn, ln, role, user_id_number')
          .neq('id', widget.userData['id']);

      if (mounted) {
        setState(() {
          _allProfiles = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Messaging Init Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedContact == null) return;

    final newMessage = {
      'sender_id': widget.userData['id'],
      'receiver_id': _selectedContact!['id'],
      'content': text,
    };

    _messageController.clear();
    try {
      await _service.client.from('messages').insert(newMessage);
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  /// 🔍 Messenger Logic: Sort threads by the latest interaction
  List<Map<String, dynamic>> get _messengerThreads {
    final query = _searchController.text.toLowerCase();

    // 1. Filter by search (Name or ID)
    List<Map<String, dynamic>> filtered = _allProfiles.where((p) {
      final fullName = "${p['fn']} ${p['ln']}".toLowerCase();
      final id = p['user_id_number'].toString().toLowerCase();
      return fullName.contains(query) || id.contains(query);
    }).toList();

    // 2. Sort by last message interaction (Top of the list)
    filtered.sort((a, b) {
      final lastA = _lastMessagesByContact[a['id']]?['id']?.toString() ?? "";
      final lastB = _lastMessagesByContact[b['id']]?['id']?.toString() ?? "";
      return lastB
          .compareTo(lastA); // String-safe comparison for UUIDs/Serial IDs
    });

    return filtered;
  }

  /// 🔔 Notification Logic: Show snackbar for background messages
  void _checkForNewMessageNotification(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return;

    // Get the absolute latest message in the stream
    final latest = messages.last;
    final String currentUserId = widget.userData['id'];

    // If I am the receiver and it's a new ID we haven't notified for yet
    if (latest['receiver_id'] == currentUserId &&
        latest['id'] != _lastNotifiedMessageId) {
      _lastNotifiedMessageId = latest['id'];

      // Only notify if we aren't currently looking at the chat with this sender
      if (_selectedContact?['id'] != latest['sender_id']) {
        final sender = _allProfiles.firstWhere(
            (p) => p['id'] == latest['sender_id'],
            orElse: () => {});
        if (sender.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showInAppNotification(
                "${sender['fn']} ${sender['ln']}", latest['content']);
          });
        }
      }
    }
  }

  void _showInAppNotification(String name, String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Text(content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.blueGrey;
    final selectedColor = widget.isDarkMode
        ? const Color(0xFF8B5CF6).withOpacity(0.15)
        : const Color(0xFFEDE9FE);

    return Container(
      height: 750,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _buildLeftPanel(textColor, subTextColor, selectedColor),
          _buildChatView(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(
      Color textColor, Color subTextColor, Color selectedColor) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Messenger",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            fontSize: 24)),
                    const Icon(LucideIcons.edit,
                        color: Color(0xFF8B5CF6), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search name or ID...",
                      hintStyle: TextStyle(color: subTextColor),
                      border: InputBorder.none,
                      icon: Icon(LucideIcons.search,
                          size: 16, color: subTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  _service.client.from('messages').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Process incoming messages to update the "Latest Activity" map
                  for (var m in snapshot.data!) {
                    final String sId = m['sender_id'];
                    final String rId = m['receiver_id'];
                    final String myId = widget.userData['id'];

                    final String otherId = (sId == myId) ? rId : sId;

                    final currentLast = _lastMessagesByContact[otherId];
                    // FIX: Used compareTo for Strings to avoid NoSuchMethodError on '>'
                    if (currentLast == null ||
                        m['id']
                                .toString()
                                .compareTo(currentLast['id'].toString()) >
                            0) {
                      _lastMessagesByContact[otherId] = m;
                    }
                  }

                  // Trigger notification check
                  _checkForNewMessageNotification(snapshot.data!);
                }

                final threads = _messengerThreads;
                return ListView.builder(
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final contact = threads[index];
                    final isSelected = _selectedContact?['id'] == contact['id'];
                    final lastMsg = _lastMessagesByContact[contact['id']]
                            ?['content'] ??
                        "No messages yet";
                    final bool isUnread = (_lastMessagesByContact[contact['id']]
                                ?['receiver_id'] ==
                            widget.userData['id']) &&
                        !isSelected;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: selectedColor,
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFF8B5CF6).withOpacity(0.1),
                            child: Text(contact['ln'][0],
                                style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: widget.isDarkMode
                                        ? const Color(0xFF1E1B4B)
                                        : Colors.white,
                                    width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text("${contact['fn']} ${contact['ln']}",
                          style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.w900
                                  : (isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600),
                              color: isUnread
                                  ? const Color(0xFF8B5CF6)
                                  : textColor,
                              fontSize: 14)),
                      subtitle: Text(lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isUnread ? textColor : subTextColor,
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      onTap: () => setState(() => _selectedContact = contact),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(Color cardColor, Color textColor, Color subTextColor) {
    if (_selectedContact == null) {
      return Expanded(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(LucideIcons.messageSquare,
                size: 48, color: textColor.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text("Select a chat to start",
                style: TextStyle(color: subTextColor))
          ])));
    }

    final inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.white10
                            : Colors.black12))),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF8B5CF6),
                    child: Text(_selectedContact!['ln'][0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "${_selectedContact!['fn']} ${_selectedContact!['ln']}",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: textColor)),
                    const Text("Active Now",
                        style: TextStyle(
                            color: Color(0xFF69F0AE),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                Icon(LucideIcons.phone, color: subTextColor, size: 20),
                const SizedBox(width: 20),
                Icon(LucideIcons.video, color: subTextColor, size: 20),
                const SizedBox(width: 20),
                Icon(LucideIcons.info, color: subTextColor, size: 20),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  _service.client.from('messages').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.where((m) {
                  final String sId = m['sender_id'];
                  final String rId = m['receiver_id'];
                  final String me = widget.userData['id'];
                  final String them = _selectedContact!['id'];
                  return (sId == me && rId == them) ||
                      (sId == them && rId == me);
                }).toList();

                messages.sort(
                    (a, b) => b['id'].toString().compareTo(a['id'].toString()));

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == widget.userData['id'];
                    return _buildMessageBubble(msg['content'], isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.black.withOpacity(0.1)
                    : cardColor,
                border: Border(
                    top: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.white10
                            : Colors.black12))),
            child: Row(
              children: [
                const Icon(LucideIcons.plusCircle, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.camera, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.image, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const Icon(LucideIcons.send,
                      color: Color(0xFF8B5CF6), size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF8B5CF6)
              : (widget.isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Text(text,
            style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                fontSize: 14)),
      ),
    );
  }
}
