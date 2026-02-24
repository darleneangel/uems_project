import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfficesPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const OfficesPanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<OfficesPanel> createState() => _OfficesPanelState();
}

class _OfficesPanelState extends State<OfficesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- FORM STATE ---
  String? _selectedRequestType;
  final TextEditingController _messageController = TextEditingController();
  bool _isUploading = false;
  String? _attachedFileName;

  // --- REGISTRAR SERVICES ONLY ---
  final List<String> _requestTypes = [
    "Official Transcript of Records (TOR)",
    "Form 138 (Report Card)",
    "Certificate of Enrollment",
    "Diploma Request",
    "Honorable Dismissal",
    "Form 137",
    "Registration Form (Copy)",
  ];

  // --- MOCK REQUEST HISTORY ---
  final List<Map<String, dynamic>> _requests = [
    {
      "id": "REQ-2026-8821",
      "type": "Official Transcript of Records (TOR)",
      "status": "Accepted",
      "date": "2026-02-10 09:30",
      "tat": "3-5 Days",
      "ticketCode": "UEMS-REG-8821-X",
      "timeline": [
        {
          "status": "Submitted",
          "time": "Feb 10, 09:30 AM",
          "msg": "Request submitted via portal.",
        },
        {
          "status": "Accepted",
          "time": "Feb 11, 10:00 AM",
          "msg":
              "Registrar verified clearance. Please present the QR ticket at Window 2.",
        },
      ],
    },
    {
      "id": "REQ-2026-9005",
      "type": "Registration Form (Copy)",
      "status": "Completed",
      "date": "2026-01-25 13:15",
      "tat": "Instant",
      "ticketCode": "UEMS-REG-9005-C",
      "timeline": [
        {
          "status": "Submitted",
          "time": "Jan 25, 01:15 PM",
          "msg": "Digital copy requested.",
        },
        {
          "status": "Completed",
          "time": "Jan 25, 01:20 PM",
          "msg": "Document generated successfully.",
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _submitRequest() {
    if (_selectedRequestType == null) return;

    setState(() {
      final newId = "REQ-2026-${1000 + Random().nextInt(9000)}";
      final now = DateTime.now().toString().substring(0, 16);

      _requests.insert(0, {
        "id": newId,
        "type": _selectedRequestType,
        "status": "Submitted",
        "date": now,
        "tat": "Processing",
        "ticketCode": "PENDING",
        "timeline": [
          {
            "status": "Submitted",
            "time": now,
            "msg": "Request submitted to Registrar Office.",
          },
        ],
      });

      _selectedRequestType = null;
      _messageController.clear();
      _attachedFileName = null;
      _tabController.animateTo(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registrar request submitted successfully!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardSummary(cardColor, textColor),
          const SizedBox(height: 24),
          _buildTabBar(textColor),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewRequestForm(cardColor, textColor, subTextColor),
                _buildRequestHistory(cardColor, textColor, subTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(Color cardColor, Color textColor) {
    int active = _requests
        .where((r) => r['status'] != 'Completed' && r['status'] != 'Rejected')
        .length;
    int completed = _requests.where((r) => r['status'] == 'Completed').length;

    return Row(
      children: [
        _statCard(
          "Pending Registrar",
          active.toString(),
          Colors.blueAccent,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Ready for Pickup",
          "1",
          const Color(0xFF69F0AE),
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Completed Docs",
          completed.toString(),
          const Color(0xFF8B5CF6),
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    Color cardColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textColor.withOpacity(0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF8B5CF6),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: "REQUEST DOCUMENT"),
          Tab(text: "TRACKING & TICKETS"),
        ],
      ),
    );
  }

  Widget _buildNewRequestForm(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.fileSignature, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                Text(
                  "Registrar Document Request",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel("Select Document Type", textColor),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRequestType,
              items: _requestTypes,
              hint: "Choose a document to request...",
              onChanged: (val) => setState(() => _selectedRequestType = val),
              textColor: textColor,
              fillColor: inputFill,
            ),
            const SizedBox(height: 20),
            _buildLabel("Purpose / Remarks", textColor),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: GoogleFonts.inter(color: textColor),
              decoration: InputDecoration(
                hintText: "e.g., For employment, scholarship, or transfer...",
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel("Support Documents (e.g. Scanned ID)", textColor),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() => _isUploading = true);
                Future.delayed(
                  const Duration(seconds: 1),
                  () => setState(() {
                    _isUploading = false;
                    _attachedFileName = "attachment_id_copy.png";
                  }),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: inputFill,
                ),
                child: _isUploading
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.uploadCloud,
                            color: subTextColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _attachedFileName ?? "Upload required documents",
                            style: TextStyle(color: subTextColor),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "SUBMIT TO REGISTRAR",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestHistory(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          "No request history found.",
          style: TextStyle(color: subTextColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        bool hasTicket =
            req['status'] == 'Accepted' || req['status'] == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(LucideIcons.fileText, color: const Color(0xFF8B5CF6)),
            title: Text(
              req['type'],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              "ID: ${req['id']} • ${req['date']}",
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),
            trailing: _statusBadge(req['status']),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    if (hasTicket)
                      _buildTicketSection(req, textColor, subTextColor),
                    const SizedBox(height: 16),
                    Text(
                      "TRACKING TIMELINE",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: subTextColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...req['timeline']
                        .map<Widget>(
                          (event) => _buildTimelineItem(
                            event,
                            textColor,
                            subTextColor,
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketSection(
    Map<String, dynamic> req,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CLAIM TICKET",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req['type'],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Verification Code: ${req['ticketCode']}",
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Present this QR code to the Registrar window for document releasing.",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.qrCode,
              color: Colors.black,
              size: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> event,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleDot, size: 14, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event['status'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      event['time'],
                      style: TextStyle(color: subTextColor, fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  event['msg'],
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: textColor.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    required Color textColor,
    required Color fillColor,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? fillColor : fillColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 14),
          ),
          isExpanded: true,
          dropdownColor: widget.isDarkMode
              ? const Color(0xFF1E1B4B)
              : Colors.white,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          onChanged: enabled ? onChanged : null,
          items: items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Completed'
        ? const Color(0xFF69F0AE)
        : (status == 'Accepted' ? Colors.blueAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
