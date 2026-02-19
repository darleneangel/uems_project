import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentRequestPanel extends StatefulWidget {
  final bool isDarkMode;
  const PaymentRequestPanel({super.key, required this.isDarkMode});

  @override
  State<PaymentRequestPanel> createState() => _PaymentRequestPanelState();
}

class _PaymentRequestPanelState extends State<PaymentRequestPanel> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedPaymentType = 'Tuition Fee';
  String _selectedUrgency = 'Normal';
  bool _isProcessing = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);
      
      // Simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment request submitted successfully!"),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
        _clearForm();
      }
    }
  }

  void _clearForm() {
    _studentIdController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _emailController.clear();
    setState(() {
      _selectedPaymentType = 'Tuition Fee';
      _selectedUrgency = 'Normal';
    });
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
              Expanded(flex: 2, child: _buildRequestForm(cardColor, textColor, subTextColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildRecentRequests(cardColor, textColor, subTextColor)),
            ],
          ),
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
                  "Payment Request Management",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Digital workflow for fee requests and approvals",
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _clearForm,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text("CLEAR FORM"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestForm(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New Payment Request",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _studentIdController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Student ID",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "Enter student ID (e.g., 2024-001)",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(LucideIcons.user, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter student ID";
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "student@university.edu",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(LucideIcons.mail, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter email";
                if (!value!.contains('@')) return "Please enter valid email";
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedPaymentType,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Payment Type",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                prefixIcon: Icon(LucideIcons.tag, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              items: [
                'Tuition Fee',
                'Laboratory Fee',
                'Library Fee',
                'Miscellaneous Fee',
                'Thesis Fee',
                'Graduation Fee',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: textColor)),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() => _selectedPaymentType = value!);
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _amountController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Amount (₱)",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(LucideIcons.dollarSign, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter amount";
                if (double.tryParse(value!) == null) return "Please enter valid amount";
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedUrgency,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Urgency Level",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                prefixIcon: Icon(LucideIcons.alertCircle, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              items: [
                'Normal',
                'Urgent',
                'Emergency',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: textColor)),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() => _selectedUrgency = value!);
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "Additional details about the payment request",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(LucideIcons.fileText, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
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
                  borderSide: BorderSide(
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter description";
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _submitRequest,
                    icon: _isProcessing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 16),
                    label: Text(_isProcessing ? "PROCESSING..." : "SUBMIT REQUEST"),
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
                  label: const Text("CANCEL"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequests(Color cardColor, Color textColor, Color subTextColor) {
    final requests = [
      {
        'id': 'REQ-001',
        'student': '2024-001',
        'type': 'Tuition Fee',
        'amount': '₱15,000',
        'status': 'Pending',
        'date': 'Today, 10:30 AM',
      },
      {
        'id': 'REQ-002',
        'student': '2024-002',
        'type': 'Laboratory Fee',
        'amount': '₱3,500',
        'status': 'Approved',
        'date': 'Today, 9:15 AM',
      },
      {
        'id': 'REQ-003',
        'student': '2024-003',
        'type': 'Library Fee',
        'amount': '₱500',
        'status': 'Rejected',
        'date': 'Yesterday, 3:45 PM',
      },
    ];

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
            "Recent Requests",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...requests.map((request) => _requestCard(request, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, String> request, Color textColor, Color subTextColor) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request['status']) {
      case 'Approved':
        statusColor = const Color(0xFF69F0AE);
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'Rejected':
        statusColor = Colors.redAccent;
        statusIcon = LucideIcons.xCircle;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['id']!,
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
                      request['status']!,
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
            "${request['student']} - ${request['type']}",
            style: GoogleFonts.inter(color: textColor),
          ),
          Text(
            request['amount']!,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            request['date']!,
            style: GoogleFonts.inter(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
