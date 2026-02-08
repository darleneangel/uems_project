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
  String? _selectedOffice;
  String? _selectedRequestType;
  final TextEditingController _messageController = TextEditingController();
  bool _isUploading = false;
  String? _attachedFileName;

  // --- MOCK DATA CONFIGURATION ---
  final Map<String, List<String>> _officeServices = {
    "Registrar": [
      "Transcript of Records",
      "Enrollment Verification",
      "Diploma Request",
      "Honorable Dismissal",
      "Form 137",
    ],
    "Accounting": [
      "Balance Inquiry",
      "Payment Receipt",
      "Promissory Note",
      "Refund Request",
      "Scholarship Application",
    ],
    "Program Office": [
      "Petition for Overload",
      "Subject Crediting",
      "Curriculum Shift",
      "Advising Session",
    ],
    "OSAS": [
      "ID Replacement",
      "Good Moral Certificate",
      "Lost & Found Inquiry",
      "Org Accreditation",
    ],
    "Clinic": [
      "Medical Certificate",
      "Dental Appointment",
      "Health Record Update",
    ],
  };

  // --- MOCK REQUEST HISTORY ---
  final List<Map<String, dynamic>> _requests = [
    {
      "id": "REQ-2026-8821",
      "office": "Registrar",
      "type": "Transcript of Records",
      "status": "Completed",
      "date": "2026-02-10 09:30",
      "tat": "3-5 Days",
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
        {
          "status": "Processing",
          "time": "Feb 12, 02:00 PM",
          "msg": "Printing document.",
        },
        {
          "status": "Completed",
          "time": "Feb 14, 08:00 AM",
          "msg": "Ready for pickup at Window 3.",
        },
      ],
    },
    {
      "id": "REQ-2026-9005",
      "office": "Accounting",
      "type": "Promissory Note",
      "status": "In Review",
      "date": "2026-03-25 13:15",
      "tat": "1-2 Days",
      "timeline": [
        {
          "status": "Submitted",
          "time": "Mar 25, 01:15 PM",
          "msg": "Request submitted with letter.",
        },
        {
          "status": "In Review",
          "time": "Mar 26, 08:45 AM",
          "msg": "Assigned to Finance Officer.",
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
    if (_selectedOffice == null || _selectedRequestType == null) return;

    setState(() {
      final newId = "REQ-2026-${1000 + Random().nextInt(9000)}";
      final now = DateTime.now().toString().substring(0, 16);

      _requests.insert(0, {
        "id": newId,
        "office": _selectedOffice,
        "type": _selectedRequestType,
        "status": "Submitted",
        "date": now,
        "tat": "Pending",
        "timeline": [
          {
            "status": "Submitted",
            "time": now,
            "msg": "Request submitted via portal.",
          },
        ],
      });

      // Reset Form
      _selectedOffice = null;
      _selectedRequestType = null;
      _messageController.clear();
      _attachedFileName = null;

      // Switch to history tab
      _tabController.animateTo(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request submitted successfully!")),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDashboardSummary(cardColor, textColor),
        const SizedBox(height: 24),
        _buildTabBar(textColor),
        const SizedBox(height: 24),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNewRequestForm(cardColor, textColor, subTextColor),
              _buildRequestHistory(cardColor, textColor, subTextColor),
            ],
          ),
        ),
      ],
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
          "Active Requests",
          active.toString(),
          Colors.blueAccent,
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Completed",
          completed.toString(),
          const Color(0xFF69F0AE),
          cardColor,
          textColor,
        ),
        const SizedBox(width: 16),
        _statCard(
          "Pending Action",
          "0",
          Colors.orangeAccent,
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
        padding: const EdgeInsets.all(20),
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
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
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
      height: 50,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF8B5CF6),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: "NEW REQUEST"),
          Tab(text: "MY REQUESTS"),
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Submit a New Request",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),

            // Office Selection
            _buildLabel("Select Office", textColor),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedOffice,
              items: _officeServices.keys.toList(),
              hint: "Choose destination office...",
              onChanged: (val) => setState(() {
                _selectedOffice = val;
                _selectedRequestType = null; // Reset type when office changes
              }),
              textColor: textColor,
              fillColor: inputFill,
            ),
            const SizedBox(height: 20),

            // Request Type Selection
            _buildLabel("Request Type", textColor),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRequestType,
              items: _selectedOffice != null
                  ? _officeServices[_selectedOffice]!
                  : [],
              hint: "Select service type...",
              onChanged: (val) => setState(() => _selectedRequestType = val),
              textColor: textColor,
              fillColor: inputFill,
              enabled: _selectedOffice != null,
            ),
            const SizedBox(height: 20),

            // Message / Details
            _buildLabel("Additional Details / Message", textColor),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: GoogleFonts.inter(color: textColor),
              decoration: InputDecoration(
                hintText: "Provide specific details about your request...",
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

            // File Upload Simulation
            _buildLabel("Attachments (Optional)", textColor),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() => _isUploading = true);
                Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                    _isUploading = false;
                    _attachedFileName = "scanned_document.pdf";
                  });
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white24 : Colors.black26,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: inputFill,
                ),
                child: _isUploading
                    ? Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor,
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
                            _attachedFileName ??
                                "Click to upload supporting documents",
                            style: TextStyle(color: subTextColor),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text("SUBMIT REQUEST"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          "No requests found.",
          style: TextStyle(color: subTextColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            shape: Border.all(color: Colors.transparent),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.fileText,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            title: Text(
              req['type'],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Text(
              "${req['office']} • ${req['id']}",
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
            trailing: _statusBadge(req['status']),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Estimated Completion: ${req['tat']}",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (req['status'] == 'Completed')
                          TextButton.icon(
                            onPressed: () {}, // Download logic
                            icon: const Icon(LucideIcons.download, size: 14),
                            label: const Text("Download Document"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF69F0AE),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "TRACKING TIMELINE",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: subTextColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(req['timeline'].length, (i) {
                      final event = req['timeline'][i];
                      final isLast = i == req['timeline'].length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Icon(
                                LucideIcons.circleDot,
                                size: 14,
                                color: isLast
                                    ? const Color(0xFF8B5CF6)
                                    : subTextColor,
                              ),
                              if (i != req['timeline'].length - 1)
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: widget.isDarkMode
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event['status'],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      event['time'],
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  event['msg'],
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          hint: Text(hint, style: TextStyle(color: textColor.withOpacity(0.4))),
          isExpanded: true,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 18,
            color: textColor.withOpacity(0.5),
          ),
          dropdownColor: widget.isDarkMode
              ? const Color(0xFF1E1B4B)
              : Colors.white,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          onChanged: enabled ? onChanged : null,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = const Color(0xFF69F0AE);
        break;
      case 'In Review':
        color = Colors.blueAccent;
        break;
      case 'Submitted':
        color = Colors.orangeAccent;
        break;
      case 'Rejected':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }
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

/*
  Widget _clearanceCard(
    String title,
    bool isDone,
    IconData icon,
    Color cardColor,
    Color textColor,
  ) {
    final statusColor = isDone
        ? const Color(0xFF69F0AE)
        : const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? statusColor.withOpacity(0.2) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDone ? "Cleared" : "Pending",
                  style: TextStyle(
                    color: isDone ? statusColor : textColor.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isDone ? LucideIcons.checkCircle : LucideIcons.clock,
            color: statusColor.withOpacity(0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
*/
