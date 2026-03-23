import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final Map<String, Map<String, dynamic>> _lastMessagesByContact = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Visual Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _initMessaging();
    _updateMyPresence();
    // Refresh the "Active X mins ago" labels every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🛰️ PRESENCE: Update current user's last seen timestamp
  Future<void> _updateMyPresence() async {
    try {
      await _service.client
          .from('profiles')
          .update({'last_active_at': DateTime.now().toIso8601String()}).eq(
              'id', widget.userData['id']);
    } catch (e) {
      // Column might not exist yet; fails silently to prevent crash
      debugPrint("Presence update skipped: $e");
    }
  }

  /// 🛰️ DATABASE: Load all profiles except current user
  Future<void> _initMessaging() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('profiles')
          .select('id, fn, ln, role, user_id_number, last_active_at')
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

  /// 🛰️ DATABASE: Send message
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
      _updateMyPresence(); // Keep presence fresh
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  /// 📐 LOGIC: Helper to format user roles for the UI
  String _formatRole(dynamic role) {
    if (role == null) return "User";
    String r = role.toString().toLowerCase();
    switch (r) {
      case 'student':
        return "Student";
      case 'teacher':
      case 'faculty':
        return "Professor";
      case 'program_chair':
        return "Pchair";
      case 'registrar':
        return "Registrar";
      case 'accounting':
        return "Accounting";
      case 'admission':
        return "Admission";
      default:
        return r[0].toUpperCase() + r.substring(1).replaceAll('_', ' ');
    }
  }

  /// 📐 LOGIC: Format "Active X ago"
  String _formatActiveStatus(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      final lastActive = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(lastActive);

      if (diff.inMinutes < 2) return "Active now";
      if (diff.inMinutes < 60) return "Active ${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "Active ${diff.inHours}h ago";
      return "Active ${diff.inDays}d ago";
    } catch (e) {
      return "";
    }
  }

  /// 🔍 Messenger Logic: Filter threads and sort by latest private interaction
  List<Map<String, dynamic>> get _messengerThreads {
    final query = _searchController.text.toLowerCase();

    List<Map<String, dynamic>> filtered = _allProfiles.where((p) {
      final fullName = "${p['fn']} ${p['ln']}".toLowerCase();
      final id = p['user_id_number'].toString().toLowerCase();
      return fullName.contains(query) || id.contains(query);
    }).toList();

    // Sort: Threads with newer private messages appear at the top of the sidebar
    filtered.sort((a, b) {
      final msgA = _lastMessagesByContact[a['id']];
      final msgB = _lastMessagesByContact[b['id']];

      if (msgA == null && msgB == null) return 0;
      if (msgA == null) return 1;
      if (msgB == null) return -1;

      final timeA = DateTime.tryParse(msgA['created_at']?.toString() ?? "") ??
          DateTime(0);
      final timeB = DateTime.tryParse(msgB['created_at']?.toString() ?? "") ??
          DateTime(0);

      return timeB.compareTo(timeA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

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
          // LEFT: THREAD LIST
          _buildLeftPanel(textColor, subTextColor),

          // RIGHT: ACTIVE CHAT
          _buildChatView(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(Color textColor, Color subTextColor) {
    final selectedColor =
        widget.isDarkMode ? aViolet.withOpacity(0.1) : const Color(0xFFF3E8FF);
    final myId = widget.userData['id'];

    return Container(
      width: 320,
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                            fontSize: 26,
                            letterSpacing: -0.5)),
                    Icon(LucideIcons.edit, size: 18, color: textColor),
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
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Search conversations...",
                      hintStyle: TextStyle(color: subTextColor, fontSize: 13),
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
              // PRIVACY LOCK: Listens for messages involving ONLY the logged-in user
              stream:
                  _service.client.from('messages').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  for (var m in snapshot.data!) {
                    final String sId = m['sender_id'];
                    final String rId = m['receiver_id'];

                    // SECURITY: Filter data strictly for current user participation
                    if (sId != myId && rId != myId) continue;

                    final String otherId = (sId == myId) ? rId : sId;
                    final currentLast = _lastMessagesByContact[otherId];

                    final timeNew =
                        DateTime.tryParse(m['created_at']?.toString() ?? "") ??
                            DateTime(0);
                    final timeOld = DateTime.tryParse(
                            currentLast?['created_at']?.toString() ?? "") ??
                        DateTime(0);

                    if (currentLast == null || timeNew.isAfter(timeOld)) {
                      _lastMessagesByContact[otherId] = m;
                    }
                  }
                }

                final threads = _messengerThreads;
                return ListView.builder(
                  itemCount: threads.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final contact = threads[index];
                    final isSelected = _selectedContact?['id'] == contact['id'];
                    final lastMsg = _lastMessagesByContact[contact['id']]
                            ?['content'] ??
                        "Start a conversation";
                    final bool isMeLast = _lastMessagesByContact[contact['id']]
                            ?['sender_id'] ==
                        myId;

                    return ListTile(
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      selectedTileColor: selectedColor,
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: aViolet.withOpacity(0.1),
                            child: Text(contact['ln'][0],
                                style: const TextStyle(
                                    color: aViolet,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (_formatActiveStatus(contact['last_active_at']) ==
                              "Active now")
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF69F0AE),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: widget.isDarkMode
                                          ? surfaceDark
                                          : Colors.white,
                                      width: 2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text("${contact['fn']} ${contact['ln']}",
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: textColor,
                              fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatRole(contact['role']),
                              style: const TextStyle(
                                  color: aViolet,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                          Text(isMeLast ? "You: $lastMsg" : lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: subTextColor, fontSize: 12)),
                        ],
                      ),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: aViolet.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(LucideIcons.messageCircle,
                    size: 48, color: aViolet.withOpacity(0.2)),
              ),
              const SizedBox(height: 16),
              Text("Select a contact to start messaging",
                  style: TextStyle(
                      color: subTextColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    final myId = widget.userData['id'];

    return Expanded(
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                  bottom: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white10 : Colors.black12)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 20,
                    backgroundColor: aViolet,
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
                            fontWeight: FontWeight.w800, color: textColor)),
                    Row(
                      children: [
                        Text(_formatRole(_selectedContact!['role']),
                            style: const TextStyle(
                                color: aViolet,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                            _formatActiveStatus(
                                _selectedContact!['last_active_at']),
                            style:
                                TextStyle(color: subTextColor, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.info, color: aViolet, size: 22),
              ],
            ),
          ),

          // Message Feed
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  _service.client.from('messages').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }

                // PRIVACY FILTER: Strictly show conversation between current user and target only
                final messages = snapshot.data!.where((m) {
                  final String sId = m['sender_id'];
                  final String rId = m['receiver_id'];
                  final String them = _selectedContact!['id'];
                  return (sId == myId && rId == them) ||
                      (sId == them && rId == myId);
                }).toList();

                // SORTING: Chronological Descending (Newest at Index 0)
                // When combined with reverse: true, this puts index 0 at the bottom.
                messages.sort((a, b) {
                  final timeA =
                      DateTime.tryParse(a['created_at']?.toString() ?? "") ??
                          DateTime(0);
                  final timeB =
                      DateTime.tryParse(b['created_at']?.toString() ?? "") ??
                          DateTime(0);
                  int timeCompare = timeB.compareTo(timeA);
                  if (timeCompare != 0) return timeCompare;

                  // Fallback to ID comparison if timestamps are identical
                  final idA = int.tryParse(a['id'].toString()) ?? 0;
                  final idB = int.tryParse(b['id'].toString()) ?? 0;
                  return idB.compareTo(idA);
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // MESSENGER STYLE: Anchored to the bottom
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == myId;
                    return _buildMessageBubble(msg['content'], isMe);
                  },
                );
              },
            ),
          ),

          // Input Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                  top: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Aa",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const Icon(LucideIcons.send, color: aViolet, size: 24),
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
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? aViolet
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
                        : (widget.isDarkMode ? Colors.white : Colors.black87),
                    fontSize: 14,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}
