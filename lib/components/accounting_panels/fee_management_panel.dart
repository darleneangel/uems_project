import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _amountInputController = TextEditingController();

  // Payment Entry State
  String _selectedCategory = "Tuition";
  String _selectedTerm = "Midterm Block A";
  String? _selectedBook;
  int _quantity = 1;
  String _miscType = "Library Fine";
  int _printPages = 1;
  double _customAmount = 0.0;
  double _manualAmount = 0.0;
  String _paymentMethod = "Cash";

  // Scholarship State
  final TextEditingController _scholarshipSearchController =
      TextEditingController();
  String _scholarshipFilter = "All";
  final List<Map<String, dynamic>> _availableScholarships = [
    {
      "name": "Academic Scholar",
      "discount": 0.20,
      "type": "Merit",
    },
    {
      "name": "Dean's Lister",
      "discount": 0.30,
      "type": "Merit",
    },
    {
      "name": "Athletic Grant",
      "discount": 0.25,
      "type": "Athletics",
    },
    {
      "name": "Financial Aid",
      "discount": 0.35,
      "type": "Needs-Based",
    },
    {
      "name": "Staff Dependent",
      "discount": 0.15,
      "type": "Special",
    },
  ];

  // Cart State for "Checkout" style payment
  final List<Map<String, dynamic>> _cartItems = [];
  double get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + (item['amount'] * item['qty']));

  // Theme Constants
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF7C3AED);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  // --- MOCK DATABASE ---
  final Map<String, dynamic> _studentDb = {
    "2024-00001": {
      "name": "DARLENE ANGEL",
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
          "date": "2025-01-20",
          "desc": "Scholarship Discount",
          "debit": 0.0,
          "credit": 5000.0,
        },
      ],
    },
    "2024-00002": {
      "name": "JUAN DELA CRUZ",
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

  void _addItemToCart() {
    double amount = 0;
    String label = "";

    if (_selectedCategory == "Tuition") {
      amount = _manualAmount > 0
          ? _manualAmount
          : (_studentDb[_selectedStudentId]['tuition_breakdown'][_selectedTerm] ??
                0.0);
      label = "Tuition: $_selectedTerm";
    } else if (_selectedCategory == "Books") {
      final book = _selectedBook ?? _bookPrices.keys.first;
      amount = _bookPrices[book]!;
      label = "Book: $book";
    } else {
      amount = _manualAmount;
      label = "$_selectedCategory: $_miscType";
    }

    if (amount <= 0) {
      _showSnackBar("Please enter a valid payment amount.", isError: true);
      return;
    }

    setState(() {
      _cartItems.add({
        "category": _selectedCategory,
        "item": label,
        "amount": amount,
        "qty": _quantity,
      });
      _amountInputController.clear();
      _manualAmount = 0;
    });
  }

  Future<void> _processTransaction() async {
    if (_selectedStudentId == null) return;
    final id = _selectedStudentId!;
    final total = _cartTotal;
    final items = List<Map<String, dynamic>>.from(_cartItems);

    setState(() {
      _studentDb[id]['balance'] -= total;
      for (var item in items) {
        _studentDb[id]['ledger'].add({
          "date": DateTime.now().toString().split(' ')[0],
          "desc": "Payment: ${item['item']}",
          "debit": 0.0,
          "credit": item['amount'] * item['qty'],
        });
      }
      if (_studentDb[id]['balance'] <= 0) {
        _studentDb[id]['balance'] = 0.0;
        _studentDb[id]['status'] = "Cleared";
        _studentDb[id]['cleared'] = true;
      }
      _cartItems.clear();
    });

    await _generatePdfReceipt(id, total, items);
  }

  // --- MODERNIZED E-DOC RECEIPT GENERATION ---
  Future<void> _generatePdfReceipt(
    String id,
    double total,
    List<Map<String, dynamic>> items,
  ) async {
    final pdf = pw.Document();
    final student = _studentDb[id];
    final String timestamp = DateTime.now().toString().split('.')[0];
    final String orNumber =
        "OR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final PdfColor brandViolet = PdfColor.fromInt(0xFF7C3AED);

    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo (2).png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. BRANDED HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 45,
                        height: 45,
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Container(
                        width: 40,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          color: brandViolet,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            "U",
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "UEMSSP Portal",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 24,
                            color: brandViolet,
                          ),
                        ),
                        pw.Text(
                          "UNIFIED EDUCATION MANAGEMENT SYSTEM AND STUDENT PORTAL",
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "OFFICIAL E-RECEIPT",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "No: $orNumber",
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      "Date: $timestamp",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: brandViolet, thickness: 1.5),
            pw.SizedBox(height: 25),

            // 2. STUDENT INFO GRID
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _pdfMetaItem("RECEIVED FROM", student['name']),
                      ),
                      pw.Expanded(
                        child: _pdfMetaItem("STUDENT ID", student['id']),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _pdfMetaItem(
                          "COURSE / PROGRAM",
                          student['course'],
                        ),
                      ),
                      pw.Expanded(
                        child: _pdfMetaItem("PAYMENT METHOD", _paymentMethod),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 35),

            // 3. ITEMIZATION TABLE
            pw.Text(
              "TRANSACTION DETAILS",
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: brandViolet,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ["Description", "Qty", "Amount"],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(color: brandViolet),
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: items
                  .map(
                    (i) => [
                      i['item'],
                      i['qty'].toString(),
                      "PHP ${(i['amount'] * i['qty']).toStringAsFixed(2)}",
                    ],
                  )
                  .toList(),
            ),

            pw.Spacer(),

            // 4. TOTALS
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "TOTAL PAID AMOUNT",
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    "PHP ${total.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: brandViolet,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 40),

            // 5. DIGITAL FOOTER
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "AUTHENTICATED BY UEMSSP FINANCE CORE",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "This is a system-generated document. No signature required.",
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      "Reference Code: ${id.split('-').last}-$orNumber",
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      "QR TICKET",
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Receipt_$orNumber.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar("Error generating document: $e", isError: true);
    }
  }

  // Fixed: This was returning pw.Widget but contained Flutter UI code
  pw.Widget _pdfMetaItem(String label, String val) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : pViolet;
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _buildTabBar(textColor),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLedgerTab(cardColor, textColor, subTextColor),
                  _buildPaymentTab(cardColor, textColor, subTextColor),
                  _buildPlaceholder("Grants Engine Active"),
                  _buildPlaceholder("Global Daily Logs"),
                ],
              ),
            ),
          ],
        );
      },
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
          color: aViolet,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withOpacity(0.5),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        tabs: const [
          Tab(text: "LEDGER"),
          Tab(text: "PAYMENT"),
          Tab(text: "GRANTS"),
          Tab(text: "LOGS"),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(Color cardColor, Color textColor, Color subTextColor) {
    if (_selectedStudentId != null)
      return _buildDetailLedger(cardColor, textColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText: "Search Student Name or ID...",
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              filled: true,
              fillColor: Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
    );
  }

  Widget _buildDetailLedger(Color cardColor, Color textColor) {
    final student = _studentDb[_selectedStudentId];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor, size: 18),
                onPressed: () => setState(() => _selectedStudentId = null),
              ),
              const SizedBox(width: 8),
              Text(
                student['name'],
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
          Table(
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
              const Spacer(),
              _badge(
                "₱${student['balance']}",
                student['balance'] > 0 ? Colors.redAccent : success,
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Expanded(
            child: ListView(
              children: (student['ledger'] as List)
                  .map((l) => _ledgerEntry(l, textColor))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(
                LucideIcons.creditCard,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                "PROCEED TO PAYMENT",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (_selectedStudentId == null) return _buildEmptyPrompt(textColor);
    final student = _studentDb[_selectedStudentId];
    return Column(
      children: [
        // Enhanced Student Header
        _buildEnhancedStudentHeader(student, cardColor, textColor, subTextColor),
        const SizedBox(height: 20),
        
        // Main Content Row
        Row(
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

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Payment Method Selection
          _buildEnhancedSectionHeader("Payment Method", LucideIcons.creditCard),
          const SizedBox(height: 8),
          _buildEnhancedDropdown(
            value: _paymentMethod,
            items: ["Cash", "GCash", "Online Banking", "Bank Transfer", "Credit Card"],
            onChanged: (val) => setState(() => _paymentMethod = val!),
            textColor: textColor,
            cardColor: cardColor,
          ),
          if (_paymentMethod != "Cash") ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.qrCode, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "QR Code will be generated for payment verification",
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

          const SizedBox(height: 24),
          
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
                if (_paymentMethod == "GCash" || 
                    _paymentMethod == "Online Banking" || 
                    _paymentMethod == "Bank Transfer") {
                  _showQRPaymentDialog(context, cardColor, textColor);
                } else {
                  _processCheckout();
                }
              } : null,
              icon: Icon(
                (_paymentMethod == "GCash" || 
                 _paymentMethod == "Online Banking" || 
                 _paymentMethod == "Bank Transfer") 
                    ? LucideIcons.qrCode 
                    : LucideIcons.creditCard,
              ),
              label: Text(
                (_paymentMethod == "GCash" || 
                 _paymentMethod == "Online Banking" || 
                 _paymentMethod == "Bank Transfer")
                    ? "GENERATE QR CODE" 
                    : "PROCESS PAYMENT"
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_paymentMethod == "GCash" || 
                                  _paymentMethod == "Online Banking" || 
                                  _paymentMethod == "Bank Transfer")
                    ? Colors.blueAccent 
                    : Colors.greenAccent,
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

  String _normalizeScholarshipName(String value) {
    return value.replaceAll(RegExp(r"\s*\(.*\)$"), "").trim();
  }

  bool _hasScholarship(Map<String, dynamic> student) {
    final scholarship = (student['scholarship'] ?? '').toString().trim();
    if (scholarship.isEmpty) return false;
    return _normalizeScholarshipName(scholarship).toLowerCase() != 'none';
  }

  Color _getScholarshipTypeColor(String type) {
    switch (type) {
      case "Merit":
        return const Color(0xFF8B5CF6);
      case "Athletics":
        return Colors.orangeAccent;
      case "Needs-Based":
        return Colors.greenAccent;
      case "Special":
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  List<MapEntry<String, dynamic>> _filteredScholarshipStudents() {
    final query = _scholarshipSearchController.text.toLowerCase();
    return _studentDb.entries.where((entry) {
      final student = entry.value as Map<String, dynamic>;
      final matchesQuery =
          student['name'].toLowerCase().contains(query) ||
          student['id'].toLowerCase().contains(query) ||
          student['course'].toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_scholarshipFilter == "All") return true;
      if (_scholarshipFilter == "None") return !_hasScholarship(student);

      final scholarshipName =
          _normalizeScholarshipName((student['scholarship'] ?? '').toString())
              .toLowerCase();
      final scholarship = _availableScholarships.firstWhere(
        (s) => s['name'].toString().toLowerCase() == scholarshipName,
        orElse: () => {},
      );
      return scholarship.isNotEmpty && scholarship['type'] == _scholarshipFilter;
    }).toList();
  }

  void _applyScholarshipToStudent(
    String studentId,
    Map<String, dynamic> scholarship,
  ) {
    final student = _studentDb[studentId];
    if (student == null) return;

    final discountRate = (scholarship['discount'] as num).toDouble();
    final currentBalance = (student['balance'] as num).toDouble();
    final discountAmount = currentBalance * discountRate;
    final newBalance = currentBalance - discountAmount;

    setState(() {
      student['scholarship'] = scholarship['name'];
      if (discountAmount > 0) {
        student['balance'] = newBalance > 0 ? newBalance : 0.0;
        student['ledger'].add({
          "date": DateTime.now().toString().split(' ')[0],
          "desc":
              "Scholarship Discount - ${scholarship['name']} (${(discountRate * 100).round()}%)",
          "debit": 0.0,
          "credit": discountAmount,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Scholarship applied to ${student['name']}.",
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeScholarshipFromStudent(String studentId) {
    final student = _studentDb[studentId];
    if (student == null) return;

    setState(() {
      student['scholarship'] = "None";
      student['ledger'].add({
        "date": DateTime.now().toString().split(' ')[0],
        "desc": "Scholarship Removed",
        "debit": 0.0,
        "credit": 0.0,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Scholarship removed from ${student['name']}.") ,
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  void _showAssignScholarshipDialog({String? studentId}) {
    String selectedStudentId =
        studentId ?? _studentDb.keys.first.toString();
    Map<String, dynamic> selectedScholarship = _availableScholarships.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final student = _studentDb[selectedStudentId];
          return AlertDialog(
            backgroundColor: widget.isDarkMode
                ? const Color(0xFF1E1B4B)
                : Colors.white,
            title: Text(
              "Assign Scholarship",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
              ),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Student",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudentId,
                    items: _studentDb.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text("${entry.value['name']} • ${entry.key}"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() => selectedStudentId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Select Scholarship",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedScholarship['name'] as String,
                    items: _availableScholarships
                        .map(
                          (scholarship) => DropdownMenuItem<String>(
                            value: scholarship['name'] as String,
                            child: Text(
                              "${scholarship['name']} • ${((scholarship['discount'] as num) * 100).round()}%",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() {
                        selectedScholarship = _availableScholarships
                            .firstWhere((s) => s['name'] == val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (student != null)
                    Text(
                      "Current Balance: ₱${(student['balance'] as num).toStringAsFixed(2)}",
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyScholarshipToStudent(
                    selectedStudentId,
                    selectedScholarship,
                  );
                },
                child: const Text("Assign"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateScholarshipDialog() {
    final nameController = TextEditingController();
    final discountController = TextEditingController();
    String selectedType = "Merit";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: widget.isDarkMode
                ? const Color(0xFF1E1B4B)
                : Colors.white,
            title: Text(
              "Create Scholarship",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : const Color(0xFF2E1065),
              ),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Scholarship Name",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Discount Percentage",
                      suffixText: "%",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(value: "Merit", child: Text("Merit")),
                      DropdownMenuItem(
                        value: "Athletics",
                        child: Text("Athletics"),
                      ),
                      DropdownMenuItem(
                        value: "Needs-Based",
                        child: Text("Needs-Based"),
                      ),
                      DropdownMenuItem(value: "Special", child: Text("Special")),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() => selectedType = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final discount =
                      double.tryParse(discountController.text.trim()) ?? 0;
                  if (name.isEmpty || discount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter a valid name and discount."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _availableScholarships.add({
                      "name": name,
                      "discount": discount / 100,
                      "type": selectedType,
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScholarshipsList(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final students = _filteredScholarshipStudents();
    final totalWithScholarship = _studentDb.values
        .where((s) => _hasScholarship(s as Map<String, dynamic>))
        .length;
    final averageDiscount = _availableScholarships.isEmpty
        ? 0
        : _availableScholarships
                .map((s) => (s['discount'] as num).toDouble())
                .reduce((a, b) => a + b) /
            _availableScholarships.length;

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
              Text(
                "Scholarship Management",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _showCreateScholarshipDialog,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text("Add Scholarship"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignScholarshipDialog(),
                    icon: const Icon(LucideIcons.userPlus),
                    label: const Text("Assign"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildScholarshipStatCard(
                "Active Scholarships",
                totalWithScholarship.toString(),
                LucideIcons.badgeCheck,
                Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildScholarshipStatCard(
                "Programs",
                _availableScholarships.length.toString(),
                LucideIcons.layers,
                Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              _buildScholarshipStatCard(
                "Avg Discount",
                "${(averageDiscount * 100).round()}%",
                LucideIcons.percent,
                Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scholarshipSearchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Search student name, ID, or course...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(LucideIcons.search, color: subTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _scholarshipFilter,
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                    DropdownMenuItem(value: "None", child: Text("No Scholarship")),
                    DropdownMenuItem(value: "Merit", child: Text("Merit")),
                    DropdownMenuItem(
                      value: "Athletics",
                      child: Text("Athletics"),
                    ),
                    DropdownMenuItem(
                      value: "Needs-Based",
                      child: Text("Needs-Based"),
                    ),
                    DropdownMenuItem(value: "Special", child: Text("Special")),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _scholarshipFilter = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (students.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "No students match your filters.",
                  style: TextStyle(color: subTextColor),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = students[index];
                final student = entry.value as Map<String, dynamic>;
                final hasScholarship = _hasScholarship(student);
                final scholarshipName = _normalizeScholarshipName(
                  (student['scholarship'] ?? "None").toString(),
                );
                final scholarship = _availableScholarships.firstWhere(
                  (s) => s['name'] == scholarshipName,
                  orElse: () => {},
                );
                final scholarshipType = scholarship['type']?.toString() ??
                    (hasScholarship ? "Assigned" : "None");
                final typeColor = _getScholarshipTypeColor(scholarshipType);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                        child: Icon(
                          LucideIcons.user,
                          color: const Color(0xFF8B5CF6),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${student['id']} • ${student['course']} • ${student['year']}",
                              style: TextStyle(color: subTextColor, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    scholarshipType,
                                    style: TextStyle(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasScholarship
                                      ? scholarshipName
                                      : "No scholarship assigned",
                                  style: TextStyle(color: subTextColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₱${(student['balance'] as num).toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  _selectedStudentId = entry.key;
                                  _showAssignScholarshipDialog(
                                    studentId: entry.key,
                                  );
                                },
                                child: Text(
                                  hasScholarship ? "Change" : "Assign",
                                ),
                              ),
                              if (hasScholarship)
                                TextButton(
                                  onPressed: () =>
                                      _removeScholarshipFromStudent(entry.key),
                                  child: const Text("Remove"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScholarshipStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            "Payment Config",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel("Category"),
          _simpleDropdown(
            ["Tuition", "Books", "Miscellaneous"],
            _selectedCategory,
            (v) => setState(() {
              _selectedCategory = v!;
              _manualAmount = 0;
              _amountInputController.clear();
            }),
          ),
          const SizedBox(height: 16),
          if (_selectedCategory == "Tuition") ...[
            _fieldLabel("Term"),
            _simpleDropdown(
              ["Midterm Block A", "Finals Block B"],
              _selectedTerm,
              (v) => setState(() => _selectedTerm = v!),
            ),
          ] else if (_selectedCategory == "Books") ...[
            _fieldLabel("Book"),
            _simpleDropdown(
              _bookPrices.keys.toList(),
              _selectedBook ?? _bookPrices.keys.first,
              (v) => setState(() => _selectedBook = v!),
            ),
          ] else ...[
            _fieldLabel("Type"),
            _simpleDropdown(
              ["Library Fine", "ID Replacement", "Graduation Fee"],
              _miscType,
              (v) => setState(() => _miscType = v!),
            ),
          ],
          const SizedBox(height: 16),
          _fieldLabel("Amount (₱)"),
          TextField(
            controller: _amountInputController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                LucideIcons.banknote,
                size: 16,
                color: Colors.blueGrey,
              ),
              hintText: "0.00",
              filled: true,
              fillColor: Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => _manualAmount = double.tryParse(v) ?? 0,
          ),
          const SizedBox(height: 24),
          if (_selectedStudentId == null)
            Center(
              child: Text(
                "Enter a valid Student ID to view history",
                style: TextStyle(color: subTextColor),
              ),
            )
          else
            _buildStudentLedgerView(cardColor, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            "Fee Summary",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 13,
            ),
          ),
          const Divider(height: 16, color: Colors.white10),
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Text(
                      "Empty",
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, i) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _cartItems[i]['item'],
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₱${(_cartItems[i]['amount']).toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 12,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                setState(() => _cartItems.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const Divider(color: Colors.white10),
          _row("TOTAL", "₱${_cartTotal.toStringAsFixed(2)}", success, 14),
          const SizedBox(height: 16),
          _fieldLabel("Method"),
          _simpleDropdown(
            ["Cash", "G-Cash", "Bank Transfer"],
            _paymentMethod,
            (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _cartItems.isEmpty ? null : _processTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 11, 76, 45),
                foregroundColor: pViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "FINALIZE E-RECEIPT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI ATOMS ---

  Widget _studentTile(Map<String, dynamic> s, Color t, Color st) {
    bool isSelected = _selectedStudentId == s['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? aViolet : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedStudentId = s['id']),
        dense: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.white.withOpacity(0.2)
              : aViolet.withOpacity(0.1),
          radius: 12,
          child: Icon(
            LucideIcons.user,
            color: isSelected ? Colors.white : aViolet,
            size: 10,
          ),
        ),
        title: Text(
          s['name'],
          style: TextStyle(
            color: isSelected ? Colors.white : t,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          "${s['id']} • ${s['course']}",
          style: TextStyle(
            color: isSelected ? Colors.white70 : st,
            fontSize: 9,
          ),
        ),
        trailing: _badge(
          "₱${s['balance']}",
          isSelected
              ? Colors.white.withOpacity(0.2)
              : (s['balance'] > 0 ? Colors.redAccent : success),
        ),
      ),
    );
  }

  Widget _ledgerEntry(Map<String, dynamic> l, Color t) {
    bool isCredit = l['credit'] > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            l['date'],
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l['desc'],
              style: TextStyle(
                color: t,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            isCredit ? "+₱${l['credit']}" : "-₱${l['debit']}",
            style: TextStyle(
              color: isCredit ? success : Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleDropdown(
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          dropdownColor: surfaceDark,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _row(String l, String v, Color c, double s) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
      Text(
        v,
        style: GoogleFonts.inter(
          color: c,
          fontWeight: FontWeight.w900,
          fontSize: s,
        ),
      ),
    ],
  );

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

    _generatePdfReceipt(id, amount, [
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
        title: Row(
          children: [
            Icon(LucideIcons.qrCode, color: const Color(0xFF8B5CF6), size: 24),
            const SizedBox(width: 12),
            Text(
              "Scan QR Code for Payment",
              style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: _buildQRCodePaymentSection(cardColor, textColor, textColor.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processCheckout();
            },
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text("Confirm Payment"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _processCheckout() {
    if (_selectedStudentId != null && _cartItems.isNotEmpty) {
      final student = _studentDb[_selectedStudentId!];
      if (student != null) {
        // Save cart items before clearing
        final itemsForReceipt = List<Map<String, dynamic>>.from(_cartItems);
        final totalAmount = _cartTotal;
        final paymentMethod = _paymentMethod;
        
        setState(() {
          student['balance'] -= totalAmount;
          student['ledger'].add({
            "date": DateTime.now().toString().split(' ')[0],
            "desc": "Payment - $paymentMethod",
            "debit": 0.0,
            "credit": totalAmount,
          });

          if (student['balance'] <= 0) {
            student['balance'] = 0.0;
            student['status'] = "Cleared";
            student['cleared'] = true;
          }

          _cartItems.clear();
        });

        // Generate receipt with saved cart items
        _generatePdfReceipt(_selectedStudentId!, totalAmount, itemsForReceipt);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Successful via $paymentMethod! Receipt Generated."),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
    ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildEmptyPrompt(Color t) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.user, size: 48, color: t.withOpacity(0.05)),
        const SizedBox(height: 12),
        Text(
          "Select a student from the Ledger tab.",
          style: TextStyle(color: t.withOpacity(0.3), fontSize: 12),
        ),
      ],
    ),
  );
  Widget _buildPlaceholder(String t) => Center(
    child: Text(t, style: const TextStyle(color: Colors.white24, fontSize: 12)),
  );

  // Added missing method
  Widget _buildStudentLedgerView(Color c, Color t, Color s) => const Text("Ledger View");

  void _showSnackBar(String m, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: isError ? Colors.redAccent : pViolet,
        ),
      );
}
