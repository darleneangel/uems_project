import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentPlansPanel extends StatefulWidget {
  final bool isDarkMode;
  const PaymentPlansPanel({super.key, required this.isDarkMode});

  @override
  State<PaymentPlansPanel> createState() => _PaymentPlansPanelState();
}

class _PaymentPlansPanelState extends State<PaymentPlansPanel> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _installmentMonthsController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedPlan = 'Fully Paid';
  String _selectedPromissoryType = 'Academic';
  bool _isProcessing = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _totalAmountController.dispose();
    _installmentMonthsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _printPromissoryNote() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);
      
      // Simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Show print preview dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Promissory Note Preview"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PROMISSORY NOTE",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text("Student ID: ${_studentIdController.text}"),
                        Text("Total Amount: ₱${_totalAmountController.text}"),
                        Text("Payment Plan: $_selectedPlan"),
                        Text("Type: $_selectedPromissoryType"),
                        Text("Reason: ${_reasonController.text}"),
                        Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
                        const SizedBox(height: 20),
                        const Text("_________________________"),
                        const Text("Student Signature"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Promissory note sent to printer"),
                      backgroundColor: Color(0xFF69F0AE),
                    ),
                  );
                },
                child: const Text("PRINT"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _submitPaymentPlan() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Payment plan $_selectedPlan submitted successfully!"),
              backgroundColor: const Color(0xFF69F0AE),
            ),
          );
          _clearForm();
        }
      });
    }
  }

  void _clearForm() {
    _studentIdController.clear();
    _totalAmountController.clear();
    _installmentMonthsController.clear();
    _reasonController.clear();
    setState(() {
      _selectedPlan = 'Fully Paid';
      _selectedPromissoryType = 'Academic';
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
              Expanded(flex: 2, child: _buildPlanForm(cardColor, textColor, subTextColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildActivePlans(cardColor, textColor, subTextColor)),
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
            child: const Icon(LucideIcons.calendar, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Plans Management",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Fully Paid vs. Installments and Promissory Notes",
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

  Widget _buildPlanForm(Color cardColor, Color textColor, Color subTextColor) {
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
              "Create Payment Plan",
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
                hintText: "Enter student ID",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(
                  LucideIcons.user,
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
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter student ID";
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _totalAmountController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Total Amount (₱)",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(
                  LucideIcons.dollarSign,
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
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return "Please enter amount";
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedPlan,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              dropdownColor: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
              decoration: InputDecoration(
                labelText: "Payment Plan",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                prefixIcon: Icon(
                  LucideIcons.calendar,
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
                'Fully Paid',
                '2 Installments',
                '3 Installments',
                '4 Installments',
                '6 Installments',
                'Custom Installments',
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
                setState(() => _selectedPlan = value!);
              },
            ),
            const SizedBox(height: 16),
            
            if (_selectedPlan.contains('Installments'))
              TextFormField(
                controller: _installmentMonthsController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Number of Months",
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  hintText: "Enter number of months",
                  hintStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.calendar,
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
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedPlan.contains('Installments') && (value?.isEmpty ?? true)) {
                    return "Please enter number of months";
                  }
                  return null;
                },
              ),
            
            if (_selectedPlan.contains('Installments')) const SizedBox(height: 16),
            
            if (_selectedPlan.contains('Installments'))
              DropdownButtonFormField<String>(
                initialValue: _selectedPromissoryType,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                dropdownColor: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
                decoration: InputDecoration(
                  labelText: "Promissory Note Type",
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.fileText,
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
                  'Academic',
                  'Financial',
                  'Medical',
                  'Personal',
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
                  setState(() => _selectedPromissoryType = value!);
                },
              ),
            
            if (_selectedPlan.contains('Installments')) const SizedBox(height: 16),
            
            if (_selectedPlan.contains('Installments'))
              TextFormField(
                controller: _reasonController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Reason for Installments",
                  labelStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  hintText: "Explain why installment plan is needed",
                  hintStyle: TextStyle(
                    color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.messageSquare,
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
                maxLines: 3,
                validator: (value) {
                  if (_selectedPlan.contains('Installments') && (value?.isEmpty ?? true)) {
                    return "Please enter reason for installment plan";
                  }
                  return null;
                },
              ),
            
            if (_selectedPlan.contains('Installments')) const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _submitPaymentPlan,
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
                    label: Text(_isProcessing ? "PROCESSING..." : "SUBMIT PLAN"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_selectedPlan.contains('Installments')) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _printPromissoryNote,
                    icon: const Icon(LucideIcons.printer, size: 16),
                    label: const Text("PRINT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlans(Color cardColor, Color textColor, Color subTextColor) {
    final plans = [
      {
        'student': '2024-001',
        'plan': 'Fully Paid',
        'amount': '₱15,000',
        'status': 'Completed',
        'date': '2024-01-15',
      },
      {
        'student': '2024-002',
        'plan': '3 Installments',
        'amount': '₱45,000',
        'status': 'Active',
        'date': '2024-01-20',
      },
      {
        'student': '2024-003',
        'plan': '2 Installments',
        'amount': '₱30,000',
        'status': 'Pending',
        'date': '2024-01-22',
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
            "Active Payment Plans",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...plans.map((plan) => _planCard(plan, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _planCard(Map<String, String> plan, Color textColor, Color subTextColor) {
    Color statusColor;
    IconData statusIcon;
    
    switch (plan['status']) {
      case 'Completed':
        statusColor = const Color(0xFF69F0AE);
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'Active':
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = LucideIcons.activity;
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
                plan['student']!,
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
                      plan['status']!,
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
            plan['plan']!,
            style: GoogleFonts.inter(color: textColor),
          ),
          Text(
            plan['amount']!,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            plan['date']!,
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
