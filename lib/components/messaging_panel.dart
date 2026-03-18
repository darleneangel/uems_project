import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessagingPanel extends StatefulWidget {
  const MessagingPanel({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<MessagingPanel> createState() => _MessagingPanelState();
}

class _MessagingPanelState extends State<MessagingPanel> {
  // Simple in-memory demo conversations between offices
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 1,
      'title': 'Admissions ↔ Registrar',
      'participants': ['admissions', 'registrar'],
      'messages': [
        {
          'from': 'admissions',
          'text': 'Please confirm applicant A12345 status.',
          'time': '10:12'
        },
        {
          'from': 'registrar',
          'text': 'Confirmed: hold for missing transcript.',
          'time': '10:18'
        },
      ],
    },
    {
      'id': 2,
      'title': 'Accounting ↔ Admissions',
      'participants': ['accounting', 'admissions'],
      'messages': [
        {
          'from': 'accounting',
          'text': 'Refund INV-789 processed.',
          'time': '09:03'
        },
        {
          'from': 'admissions',
          'text': 'Acknowledged, thanks.',
          'time': '09:10'
        },
      ],
    },
  ];

  int _selectedConv = 0;

  // Theme colors
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color lCard = Color(0xFFFFFFFF);

  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void didUpdateWidget(covariant MessagingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        _isDarkMode = widget.isDarkMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = _conversations[_selectedConv];

    // Theme-aware colors
    final cardColor = _isDarkMode ? surfaceDark : lCard;
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white54 : Colors.blueGrey;
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: SizedBox(
        height: 520,
        child: Row(
          children: [
            // Conversations list
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conversations',
                      style: GoogleFonts.inter(
                          color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final c = _conversations[idx];
                        return ListTile(
                          onTap: () => setState(() => _selectedConv = idx),
                          tileColor: idx == _selectedConv
                              ? (_isDarkMode
                                  ? Colors.white12
                                  : Colors.grey.shade100)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          title: Text(c['title'],
                              style: GoogleFonts.inter(color: textColor)),
                          subtitle: Text(
                            c['messages'].last['text'],
                            style: GoogleFonts.inter(
                                color: subTextColor, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(LucideIcons.messageSquare,
                              color: subTextColor),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Message view
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(conv['title'],
                          style: GoogleFonts.inter(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {},
                              icon: Icon(LucideIcons.refreshCw,
                                  color: subTextColor)),
                          IconButton(
                              onPressed: () {},
                              icon: Icon(LucideIcons.archive,
                                  color: subTextColor)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: ListView.builder(
                        itemCount: conv['messages'].length,
                        itemBuilder: (context, i) {
                          final m = conv['messages'][i];
                          final isOwn = m['from'] == 'registrar'
                              ? true
                              : false; // highlight registrar messages as example
                          return Align(
                            alignment: isOwn
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 480),
                              decoration: BoxDecoration(
                                color: isOwn
                                    ? (_isDarkMode
                                        ? Colors.white12
                                        : Colors.grey.shade100)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['from'].toString().toUpperCase(),
                                      style: GoogleFonts.inter(
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                          fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Text(m['text'],
                                      style:
                                          GoogleFonts.inter(color: textColor)),
                                  const SizedBox(height: 6),
                                  Text(m['time'],
                                      style: GoogleFonts.inter(
                                          color: subTextColor, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Monitor-only: admin can post a note
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Write a monitoring note (admin only)',
                            hintStyle: GoogleFonts.inter(
                                color: _isDarkMode
                                    ? Colors.white30
                                    : Colors.grey.shade400),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor)),
                          ),
                          style: GoogleFonts.inter(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: aViolet),
                          child: Text('Post',
                              style: GoogleFonts.inter(color: Colors.white)))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
