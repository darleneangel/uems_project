import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentRequestsPanel extends StatefulWidget {
  final bool isDarkMode;
  const StudentRequestsPanel({super.key, required this.isDarkMode});

  @override
  State<StudentRequestsPanel> createState() => _StudentRequestsPanelState();
}

class _StudentRequestsPanelState extends State<StudentRequestsPanel> {
  String? _selectedRequestId;
  final TextEditingController _replyController = TextEditingController();

  // --- SHARED MOCK DATA (Connected to Student Portal Logic) ---
  final List<Map<String, dynamic>> _incomingRequests = [
    {
      "id": "REQ-2026-8821",
      "studentName": "DARLENE ANGEL",
      "studentId": "2024-00001",
      "type": "Transcript of Records",
      "status": "In Review",
      "date": "Feb 10, 09:30 AM",
      "priority": "High",
      "timeline": [
        {
          "status": "Submitted",
          "time": "Feb 10, 09:30 AM",
          "msg": "Request submitted via portal.",
        },
        {
          "status": "In Review",
          "time": "Feb 11, 10:00 AM",
          "msg": "Registrar verified clearance.",
        },
      ],
      "messages": [
        {
          "sender": "You",
          "text": "Is there any additional requirement?",
          "time": "Feb 10, 09:31 AM",
        },
      ],
    },
    {
      "id": "REQ-2026-9112",
      "studentName": "JUAN DELA CRUZ",
      "studentId": "2024-00002",
      "type": "Enrollment Verification",
      "status": "Submitted",
      "date": "Feb 11, 01:15 PM",
      "priority": "Normal",
      "timeline": [
        {
          "status": "Submitted",
          "time": "Feb 11, 01:15 PM",
          "msg": "Payment verified by Accounting.",
        },
      ],
      "messages": [],
    },
  ];

  void _updateStatus(String newStatus) {
    setState(() {
      final req = _incomingRequests.firstWhere(
        (r) => r['id'] == _selectedRequestId,
      );
      req['status'] = newStatus;
      req['timeline'].add({
        "status": newStatus,
        "time": "Today, ${DateTime.now().hour}:${DateTime.now().minute}",
        "msg": "Status updated by Registrar Office.",
      });
    });
  }

  void _sendReply() {
    if (_replyController.text.isEmpty) return;
    setState(() {
      final req = _incomingRequests.firstWhere(
        (r) => r['id'] == _selectedRequestId,
      );
      req['messages'].add({
        "sender": "Registrar",
        "text": _replyController.text,
        "time": "Just now",
      });
      _replyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LEFT SIDE: LIST OF INCOMING REQUESTS
        Expanded(
          flex: 4,
          child: _buildRequestQueue(cardColor, textColor, subTextColor),
        ),
        const SizedBox(width: 24),
        // 2. RIGHT SIDE: DETAIL & INTERACTION PANEL
        Expanded(
          flex: 6,
          child: _selectedRequestId == null
              ? _buildEmptyDetailState(textColor, subTextColor)
              : _buildRequestDetailView(cardColor, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildRequestQueue(Color cardBg, Color text, Color subText) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Incoming Requests",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                color: text,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _incomingRequests.length,
              separatorBuilder: (context, index) => Divider(
                color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final req = _incomingRequests[index];
                bool isSelected = _selectedRequestId == req['id'];
                return InkWell(
                  onTap: () => setState(() => _selectedRequestId = req['id']),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: isSelected
                        ? const Color(0xFF8B5CF6).withOpacity(0.1)
                        : Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req['id'],
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            _statusBadge(req['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['studentName'],
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          req['type'],
                          style: TextStyle(color: subText, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              req['date'],
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

  Widget _buildRequestDetailView(Color cardBg, Color text, Color subText) {
    final req = _incomingRequests.firstWhere(
      (r) => r['id'] == _selectedRequestId,
    );

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['studentName'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: text,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "${req['studentId']} • ${req['type']}",
                      style: TextStyle(color: subText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildActionDropdown(text, cardBg),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PROCESS TIMELINE",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...req['timeline']
                          .map<Widget>(
                            (t) => _buildTimelineItem(
                              t['status'],
                              t['time'],
                              subText,
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
                const VerticalDivider(width: 40, color: Colors.white10),
                // Messages
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "COMMUNICATION",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: req['messages']
                              .map<Widget>((m) => _buildChatBubble(m, text))
                              .toList(),
                        ),
                      ),
                      _buildReplyInput(text, subText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDropdown(Color text, Color cardBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: const Text(
            "UPDATE STATUS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: const Icon(
            LucideIcons.chevronDown,
            color: Colors.white,
            size: 14,
          ),
          dropdownColor: const Color(0xFF1E1B4B),
          items: ["Processing", "Completed", "Rejected"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (val) => _updateStatus(val!),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String status, String time, Color subText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            size: 14,
            color: Color(0xFF69F0AE),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(time, style: TextStyle(color: subText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, Color text) {
    bool isRegistrar = msg['sender'] == 'Registrar';
    return Align(
      alignment: isRegistrar ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRegistrar
              ? const Color(0xFF8B5CF6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isRegistrar
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              msg['time'],
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(Color text, Color subText) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _replyController,
        style: TextStyle(color: text, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Reply to student...",
          hintStyle: TextStyle(color: subText, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(
              LucideIcons.send,
              size: 18,
              color: Color(0xFF8B5CF6),
            ),
            onPressed: _sendReply,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDetailState(Color text, Color subText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mousePointer2,
            color: text.withOpacity(0.1),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "Select a request from the queue to manage approval and messaging.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subText),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == "Completed"
        ? const Color(0xFF69F0AE)
        : (status == "In Review" ? Colors.blueAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
