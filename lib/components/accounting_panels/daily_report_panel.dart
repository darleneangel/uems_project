import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DailyReportPanel extends StatefulWidget {
  final bool isDarkMode;
  const DailyReportPanel({super.key, required this.isDarkMode});

  @override
  State<DailyReportPanel> createState() => _DailyReportPanelState();
}

class _DailyReportPanelState extends State<DailyReportPanel> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _totalRevenueController = TextEditingController();
  final _totalExpensesController = TextEditingController();
  final _netIncomeController = TextEditingController();
  final _transactionsController = TextEditingController();
  String _selectedReportType = 'Daily Summary';
  bool _isGenerating = false;

  @override
  void dispose() {
    _dateController.dispose();
    _totalRevenueController.dispose();
    _totalExpensesController.dispose();
    _netIncomeController.dispose();
    _transactionsController.dispose();
    super.dispose();
  }

  void _generateReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isGenerating = true);
      
      // Simulate report generation
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() => _isGenerating = false);
        _showReportPreview();
      }
    }
  }

  void _showReportPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Daily Report Preview"),
        content: SizedBox(
          width: 600,
          height: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(),
                const SizedBox(height: 20),
                _buildFinancialSummary(),
                const SizedBox(height: 20),
                _buildTransactionBreakdown(),
                const SizedBox(height: 20),
                _buildGraphSection(),
              ],
            ),
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
                  content: Text("Report exported successfully!"),
                  backgroundColor: Color(0xFF69F0AE),
                ),
              );
            },
            child: const Text("EXPORT PDF"),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UNIVERSITY EDUCATION MANAGEMENT SYSTEM",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "DAILY FINANCIAL REPORT",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Report Date: ${_dateController.text}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Text(
                "Generated: ${DateTime.now().toString().split(' ')[0]}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "FINANCIAL SUMMARY",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  "Total Revenue",
                  _totalRevenueController.text,
                  const Color(0xFF69F0AE),
                  LucideIcons.trendingUp,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryCard(
                  "Total Expenses",
                  _totalExpensesController.text,
                  Colors.redAccent,
                  LucideIcons.trendingDown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryCard(
            "Net Income",
            _netIncomeController.text,
            const Color(0xFF8B5CF6),
            LucideIcons.dollarSign,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown() {
    final transactions = [
      {"category": "Tuition Fees", "amount": "₱125,000", "count": "45"},
      {"category": "Laboratory Fees", "amount": "₱23,500", "count": "12"},
      {"category": "Library Fees", "amount": "₱8,200", "count": "8"},
      {"category": "Miscellaneous", "amount": "₱15,300", "count": "23"},
      {"category": "Scholarship Disbursements", "amount": "-₱45,000", "count": "5"},
      {"category": "Faculty Salaries", "amount": "-₱125,000", "count": "15"},
      {"category": "Operational Costs", "amount": "-₱18,000", "count": "10"},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TRANSACTION BREAKDOWN",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
          const SizedBox(height: 16),
          ...transactions.map((transaction) => _transactionItem(transaction)),
        ],
      ),
    );
  }

  Widget _transactionItem(Map<String, String> transaction) {
    final isIncome = !transaction["amount"]!.startsWith("-");
    final color = isIncome ? const Color(0xFF69F0AE) : Colors.redAccent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction["category"]!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "${transaction["count"]} transactions",
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction["amount"]!,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REVENUE VS EXPENSES TREND",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _ReportGraphPainter(widget.isDarkMode),
              child: Container(),
            ),
          ),
        ],
      ),
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
              Expanded(flex: 2, child: _buildReportForm(cardColor, textColor, subTextColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildQuickStats(cardColor, textColor, subTextColor)),
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
                  "Daily Report Generation",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Generate comprehensive daily financial reports with analytics",
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

  Widget _buildReportForm(Color cardColor, Color textColor, Color subTextColor) {
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
              "Report Configuration",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _dateController,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: "Report Date",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "Select date",
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
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dateController.text = date.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedReportType,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              dropdownColor: widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white,
              decoration: InputDecoration(
                labelText: "Report Type",
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
                'Daily Summary',
                'Weekly Summary',
                'Monthly Summary',
                'Custom Range',
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
                setState(() => _selectedReportType = value!);
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalRevenueController,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: "Total Revenue (₱)",
                      labelStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      hintText: "0.00",
                      hintStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.trendingUp,
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
                      if (value?.isEmpty ?? true) return "Please enter total revenue";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _totalExpensesController,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: "Total Expenses (₱)",
                      labelStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      hintText: "0.00",
                      hintStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.trendingDown,
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
                      if (value?.isEmpty ?? true) return "Please enter total expenses";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _netIncomeController,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: "Net Income (₱)",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "Auto-calculated",
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
              readOnly: true,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _transactionsController,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: "Total Transactions",
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                hintText: "0",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: Icon(
                  LucideIcons.activity,
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
                if (value?.isEmpty ?? true) return "Please enter transaction count";
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: _isGenerating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.fileText, size: 16),
                    label: Text(_isGenerating ? "GENERATING..." : "GENERATE REPORT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    _clearForm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Form cleared"),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text("CLEAR"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(Color cardColor, Color textColor, Color subTextColor) {
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
            "Today's Quick Stats",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Payments Received",
                  "23",
                  const Color(0xFF69F0AE),
                  LucideIcons.checkCircle,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  "Pending Approvals",
                  "5",
                  Colors.orangeAccent,
                  LucideIcons.clock,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Reports Generated",
                  "8",
                  const Color(0xFF8B5CF6),
                  LucideIcons.fileText,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  "E-Receipts Sent",
                  "15",
                  Colors.blueAccent,
                  LucideIcons.mail,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    Color color,
    IconData icon,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _dateController.clear();
    _totalRevenueController.clear();
    _totalExpensesController.clear();
    _netIncomeController.clear();
    _transactionsController.clear();
    setState(() {
      _selectedReportType = 'Daily Summary';
    });
  }
}

class _ReportGraphPainter extends CustomPainter {
  final bool isDarkMode;
  
  _ReportGraphPainter(this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);
    
    // Grid lines
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 6) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Draw vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 7) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    // Revenue line (green)
    final revenuePaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final revenuePoints = [
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.2),
    ];
    
    final revenuePath = Path();
    revenuePath.moveTo(revenuePoints.first.dx, revenuePoints.first.dy);
    for (int i = 1; i < revenuePoints.length; i++) {
      revenuePath.lineTo(revenuePoints[i].dx, revenuePoints[i].dy);
    }
    canvas.drawPath(revenuePath, revenuePaint);
    
    // Expense line (red)
    final expensePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final expensePoints = [
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.3),
    ];
    
    final expensePath = Path();
    expensePath.moveTo(expensePoints.first.dx, expensePoints.first.dy);
    for (int i = 1; i < expensePoints.length; i++) {
      expensePath.lineTo(expensePoints[i].dx, expensePoints[i].dy);
    }
    canvas.drawPath(expensePath, expensePaint);
    
    // Draw points
    final pointPaint = Paint()
      ..style = PaintingStyle.fill;
    
    for (final point in revenuePoints) {
      pointPaint.color = const Color(0xFF69F0AE);
      canvas.drawCircle(point, 4, pointPaint);
    }
    
    for (final point in expensePoints) {
      pointPaint.color = Colors.redAccent;
      canvas.drawCircle(point, 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
