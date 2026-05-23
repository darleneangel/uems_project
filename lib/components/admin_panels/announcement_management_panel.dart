import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class AnnouncementManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AnnouncementManagementPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<AnnouncementManagementPanel> createState() =>
      _AnnouncementManagementPanelState();
}

class _AnnouncementManagementPanelState
    extends State<AnnouncementManagementPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _contentCtl = TextEditingController();

  bool _isPublishing = false;
  String _targetAudience = 'All';

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 🛰️ DATABASE: Inserts a new notice into the institutional broadcast table
  Future<void> _publishNotice() async {
    final title = _titleCtl.text.trim();
    final content = _contentCtl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showToast("Incomplete Notice: Title and Content are required.",
          Colors.orangeAccent);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await _service.client.from('announcements').insert({
        'title': title,
        'content': content,
        'target_audience':
            _targetAudience, // Correctly routes to Student/Professor portal
        'office': 'Institutional Administration',
        'priority': 'High',
        'created_by': widget.userData['id'], // Linked to performing Admin
      });

      _titleCtl.clear();
      _contentCtl.clear();
      _showToast("Institutional Broadcast Released Successfully.", success);
    } catch (e) {
      debugPrint("Broadcast Error: $e");
      _showToast(
          "Network Error: Verification with ledger failed.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  /// 🛰️ DATABASE: Retracts a broadcast notice
  Future<void> _deleteAnnouncement(String id) async {
    try {
      await _service.client.from('announcements').delete().eq('id', id);
      _showToast(
          "Notice successfully retracted from all portals.", Colors.blueGrey);
    } catch (e) {
      _showToast("Retraction Error.", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildComposer(cardColor, textColor),
          const SizedBox(height: 32),
          _buildLiveFeed(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Broadcast Intelligence",
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900, color: t)),
          const Text(
              "Dispatch high-priority notices to student and faculty terminals in real-time.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ],
      );

  Widget _buildComposer(Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SYSTEM BROADCAST COMPOSER",
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleCtl,
            style: TextStyle(color: text, fontWeight: FontWeight.bold),
            decoration:
                _inputStyle("Notice Title (e.g., Campus Holiday Announcement)"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtl,
            maxLines: 4,
            style: TextStyle(color: text),
            decoration: _inputStyle(
                "Announcement Details and Institutional Instructions..."),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text("TARGET AUDIENCE: ",
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey)),
              const SizedBox(width: 12),
              _audienceChip("All"),
              _audienceChip("Students"),
              _audienceChip("Faculty"),
              const Spacer(),
              if (_isPublishing)
                const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                        color: success, strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _publishNotice,
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text("PUBLISH BROADCAST"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: success,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeed(Color bg, Color text) {
    final double feedHeight =
        (MediaQuery.of(context).size.height * 0.34).clamp(220.0, 420.0);

    return Container(
      height: feedHeight,
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text("ACTIVE INSTITUTIONAL NOTICES",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                    letterSpacing: 1.5)),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.client.from('announcements').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }
                final list = snapshot.data!;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.megaphone,
                            color: Colors.blueGrey.withOpacity(0.2), size: 48),
                        const SizedBox(height: 16),
                        const Text("No active institutional notices.",
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, i) {
                    final notice = list[i];
                    final date = DateFormat('MMM dd, hh:mm a')
                        .format(DateTime.parse(notice['created_at']).toLocal());

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Text(notice['title'],
                              style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(width: 12),
                          _statusChip(
                              notice['target_audience'] ?? 'All', aViolet),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notice['content'],
                              style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 12,
                                  height: 1.4)),
                          const SizedBox(height: 8),
                          Text(date,
                              style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              size: 18, color: Colors.redAccent),
                          onPressed: () => _confirmRetraction(
                              notice['id'], notice['title'])),
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

  Widget _audienceChip(String label) {
    bool isSelected = _targetAudience == label;
    return GestureDetector(
      onTap: () => setState(() => _targetAudience = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected
                ? aViolet
                : widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200, // Ensure visibility in light mode
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white10)),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statusChip(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w900)));

  void _confirmRetraction(String id, String title) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: surfaceDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Text("Retract Broadcast",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(
                  "Are you sure you want to remove '$title' from the system? This will disappear from all student and faculty dashboards.",
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCEL")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteAnnouncement(id);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text("RETRACT NOTICE"))
              ],
            ));
  }

  InputDecoration _inputStyle(String h) => InputDecoration(
      hintText: h,
      hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: aViolet)));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
