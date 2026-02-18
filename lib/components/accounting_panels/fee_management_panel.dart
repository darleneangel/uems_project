import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const FeeManagementPanel({super.key, required this.isDarkMode});

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  // Payment Entry State
  String _selectedCategory = "Tuition";
  String _selectedTerm = "Midterm Block A";
  String? _selectedBook;
  int _quantity = 1;
  int _printPages = 1;
  String _miscType = "Library Fine";
  double _customAmount = 0.0;
  String _paymentMethod = "Cash";

  // Cart State for "Checkout" style payment
  final List<Map<String, dynamic>> _cartItems = [];
  double get _cartTotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item['amount'] * (item['qty'] ?? 1)),
  );

  // --- MOCK DATABASE (Linked to Student ID) ---
  final Map<String, dynamic> _studentDb = {
    "2024-00001": {
      "name": "Darlene Angel",
      "id": "2024-00001",
      "course": "BS Computer Science",
      "year": "4th Year",
      "section": "BSCS-4A",
      "tuition_breakdown": {
        "Midterm Block A": 25000.0,
        "Finals Block B": 25000.0,
      },
      "balance": 15000.00,
      "status": "Overdue",
      "cleared": false,
      "scholarship": "Academic Scholar (20%)",
      "ledger": [
        {
          "date": "2025-01-15",
          "desc": "Tuition Fee (Prelim)",
          "debit": 20000.0,
          "credit": 0.0,
        },
        {
          "date": "2025-01-15",
          "desc": "Miscellaneous Fees",
          "debit": 5000.0,
          "credit": 0.0,
        },
        {
          "date": "2025-01-20",
          "desc": "Scholarship Discount",
          "debit": 0.0,
          "credit": 5000.0,
        },
        {
          "date": "2025-02-01",
          "desc": "Payment - Cash (OR#1001)",
          "debit": 0.0,
          "credit": 5000.0,
        },
      ],
    },
    "2024-00002": {
      "name": "John Doe",
      "id": "2024-00002",
      "course": "BS Info Tech",
      "year": "3rd Year",
      "section": "BSIT-3B",
      "tuition_breakdown": {
        "Midterm Block A": 20000.0,
        "Finals Block B": 20000.0,
      },
      "balance": 5500.00,
      "status": "Due Soon",
      "cleared": false,
      "scholarship": "None",
      "ledger": [
        {
          "date": "2025-01-15",
          "desc": "Tuition Fee",
          "debit": 18000.0,
          "credit": 0.0,
        },
        {
          "date": "2025-02-01",
          "desc": "Payment - Online",
          "debit": 0.0,
          "credit": 12500.0,
        },
      ],
    },
    "2024-00003": {
      "name": "Jane Smith",
      "id": "2024-00003",
      "course": "BS Business Ad",
      "year": "2nd Year",
      "section": "BSBA-2A",
      "tuition_breakdown": {
        "Midterm Block A": 18000.0,
        "Finals Block B": 18000.0,
      },
      "balance": 0.00,
      "status": "Cleared",
      "cleared": true,
      "scholarship": "Dean's Lister",
      "ledger": [
        {
          "date": "2025-01-15",
          "desc": "Tuition Fee",
          "debit": 15000.0,
          "credit": 0.0,
        },
        {
          "date": "2025-01-16",
          "desc": "Full Payment",
          "debit": 0.0,
          "credit": 15000.0,
        },
      ],
    },
  };

  final Map<String, double> _bookPrices = {
    "Intro to AI": 850.0,
    "Data Structures": 450.0,
    "Web Development": 600.0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _addToCart(String category, String item, double amount, {int qty = 1}) {
    setState(() {
      _cartItems.add({
        "category": category,
        "item": item,
        "amount": amount,
        "qty": qty,
      });
    });
  }

  void _addItemToCart() {
    if (_selectedCategory == "Tuition") {
      // Auto-load fee logic if available, otherwise use custom amount
      double amount = _customAmount;
      if (amount <= 0 &&
          _selectedStudentId != null &&
          _studentDb[_selectedStudentId]['tuition_breakdown'] != null) {
        amount =
            _studentDb[_selectedStudentId]['tuition_breakdown'][_selectedTerm] ??
            0.0;
      }

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount.")),
        );
        return;
      }
      _addToCart("Tuition", "Tuition - $_selectedTerm", amount);
    } else if (_selectedCategory == "Books") {
      final book = _selectedBook ?? _bookPrices.keys.first;
      final price = _bookPrices[book]!;
      _addToCart("Books", book, price, qty: _quantity);
    } else if (_selectedCategory == "Printing") {
      if (_printPages <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid number of pages.")),
        );
        return;
      }
      _addToCart("Printing", "Printing Services", 5.0, qty: _printPages);
    } else if (_selectedCategory == "Miscellaneous") {
      if (_customAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount.")),
        );
        return;
      }
      _addToCart("Miscellaneous", _miscType, _customAmount);
    }
    // Reset fields
    setState(() {
      // _customAmount = 0.0; // Keep amount for easier multiple entry if needed, or reset. Let's reset.
      _quantity = 1;
      _printPages = 1;
    });
  }

  // --- ACTIONS ---
  Future<void> _processTransaction() async {
    final id = _selectedStudentId!;
    final amount = _cartTotal;
    final itemsToPrint = List<Map<String, dynamic>>.from(_cartItems);

    setState(() {
      _studentDb[id]['balance'] -= amount;
      // Add consolidated or individual ledger entries
      for (var item in _cartItems) {
        _studentDb[id]['ledger'].add({
          "date": DateTime.now().toString().split(' ')[0],
          "desc": "${item['category']} - ${item['item']} (x${item['qty']})",
          "debit": 0.0,
          "credit": item['amount'] * item['qty'],
        });
      }

      if (_studentDb[id]['balance'] <= 0.01) {
        _studentDb[id]['balance'] = 0.0;
        _studentDb[id]['status'] = "Cleared";
        _studentDb[id]['cleared'] = true;
      }
      _cartItems.clear();
    });

    try {
      final path = await _generateReceipt(
        id,
        amount,
        _paymentMethod,
        itemsToPrint,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Receipt generated: $path")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating receipt: $e")));
    }
  }

  Future<String> _generateReceipt(
    String id,
    double amount,
    String method,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final pdf = pw.Document();
      final student = _studentDb[id];
      final isCleared = student['cleared'] == true;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "OFFICIAL RECEIPT",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "NO: ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Student: ${student['name']}"),
                      pw.Text("ID: ${student['id']}"),
                      pw.Text("Course: ${student['course']}"),
                      pw.Text("Year Level: ${student['year']}"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Date: ${DateTime.now().toString().split('.')[0]}",
                      ),
                      pw.Text("Payment Method: $method"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                "Transaction Summary",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Item', 'Qty', 'Amount'],
                data: items
                    .map(
                      (item) => [
                        item['item'],
                        item['qty'].toString(),
                        "PHP ${(item['amount'] * item['qty']).toStringAsFixed(2)}",
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL AMOUNT PAID",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "PHP ${amount.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Remaining Balance:"),
                  pw.Text(
                    "PHP ${student['balance'].toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: isCleared ? PdfColors.green : PdfColors.red,
                    ),
                  ),
                ],
              ),
              if (isCleared) ...[
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 2),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      "OFFICIALLY CLEARED",
                      style: pw.TextStyle(
                        color: PdfColors.green,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  "Thank you for your payment!",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/receipt_${id}_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint("Error opening file: ${result.message}");
      }
      return file.path;
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      rethrow;
    }
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
      children: [
          Container(
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
              Tab(text: "STUDENT LEDGER"),
              Tab(text: "PAYMENT PROCESSING"),
              Tab(text: "SCHOLARSHIPS"),
              Tab(text: "TRANSACTION HISTORY"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                child: _buildBillingList(cardColor, textColor, subTextColor),
              ),
              SingleChildScrollView(
                child: _buildPaymentProcessing(cardColor, textColor, subTextColor),
              ),
              SingleChildScrollView(
                child: _buildScholarshipsList(cardColor, textColor, subTextColor),
              ),
              SingleChildScrollView(
                child: _buildTransactionHistory(cardColor, textColor, subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingList(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_selectedStudentId != null) {
      return _buildStudentLedgerView(cardColor, textColor, subTextColor);
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Search Student ID or Name...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(LucideIcons.search, color: subTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.send, size: 16),
                label: const Text("SEND REMINDERS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _studentDb.entries
                  .where((entry) {
                    final s = entry.value;
                    final q = _searchController.text.toLowerCase();
                    return s['name'].toLowerCase().contains(q) ||
                        s['id'].contains(q);
                  })
                  .map((entry) {
                    final s = entry.value;
                    Color statusColor = s['status'] == 'Overdue'
                        ? Colors.redAccent
                        : (s['status'] == 'Cleared'
                              ? const Color(0xFF69F0AE)
                              : Colors.orangeAccent);
                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedStudentId = entry.key),
                      child: _studentRow(
                        s['name'],
                        s['section'],
                        "₱${s['balance'].toStringAsFixed(2)}",
                        s['status'],
                        statusColor,
                        textColor,
                        subTextColor,
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLedgerView(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final student = _studentDb[_selectedStudentId];
    if (student == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor),
                onPressed: () => setState(() => _selectedStudentId = null),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "${student['id']} • ${student['course']}",
                    style: TextStyle(color: subTextColor),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: student['cleared']
                      ? const Color(0xFF69F0AE).withOpacity(0.2)
                      : Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student['cleared'] ? "CLEARED" : "NOT CLEARED",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: student['cleared']
                        ? const Color(0xFF69F0AE)
                        : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Financial Ledger",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddFeeDialog(context, textColor, cardColor),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text("ADD FEE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: subTextColor.withOpacity(0.1),
                  ),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "Date",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "Description",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "Debit",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "Credit",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...(student['ledger'] as List).map(
                    (t) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            t['date'],
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            t['desc'],
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            t['debit'] > 0 ? "₱${t['debit']}" : "-",
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            t['credit'] > 0 ? "₱${t['credit']}" : "-",
                            style: TextStyle(
                              color: const Color(0xFF69F0AE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Total Balance: ", style: TextStyle(color: subTextColor)),
              Text(
                "₱${student['balance'].toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProcessing(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_selectedStudentId != null) {
      return _buildCheckoutInterface(cardColor, textColor, subTextColor);
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.creditCard,
            size: 48,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            "Process Tuition Payment",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Accept Cash, Card, or Digital Wallet payments instantly.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showStudentSelectionDialog(context, textColor, cardColor),
              icon: const Icon(LucideIcons.shoppingCart),
              label: const Text("START CHECKOUT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Supported: GCash, PayMaya, Bank Transfer",
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutInterface(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final student = _studentDb[_selectedStudentId];
    if (student == null) return const SizedBox();

    return Column(
      children: [
        // Enhanced Student Header
        _buildEnhancedStudentHeader(student, cardColor, textColor, subTextColor),
        const SizedBox(height: 20),
        
        // Main Content Row
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Payment Selection Panel
              Expanded(
                flex: 3,
                child: _buildEnhancedPaymentEntryForm(
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
              const SizedBox(width: 20),
              // RIGHT: Transaction Summary Panel
              Expanded(
                flex: 2,
                child: _buildEnhancedTransactionSummary(
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStudentHeader(
    Map<String, dynamic> student,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Student Avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.user,
              size: 32,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 20),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        student['id'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${student['course']} • ${student['year']}",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Balance Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Current Balance",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: student['balance'] > 0 
                      ? Colors.redAccent.withOpacity(0.1)
                      : const Color(0xFF69F0AE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: student['balance'] > 0 
                        ? Colors.redAccent.withOpacity(0.3)
                        : const Color(0xFF69F0AE).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  "₱${student['balance'].toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: student['balance'] > 0 
                        ? Colors.redAccent
                        : const Color(0xFF69F0AE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPaymentEntryForm(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.shoppingCart,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Selection",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "Add items to cart for payment processing",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Type Selection
          _buildEnhancedSectionHeader("Payment Type", LucideIcons.creditCard),
          const SizedBox(height: 8),
          _buildEnhancedDropdown(
            value: _selectedCategory,
            items: ["Tuition", "Books", "Printing", "Miscellaneous"],
            onChanged: (val) => setState(() {
              _selectedCategory = val!;
              _quantity = 1;
              _printPages = 1;
              _customAmount = 0.0;
            }),
            textColor: textColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 16),

          // Dynamic Form Fields
          if (_selectedCategory == "Tuition") ...[
            _buildEnhancedSectionHeader("Term / Block", LucideIcons.calendar),
            const SizedBox(height: 8),
            _buildEnhancedDropdown(
              value: _selectedTerm,
              items: ["Midterm Block A", "Finals Block B", "Summer"],
              onChanged: (val) => setState(() {
                _selectedTerm = val!;
                // Auto-load fee if available
                if (_selectedStudentId != null &&
                    _studentDb[_selectedStudentId]['tuition_breakdown'] !=
                        null) {
                  _customAmount =
                      _studentDb[_selectedStudentId]['tuition_breakdown'][val] ??
                      0.0;
                }
              }),
              textColor: textColor,
              cardColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildEnhancedAmountField(
              "Fee Amount (Auto-loaded)",
              textColor,
              (val) => _customAmount = double.tryParse(val) ?? 0.0,
              initialValue: _customAmount > 0 ? _customAmount.toString() : null,
            ),
          ] else if (_selectedCategory == "Books") ...[
            _buildEnhancedSectionHeader("Book Selection", LucideIcons.book),
            const SizedBox(height: 8),
            _buildEnhancedDropdown(
              value: _selectedBook ?? _bookPrices.keys.first,
              items: _bookPrices.keys.toList(),
              onChanged: (val) => setState(() => _selectedBook = val),
              textColor: textColor,
              cardColor: cardColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedNumberField(
                    "Quantity",
                    textColor,
                    _quantity,
                    (val) => setState(
                      () => _quantity = int.tryParse(val) ?? 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedPriceDisplay(
                    "Unit Price",
                    "₱${_bookPrices[_selectedBook ?? _bookPrices.keys.first]}",
                    textColor,
                  ),
                ),
              ],
            ),
          ] else if (_selectedCategory == "Printing") ...[
            _buildEnhancedSectionHeader("Printing Services", LucideIcons.printer),
            const SizedBox(height: 8),
            _buildEnhancedNumberField(
              "Number of Pages",
              textColor,
              _printPages,
              (val) => setState(() => _printPages = int.tryParse(val) ?? 1),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Rate: ₱5.00 / page",
                      style: GoogleFonts.inter(
                        color: Colors.blueAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_selectedCategory == "Miscellaneous") ...[
            _buildEnhancedSectionHeader("Miscellaneous Fee", LucideIcons.fileText),
            const SizedBox(height: 8),
            _buildEnhancedDropdown(
              value: _miscType,
              items: [
                "Graduation Fee",
                "Lab Fee",
                "Library Fine",
                "ID Replacement",
              ],
              onChanged: (val) => setState(() => _miscType = val!),
              textColor: textColor,
              cardColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildEnhancedAmountField(
              "Amount",
              textColor,
              (val) => _customAmount = double.tryParse(val) ?? 0.0,
            ),
          ],

          const Spacer(),
          
          // Add to Cart Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addItemToCart,
              icon: const Icon(LucideIcons.plus),
              label: const Text("ADD TO CART"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardColor,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 14,
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            color: textColor.withOpacity(0.6),
            size: 20,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEnhancedAmountField(
    String label,
    Color textColor,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixText: "₱ ",
            prefixStyle: GoogleFonts.inter(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          controller: initialValue != null
              ? TextEditingController(text: initialValue)
              : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEnhancedNumberField(
    String label,
    Color textColor,
    int value,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          controller: initialValue != null
              ? TextEditingController(text: initialValue)
              : TextEditingController(text: ''),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEnhancedPriceDisplay(
    String label,
    String price,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF69F0AE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF69F0AE).withOpacity(0.3),
            ),
          ),
          child: Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF69F0AE),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTransactionSummary(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  color: Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Transaction Summary",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cart Items
          if (_cartItems.isEmpty)
            _buildEmptyCartState(subTextColor)
          else
            _buildCartItemsList(textColor, subTextColor),

          const SizedBox(height: 12),

          // Total Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Amount",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  "₱${_cartTotal.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cartItems.isNotEmpty ? () {
                if (_paymentMethod == "QR Code") {
                  _showQRPaymentDialog(context, cardColor, textColor);
                } else {
                  _processCheckout();
                }
              } : null,
              icon: Icon(
                _paymentMethod == "QR Code" ? LucideIcons.qrCode : LucideIcons.creditCard,
              ),
              label: Text(_paymentMethod == "QR Code" ? "GENERATE QR CODE" : "MARK AS PAID"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentMethod == "QR Code" ? Colors.blueAccent : Colors.greenAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState(Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: (widget.isDarkMode ? Colors.white10 : Colors.black12).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.shoppingCart,
            size: 48,
            color: subTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            "No items in cart",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items from the left panel to get started",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: subTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(Color textColor, Color subTextColor) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cartItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item['category']} • Qty: ${item['qty']}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₱${(item['amount'] * item['qty']).toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF69F0AE),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => setState(() => _cartItems.removeAt(index)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
    Widget _buildScholarshipsList(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Center(
      child: Text(
        "Scholarship Management Module",
        style: TextStyle(color: subTextColor),
      ),
    );
  }

  Widget _buildTransactionHistory(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            "Search Student Transaction History",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Enter Student ID...",
              hintStyle: TextStyle(color: subTextColor),
              prefixIcon: Icon(LucideIcons.search, color: subTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) {
              // Simple search logic: if ID matches exactly, show history
              if (_studentDb.containsKey(val)) {
                setState(() => _selectedStudentId = val);
              } else if (val.isEmpty) {
                setState(() => _selectedStudentId = null);
              }
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _selectedStudentId == null
                ? Center(
                    child: Text(
                      "Enter a valid Student ID to view history",
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : _buildStudentLedgerView(cardColor, textColor, subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(
    String name,
    String section,
    String balance,
    String status,
    Color statusColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: widget.isDarkMode
                ? Colors.white10
                : Colors.grey.shade200,
            child: Icon(LucideIcons.user, size: 16, color: textColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  section,
                  style: GoogleFonts.inter(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStudentSelectionDialog(
    BuildContext context,
    Color textColor,
    Color cardColor,
  ) {
    final idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          "Select Student for Checkout",
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: idController,
          decoration: InputDecoration(
            labelText: "Student ID",
            hintText: "e.g., 2024-00001",
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          ),
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_studentDb.containsKey(idController.text)) {
                setState(() => _selectedStudentId = idController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student ID not found.")),
                );
              }
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    Color textColor,
    Color cardColor, {
    double? initialAmount,
  }) {
    final idController = TextEditingController();
    final amountController = TextEditingController(
      text: initialAmount?.toString(),
    );
    String method = "Cash";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text("New Payment", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: "Student ID",
                hintText: _selectedStudentId,
              ),
              style: TextStyle(color: textColor),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
            ),
            DropdownButton<String>(
              value: method,
              dropdownColor: cardColor,
              items: ["Cash", "Credit Card", "GCash", "PayMaya"]
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m, style: TextStyle(color: textColor)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => method = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final targetId = idController.text.isNotEmpty
                  ? idController.text
                  : _selectedStudentId;
              if (targetId != null && _studentDb.containsKey(targetId)) {
                _processPayment(
                  targetId,
                  double.tryParse(amountController.text) ?? 0.0,
                  method,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment Successful! Receipt Generated."),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student ID not found.")),
                );
              }
            },
            child: const Text("Process"),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        color: textColor.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardColor,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(color: textColor)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAmountField(
    Color textColor,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return TextField(
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixText: "₱ ",
        prefixStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(
    Color textColor,
    int value,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return TextField(
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      onChanged: onChanged,
    );
  }

  void _processPayment(String id, double amount, String method) {
    final student = _studentDb[id];
    if (student == null) return;

    setState(() {
      student['balance'] -= amount;
      student['ledger'].add({
        "date": DateTime.now().toString().split(' ')[0],
        "desc": "Payment - $method",
        "debit": 0.0,
        "credit": amount,
      });

      if (student['balance'] <= 0) {
        student['balance'] = 0.0;
        student['status'] = "Cleared";
        student['cleared'] = true;
      }
    });

    _generateReceipt(id, amount, method, [
      {"item": "Payment", "amount": amount, "qty": 1},
    ]);
  }

  Widget _buildQRCodePaymentSection(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.qrCode,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "QR Code Payment",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: 'PAY_${_selectedStudentId}_${_cartTotal.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}',
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Scan QR Code to Pay",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Amount: ₱${_cartTotal.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "QR code is valid for 15 minutes. Please ensure payment is completed within this time.",
                    style: GoogleFonts.inter(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRPaymentDialog(BuildContext context, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          "QR Code Generated",
          style: TextStyle(color: textColor),
        ),
        content: _buildQRCodePaymentSection(cardColor, textColor, textColor.withOpacity(0.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _processCheckout() {
    if (_selectedStudentId != null && _cartItems.isNotEmpty) {
      final student = _studentDb[_selectedStudentId!];
      if (student != null) {
        setState(() {
          student['balance'] -= _cartTotal;
          student['ledger'].add({
            "date": DateTime.now().toString().split(' ')[0],
            "desc": "Payment - ${_paymentMethod}",
            "debit": 0.0,
            "credit": _cartTotal,
          });

          if (student['balance'] <= 0) {
            student['balance'] = 0.0;
            student['status'] = "Cleared";
            student['cleared'] = true;
          }

          _cartItems.clear();
        });

        _generateReceipt(_selectedStudentId!, _cartTotal, _paymentMethod, _cartItems);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Successful! Receipt Generated."),
          ),
        );
      }
    }
  }

  void _showAddFeeDialog(
    BuildContext context,
    Color textColor,
    Color cardColor,
  ) {
    // Implementation for adding miscellaneous fees
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          "Add Miscellaneous Fee",
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Description"),
              style: TextStyle(color: textColor),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Add Fee"),
          ),
        ],
      ),
    );
  }
}
