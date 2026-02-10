import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessagingPanel extends StatefulWidget {
  const MessagingPanel({super.key});

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
        {'from': 'admissions', 'text': 'Please confirm applicant A12345 status.', 'time': '10:12'},
        {'from': 'registrar', 'text': 'Confirmed: hold for missing transcript.', 'time': '10:18'},
      ],
    },
    {
      'id': 2,
      'title': 'Accounting ↔ Admissions',
      'participants': ['accounting', 'admissions'],
      'messages': [
        {'from': 'accounting', 'text': 'Refund INV-789 processed.', 'time': '09:03'},
        {'from': 'admissions', 'text': 'Acknowledged, thanks.', 'time': '09:10'},
      ],
    },
  ];

  int _selectedConv = 0;

  @override
  Widget build(BuildContext context) {
    final conv = _conversations[_selectedConv];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1033),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
                  Text('Conversations', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final c = _conversations[idx];
                        return ListTile(
                          onTap: () => setState(() => _selectedConv = idx),
                          tileColor: idx == _selectedConv ? Colors.white12 : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          title: Text(c['title'], style: GoogleFonts.inter(color: Colors.white)),
                          subtitle: Text(
                            c['messages'].last['text'],
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(LucideIcons.messageSquare, color: Colors.white54),
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
                      Text(conv['title'], style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          IconButton(onPressed: () {}, icon: Icon(LucideIcons.refreshCw, color: Colors.white54)),
                          IconButton(onPressed: () {}, icon: Icon(LucideIcons.archive, color: Colors.white54)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                      child: ListView.builder(
                        itemCount: conv['messages'].length,
                        itemBuilder: (context, i) {
                          final m = conv['messages'][i];
                          final isOwn = m['from'] == 'registrar' ? true : false; // highlight registrar messages as example
                          return Align(
                            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 480),
                              decoration: BoxDecoration(
                                color: isOwn ? Colors.white12 : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['from'].toString().toUpperCase(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Text(m['text'], style: GoogleFonts.inter(color: Colors.white)),
                                  const SizedBox(height: 6),
                                  Text(m['time'], style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
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
                            hintStyle: GoogleFonts.inter(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), child: Text('Post', style: GoogleFonts.inter(color: Colors.white)))
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
