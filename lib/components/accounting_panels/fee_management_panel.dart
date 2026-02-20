import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

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
  double _manualAmount = 0.0;
  String _paymentMethod = "Cash";

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

  pw.Widget _pdfMetaItem(String label, String val) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _studentDb.entries
                  .where(
                    (e) =>
                        e.key.contains(_searchController.text) ||
                        e.value['name'].contains(
                          _searchController.text.toUpperCase(),
                        ),
                  )
                  .map((e) => _studentTile(e.value, textColor, subTextColor))
                  .toList(),
            ),
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
                  fontSize: 14,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildEntryPanel(cardColor, textColor, subTextColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildCheckoutPanel(cardColor, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildEntryPanel(
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
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _addItemToCart,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text(
                "ADD TO BATCH",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
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

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
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
  void _showSnackBar(String m, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: isError ? Colors.redAccent : pViolet,
        ),
      );
}
