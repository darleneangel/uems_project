import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class AdmissionMessagingPanel extends StatefulWidget {
  final bool isDarkMode;
  const AdmissionMessagingPanel({super.key, required this.isDarkMode});

  @override
  State<AdmissionMessagingPanel> createState() =>
      _AdmissionMessagingPanelState();
}

class _AdmissionMessagingPanelState extends State<AdmissionMessagingPanel> {
  int _selectedThreadIndex = 0;
  final TextEditingController _msgController = TextEditingController();

  // Modern Tonal Palette
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  // --- MOCK DATA: THREADS & MESSAGES ---
  final List<Map<String, dynamic>> _threads = [
    {
      "name": "SEAN KIEFER BENITEZ",
      "id": "APL-2026-004",
      "status": "For Interview",
      "lastMsg": "maam ipasa niyo kami pls.",
      "time": "2m ago",
      "unread": true,
      "messages": [
        {
          "sender": "Kiefer",
          "text": "oo naman",
          "time": "10:30 AM",
          "isNotice": false,
        },
        {
          "sender": "Officer",
          "text": "Received. We are reviewing your documents now.",
          "time": "10:35 AM",
          "isNotice": false,
        },
      ],
    },
    {
      "name": "DARLENE ANGEL L. CUSTODIO",
      "id": "APL-2026-001",
      "status": "Verified",
      "lastMsg": "Official Notice of Admission sent.",
      "time": "1h ago",
      "unread": false,
      "messages": [
        {
          "sender": "Darlene",
          "text": "When will I receive my admission slip?",
          "time": "09:00 AM",
          "isNotice": false,
        },
        {
          "sender": "Officer",
          "text": "OFFICIAL NOTICE: Your admission to BSCS has been approved.",
          "time": "09:15 AM",
          "isNotice": true,
        },
      ],
    },
  ];

  void _sendMessage({bool isNotice = false, String? customText}) {
    final text = customText ?? _msgController.text;
    if (text.isEmpty) return;

    setState(() {
      _threads[_selectedThreadIndex]['messages'].add({
        "sender": "Officer",
        "text": text,
        "time": "Just now",
        "isNotice": isNotice,
      });
      _threads[_selectedThreadIndex]['lastMsg'] = text;
      _msgController.clear();
    });
  }

  // --- OFFICIAL LETTER GENERATION ---
  Future<void> _generateAdmissionLetter(String type) async {
    final applicant = _threads[_selectedThreadIndex];
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "OFFICE OF ADMISSIONS",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
              pw.SizedBox(height: 20),
              pw.Text("Dear ${applicant['name']},"),
              pw.SizedBox(height: 20),
              pw.Text("Subject: $type"),
              pw.SizedBox(height: 20),
              pw.Text(
                "We are pleased to inform you that your application for admission to the program ${applicant['status']} has been processed.",
              ),
              pw.SizedBox(height: 40),
              pw.Text("Respectfully,"),
              pw.SizedBox(height: 10),
              pw.Text(
                "ADMISSIONS_OFFICER_HUB",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Admission_Letter_${applicant['id']}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      _sendMessage(
        isNotice: true,
        customText: "OFFICIAL DOCUMENT: $type has been generated and sent.",
      );
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Row(
      children: [
        // 1. MODERN THREAD LIST SIDEBAR
        _buildThreadSidebar(cardColor, textColor, subTextColor),
        const SizedBox(width: 24),
        // 2. INTERACTIVE CHAT & NOTICE CONSOLE
        Expanded(
          child: _buildChatConsole(cardColor, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildThreadSidebar(Color cardBg, Color text, Color subText) {
    return Container(
      width: 380,
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
                      "Inbox",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    _badge("4 UNREAD", aViolet),
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
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildChatHeader(activeThread, text, subText),
          const Divider(height: 1, color: Colors.white10),
          // Messages
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
          // Input & Templates
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
          _actionIconButton(
            LucideIcons.fileSignature,
            "OFFICIAL NOTICE",
            () => _showTemplateMenu(),
            aViolet,
          ),
          const SizedBox(width: 12),
          _actionIconButton(
            LucideIcons.archive,
            "ARCHIVE",
            () {},
            Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, Color text) {
    bool isOfficer = m['sender'] == 'Officer';
    bool isNotice = m['isNotice'] ?? false;

    return Align(
      alignment: isOfficer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isNotice
              ? aViolet.withOpacity(0.1)
              : (isOfficer ? aViolet : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: isNotice ? Border.all(color: aViolet.withOpacity(0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment:
              isOfficer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isNotice)
              const Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: aViolet, size: 14),
                  SizedBox(width: 8),
                  Text(
                    "OFFICIAL ADMISSION NOTICE",
                    style: TextStyle(
                      color: aViolet,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            if (isNotice) const SizedBox(height: 8),
            Text(
              m['text'],
              style: TextStyle(
                color: isOfficer && !isNotice ? Colors.white : text,
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
        color:
            widget.isDarkMode ? Colors.black.withOpacity(0.1) : Colors.grey[50],
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
                  hintText: "Compose a message to applicant...",
                  hintStyle: TextStyle(color: subText),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => _sendMessage(),
            backgroundColor: aViolet,
            elevation: 0,
            child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // --- TEMPLATE MENU ---
  void _showTemplateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Official Document Templates",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            _templateTile(
              "Notice of Admission (Approved)",
              LucideIcons.checkCircle,
              success,
            ),
            _templateTile(
              "Notice of Conditional Acceptance",
              LucideIcons.alertCircle,
              Colors.amber,
            ),
            _templateTile(
              "Notice of Deficiency (Missing Docs)",
              LucideIcons.fileX,
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateTile(String title, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: Colors.white24,
      ),
      onTap: () {
        Navigator.pop(context);
        _generateAdmissionLetter(title);
      },
    );
  }

  // --- UI HELPERS ---
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

  Widget _actionIconButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
