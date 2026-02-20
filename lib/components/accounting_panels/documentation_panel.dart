import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DocumentationPanel extends StatefulWidget {
  final bool isDarkMode;
  const DocumentationPanel({super.key, required this.isDarkMode});

  @override
  State<DocumentationPanel> createState() => _DocumentationPanelState();
}

class _DocumentationPanelState extends State<DocumentationPanel> {
  final _emailController = TextEditingController();
  final _receiptIdController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedDocumentType = 'E-Receipt';
  bool _isSending = false;
  String _activeQuickAction = 'all';

  @override
  void dispose() {
    _emailController.dispose();
    _receiptIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendEReceipt() {
    if (_emailController.text.isEmpty || _receiptIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("E-Receipt sent to ${_emailController.text}"),
            backgroundColor: const Color(0xFF69F0AE),
          ),
        );
        _clearForm();
      }
    });
  }

  void _clearForm() {
    _emailController.clear();
    _receiptIdController.clear();
  }

  void _toggleQuickAction(String key) {
    setState(() {
      _activeQuickAction = _activeQuickAction == key ? 'all' : key;
    });
  }

  List<Map<String, String>> _filterDocuments(List<Map<String, String>> documents) {
    switch (_activeQuickAction) {
      case 'pending':
        return documents.where((doc) => doc['status'] == 'Pending').toList();
      case 'approved':
        return documents.where((doc) => doc['status'] == 'Approved').toList();
      case 'rejected':
        return documents.where((doc) => doc['status'] == 'Rejected').toList();
      default:
        return documents;
    }
  }

  void _showApprovalBasis(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Basis of Approval - $requestId"),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasisSection("Student Information", [
                "Student ID: 2024-001",
                "Name: Juan Dela Cruz",
                "Program: BSCS",
                "Year: 2nd Year",
                "GWA: 1.75",
              ]),
              const SizedBox(height: 16),
              _buildBasisSection("Financial Status", [
                "Previous Payments: Fully Paid",
                "Outstanding Balance: ₱0.00",
                "Scholarship: Dean's Lister (25% discount)",
                "Payment History: Excellent",
              ]),
              const SizedBox(height: 16),
              _buildBasisSection("Academic Standing", [
                "Units Enrolled: 21 units",
                "Attendance: 95%",
                "No disciplinary records",
                "Good moral character",
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Color(0xFF69F0AE), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "RECOMMENDATION: APPROVED",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF69F0AE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Student meets all requirements for financial clearance. No outstanding balances and good academic standing.",
                      style: GoogleFonts.inter(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Approval basis exported to PDF"),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text("EXPORT PDF"),
          ),
        ],
      ),
    );
  }

  Widget _buildBasisSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            "• $item",
            style: GoogleFonts.inter(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildEmailForm(cardColor, textColor, subTextColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildDocumentSearch(cardColor, textColor, subTextColor)),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentDocuments(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Documentation Management",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "E-Receipts and Basis of Approve & Reject for financial clearance",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send E-Receipt",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _receiptIdController,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "Receipt ID",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hintText: "Enter receipt ID",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                LucideIcons.hash,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "Email Address",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hintText: "student@university.edu",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                LucideIcons.mail,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedDocumentType,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            dropdownColor: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
            decoration: InputDecoration(
              labelText: "Document Type",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              prefixIcon: Icon(
                LucideIcons.file,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            items: [
              'E-Receipt',
              'Certificate of Payment',
              'Tax Certificate',
              'Financial Clearance',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() => _selectedDocumentType = value!);
            },
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendEReceipt,
                  icon: _isSending 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.send, size: 16),
                  label: Text(_isSending ? "SENDING..." : "SEND EMAIL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _clearForm,
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text("CLEAR"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSearch(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Search Documents",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _searchController,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "Search by ID, Name, or Email",
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hintText: "Enter search term...",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Search completed"),
                        backgroundColor: Color(0xFF69F0AE),
                      ),
                    );
                  }
                },
                icon: Icon(
                  LucideIcons.search,
                  color: widget.isDarkMode ? Colors.white54 : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            "Quick Actions",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          _quickActionButton(
            "Pending Approvals",
            "5 requests",
            LucideIcons.clock,
            Colors.orangeAccent,
            textColor,
            subTextColor,
            isActive: _activeQuickAction == 'pending',
            onTap: () => _toggleQuickAction('pending'),
          ),
          const SizedBox(height: 8),
          
          _quickActionButton(
            "Approved Today",
            "12 documents",
            LucideIcons.checkCircle,
            const Color(0xFF69F0AE),
            textColor,
            subTextColor,
            isActive: _activeQuickAction == 'approved',
            onTap: () => _toggleQuickAction('approved'),
          ),
          const SizedBox(height: 8),
          
          _quickActionButton(
            "Rejected Requests",
            "2 requests",
            LucideIcons.xCircle,
            Colors.redAccent,
            textColor,
            subTextColor,
            isActive: _activeQuickAction == 'rejected',
            onTap: () => _toggleQuickAction('rejected'),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color textColor,
    Color subTextColor,
    {
      required bool isActive,
      required VoidCallback onTap,
    }
  ) {
    final baseColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.withOpacity(0.05);
    final activeColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.withOpacity(0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? (widget.isDarkMode ? Colors.white24 : Colors.black26)
                : (widget.isDarkMode ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: widget.isDarkMode ? Colors.white54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocuments(Color cardColor, Color textColor, Color subTextColor) {
    final documents = [
      {
        'id': 'DOC-001',
        'type': 'E-Receipt',
        'student': '2024-001',
        'email': 'student1@university.edu',
        'status': 'Sent',
        'date': 'Today, 10:30 AM',
      },
      {
        'id': 'DOC-002',
        'type': 'Financial Clearance',
        'student': '2024-002',
        'email': 'student2@university.edu',
        'status': 'Pending',
        'date': 'Today, 9:15 AM',
      },
      {
        'id': 'DOC-003',
        'type': 'Certificate of Payment',
        'student': '2024-003',
        'email': 'student3@university.edu',
        'status': 'Approved',
        'date': 'Yesterday, 3:45 PM',
      },
    ];

    final filteredDocuments = _filterDocuments(documents);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Documents",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (filteredDocuments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No documents found for this filter.",
                style: GoogleFonts.inter(
                  color: subTextColor,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...filteredDocuments.map((doc) => _documentCard(doc, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _documentCard(Map<String, String> doc, Color textColor, Color subTextColor) {
    Color statusColor;
    IconData statusIcon;
    
    switch (doc['status']) {
      case 'Sent':
        statusColor = const Color(0xFF69F0AE);
        statusIcon = LucideIcons.send;
        break;
      case 'Approved':
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = LucideIcons.checkCircle;
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusIcon = LucideIcons.clock;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      doc['id']!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            doc['status']!,
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${doc['type']} - ${doc['student']}",
                  style: GoogleFonts.inter(color: textColor),
                ),
                Text(
                  doc['email']!,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  doc['date']!,
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              IconButton(
                onPressed: () => _showApprovalBasis(doc['id']!),
                icon: const Icon(LucideIcons.eye),
                tooltip: "View Approval Basis",
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Document downloaded"),
                      backgroundColor: Color(0xFF69F0AE),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.download),
                tooltip: "Download",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
