import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../services/supabase_service.dart';
import '../../widgets/windows_qr_scanner.dart'; // Using fixed hardware scanner

class FeeManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const FeeManagementPanel({super.key, required this.isDarkMode});

  @override
  State<FeeManagementPanel> createState() => _FeeManagementPanelState();
}

class _FeeManagementPanelState extends State<FeeManagementPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;
  final TextEditingController _studentLookupController =
      TextEditingController();

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- SCANNER LOGIC (QR TICKET HANDLER) ---

  void _triggerScanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WindowsQRScanner(
        onScan: (qrData) {
          Navigator.pop(context);
          _lookupServiceTicket(qrData);
        },
        onManualEntry: () => _manualTicketEntry(),
      ),
    );
  }

  Future<void> _lookupServiceTicket(String hash) async {
    setState(() => _isProcessing = true);
    try {
      final client = SupabaseService().client;
      final result = await client
          .from('office_requests')
          .select('*, profiles(fn, ln, user_id_number, email)')
          .eq('qr_hash', hash.trim())
          .maybeSingle();

      setState(() => _isProcessing = false);

      if (result != null) {
        _showServicePaymentDialog(result);
      } else {
        _showMsg("Invalid Ticket: No record found.", Colors.redAccent);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMsg("Scan Error: Ledger unreachable.", Colors.redAccent);
    }
  }

  // --- PAYMENT CHANNEL HANDLERS ---

  void _processUnifiedPayment(
      Map<String, dynamic> entity, String category, double amount,
      {String type = "STUDENT"}) {
    showDialog(
      context: context,
      builder: (context) => _PaymentChannelSelector(
        onSelect: (channel) {
          Navigator.pop(context);
          if (channel == 'cash') {
            _handleCashFlow(entity, amount, category, type);
          } else {
            _handleOnlineFlow(entity, amount, category,
                channel == 'gcash' ? 'GCash' : 'Bank', type);
          }
        },
      ),
    );
  }

  void _handleCashFlow(
      Map<String, dynamic> entity, double total, String category, String type) {
    showDialog(
      context: context,
      builder: (context) => _CashPaymentModal(
        totalDue: total,
        onConfirm: (rec, change) => _finalizeLedgerSync(
          entity: entity,
          ref: "CASH-${Random().nextInt(9999)}",
          method: "Cash",
          amount: total,
          category: category,
          type: type,
        ),
      ),
    );
  }

  void _handleOnlineFlow(Map<String, dynamic> entity, double total,
      String category, String provider, String type) {
    final String name = entity['full_name'] ??
        "${entity['profiles']?['fn']} ${entity['profiles']?['ln']}";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OnlineGatewaySimulator(
        provider: provider,
        amount: total,
        studentName: name,
        onSuccess: (ref) => _finalizeLedgerSync(
          entity: entity,
          ref: ref,
          method: provider,
          amount: total,
          category: category,
          type: type,
        ),
      ),
    );
  }

  Future<void> _finalizeLedgerSync({
    required Map<String, dynamic> entity,
    required String ref,
    required String method,
    required double amount,
    required String category,
    required String type,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final client = SupabaseService().client;

      if (type == "APPLICANT") {
        await client
            .from('applicants')
            .update({'status': 'Approved'}).eq('id', entity['id']);
      } else if (type == "REQUEST") {
        await client
            .from('office_requests')
            .update({'payment_status': 'Paid'}).eq('id', entity['id']);
      } else if (type == "STUDENT") {
        final double currentBalance =
            double.tryParse(entity['account_balance']?.toString() ?? "0.0") ??
                0.0;
        await client
            .from('student_details')
            .update({'account_balance': currentBalance - amount}).eq(
                'profile_id', entity['id']);
      }

      await client.from('payments').insert({
        'student_id': type == "APPLICANT"
            ? entity['id']
            : (type == "REQUEST" ? entity['student_id'] : entity['id']),
        'amount_paid': amount,
        'category': category,
        'payment_method': method,
        'reference_no': ref,
        'status': 'Paid',
      });

      await _generateReceipt(entity, ref, method, amount, category);
      _showMsg("Ledger Synchronized. Transaction reflected.", success);
    } catch (e) {
      _showMsg("Sync Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 24),
          _buildTabBar(textColor),
          const SizedBox(height: 32),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIntakeQueue(cardColor, textColor),
                _buildStudentBilling(cardColor, textColor),
                _buildSettledLedger(cardColor, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Financial Collection Hub",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: t,
                    letterSpacing: -1)),
            const Text(
                "Audit multi-channel payments and Gmail-based QR tickets.",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ]),
          ElevatedButton.icon(
            onPressed: _triggerScanner,
            icon: const Icon(LucideIcons.qrCode),
            label: const Text("SCAN GMAIL TICKET"),
            style: ElevatedButton.styleFrom(
                backgroundColor: aViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          )
        ],
      );

  Widget _buildTabBar(Color t) => Container(
        height: 50,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
              color: aViolet, borderRadius: BorderRadius.circular(10)),
          labelColor: Colors.white,
          unselectedLabelColor: t.withOpacity(0.4),
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: "1. INTAKE"),
            Tab(text: "2. BILLING"),
            Tab(text: "3. HISTORY")
          ],
        ),
      );

  Widget _buildIntakeQueue(Color bg, Color text) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService()
          .client
          .from('applicants')
          .stream(primaryKey: ['id']).eq('status', 'For Payment'),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: aViolet));
        final list = snapshot.data!;
        if (list.isEmpty)
          return _emptyState(text, "No pending intake collections.");
        return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => _paymentCard(
                list[i], bg, text, "Enrollment Fee", 8500.0, "APPLICANT"));
      },
    );
  }

  Widget _buildStudentBilling(Color bg, Color text) {
    return Column(children: [
      TextField(
        controller: _studentLookupController,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          hintText: "Search Enrolled Student (ID/Name)...",
          prefixIcon: const Icon(LucideIcons.search, color: aViolet),
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() {}),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SupabaseService()
              .client
              .from('profiles')
              .stream(primaryKey: ['id']).eq('role', 'student'),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!
                .where((s) =>
                    s['user_id_number']
                        .toString()
                        .contains(_studentLookupController.text) ||
                    s['fn']
                        .toString()
                        .toUpperCase()
                        .contains(_studentLookupController.text.toUpperCase()))
                .toList();
            return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) =>
                    _studentBillingCard(list[i], bg, text));
          },
        ),
      ),
    ]);
  }

  Widget _buildSettledLedger(Color bg, Color text) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService()
          .client
          .from('payments')
          .stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => _historyCard(list[i], bg, text));
      },
    );
  }

  // --- UI CARDS ---

  Widget _paymentCard(Map<String, dynamic> data, Color bg, Color text,
      String category, double amount, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        const CircleAvatar(
            backgroundColor: aViolet,
            child: Icon(LucideIcons.userPlus, color: Colors.white, size: 16)),
        const SizedBox(width: 20),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['full_name'],
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 16)),
          Text("$category • PHP ${amount.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ])),
        ElevatedButton(
            onPressed: () =>
                _processUnifiedPayment(data, category, amount, type: type),
            style: ElevatedButton.styleFrom(
                backgroundColor: success, foregroundColor: Colors.black),
            child: const Text("COLLECT")),
      ]),
    );
  }

  Widget _studentBillingCard(Map<String, dynamic> s, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: aViolet.withOpacity(0.1),
            child: Text(s['fn'][0],
                style: const TextStyle(
                    color: aViolet, fontWeight: FontWeight.bold))),
        const SizedBox(width: 20),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${s['fn']} ${s['ln']}",
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 16)),
          Text("ID: ${s['user_id_number']}",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ])),
        _billingAction(LucideIcons.book, "BOOKS",
            () => _processUnifiedPayment(s, "Books", 1500.0)),
        _billingAction(LucideIcons.shirt, "UNIFORM",
            () => _processUnifiedPayment(s, "Uniform", 2200.0)),
        _billingAction(LucideIcons.graduationCap, "TUITION",
            () => _processUnifiedPayment(s, "Tuition", 5000.0)),
      ]),
    );
  }

  Widget _historyCard(Map<String, dynamic> p, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        const Icon(LucideIcons.checkCircle, color: success, size: 16),
        const SizedBox(width: 16),
        Expanded(
            child: Text(p['category'],
                style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        Text("₱${p['amount_paid']}",
            style: GoogleFonts.orbitron(
                color: text, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 16),
        _badge(p['payment_method'] ?? "N/A", aViolet),
      ]),
    );
  }

  void _showServicePaymentDialog(Map<String, dynamic> req) {
    final p = req['profiles'];
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: const Color(0xFF0F071D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              title: const Text("GMAIL TICKET VERIFIED",
                  style: TextStyle(
                      color: success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${p['fn']} ${p['ln']}",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    Text("ID: ${p['user_id_number']}",
                        style: const TextStyle(color: Colors.white38)),
                    const Divider(height: 40, color: Colors.white10),
                    _infoRow("Request:", req['request_type']),
                    _infoRow("Charge:", "₱${req['amount_due']}"),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("CANCEL")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      _processUnifiedPayment(
                          {...req, 'profiles': p},
                          req['request_type'],
                          double.parse(req['amount_due'].toString()),
                          type: "REQUEST");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                    child: const Text("PROCEED")),
              ],
            ));
  }

  void _manualTicketEntry() {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: surfaceDark,
              title: const Text("Manual Ticket Lookup",
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      hintText: "Enter REQ-XXXX hash from Gmail")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("CANCEL")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      _lookupServiceTicket(ctrl.text);
                    },
                    child: const Text("VERIFY"))
              ],
            ));
  }

  Future<void> _generateReceipt(Map<String, dynamic> entity, String ref,
      String method, double amount, String category) async {
    final pdf = pw.Document();
    final String name = entity['profiles'] != null
        ? "${entity['profiles']['fn']} ${entity['profiles']['ln']}"
        : (entity['full_name'] ?? "${entity['fn']} ${entity['ln']}");
    pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("SAN SEBASTIAN COLLEGE - RECOLETOS DE CAVITE",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text("OFFICIAL E-RECEIPT"),
                  pw.Divider(),
                  pw.Text("REF: $ref"),
                  pw.Text("METHOD: $method"),
                  pw.Text("RECEIVED FROM: $name"),
                  pw.Text("PARTICULARS: $category"),
                  pw.SizedBox(height: 10),
                  pw.Text("TOTAL PAID: PHP ${amount.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ])));
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/OR_$ref.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Widget _billingAction(IconData i, String l, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
          message: l,
          child: IconButton(
              onPressed: onTap, icon: Icon(i, color: aViolet, size: 20))));
  Widget _infoRow(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.white54)),
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))
      ]));
  Widget _emptyState(Color t, String m) =>
      Center(child: Text(m, style: TextStyle(color: t.withOpacity(0.2))));
  Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}

/// --- MODAL: CHANNEL SELECTOR ---
class _PaymentChannelSelector extends StatelessWidget {
  final Function(String) onSelect;
  const _PaymentChannelSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F071D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text("Select Payment Channel",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _option(LucideIcons.banknote, "Cash Payment", "Manual over-the-counter",
            () => onSelect('cash')),
        _option(LucideIcons.smartphone, "GCash / PayMongo",
            "Simulated mobile gateway", () => onSelect('gcash')),
        _option(LucideIcons.landmark, "Bank Transfer", "BDO, BPI, Metrobank",
            () => onSelect('bank')),
      ]),
    );
  }

  Widget _option(IconData i, String t, String s, VoidCallback onTap) =>
      ListTile(
          onTap: onTap,
          leading: Icon(i, color: const Color(0xFF8B5CF6)),
          title: Text(t,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(s,
              style: const TextStyle(color: Colors.white38, fontSize: 11)));
}

/// --- MODAL: CASH PAYMENT HANDLER ---
class _CashPaymentModal extends StatefulWidget {
  final double totalDue;
  final Function(double received, double change) onConfirm;
  const _CashPaymentModal({required this.totalDue, required this.onConfirm});
  @override
  State<_CashPaymentModal> createState() => _CashPaymentModalState();
}

class _CashPaymentModalState extends State<_CashPaymentModal> {
  final TextEditingController _amountCtrl = TextEditingController();
  double _change = 0.0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1B4B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("CASH TRANSACTION",
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const SizedBox(height: 24),
        Text("PHP ${widget.totalDue.toStringAsFixed(2)}",
            style: GoogleFonts.orbitron(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        TextField(
            controller: _amountCtrl,
            autofocus: true,
            onChanged: (v) {
              final rec = double.tryParse(v) ?? 0.0;
              setState(() => _change =
                  rec >= widget.totalDue ? rec - widget.totalDue : 0.0);
            },
            style: const TextStyle(color: Colors.white, fontSize: 24),
            decoration: const InputDecoration(
                hintText: "Received Amount",
                filled: true,
                fillColor: Colors.black26,
                border: InputBorder.none)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("CHANGE:", style: TextStyle(color: Colors.blueGrey)),
          Text("₱${_change.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Color(0xFF69F0AE), fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 32),
        SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConfirm(double.parse(_amountCtrl.text), _change);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6)),
                child: const Text("COMPLETE"))),
      ]),
    );
  }
}

/// --- MODAL: GATEWAY SIMULATOR ---
class _OnlineGatewaySimulator extends StatefulWidget {
  final String provider;
  final double amount;
  final String studentName;
  final Function(String ref) onSuccess;
  const _OnlineGatewaySimulator(
      {required this.provider,
      required this.amount,
      required this.studentName,
      required this.onSuccess});
  @override
  State<_OnlineGatewaySimulator> createState() =>
      _OnlineGatewaySimulatorState();
}

class _OnlineGatewaySimulatorState extends State<_OnlineGatewaySimulator> {
  int _step = 0;
  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
            width: 400,
            height: 600,
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Row(children: [
                Icon(
                    widget.provider == 'GCash'
                        ? LucideIcons.smartphone
                        : LucideIcons.landmark,
                    color: Colors.blue),
                const SizedBox(width: 12),
                Text(widget.provider.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                const Spacer(),
                const Text("SECURE",
                    style: TextStyle(fontSize: 8, color: Colors.grey))
              ]),
              const Divider(height: 40),
              Expanded(
                  child: _step == 0
                      ? _stepAuth()
                      : (_step == 1 ? _stepReview() : _stepSuccess())),
            ])));
  }

  Widget _stepAuth() =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Authenticate",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const Text("OTP sent to student Gmail",
            style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 40),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Text("*", style: TextStyle(color: Colors.black)),
          Text("*", style: TextStyle(color: Colors.black)),
          Text("*", style: TextStyle(color: Colors.black)),
          Text("*", style: TextStyle(color: Colors.black))
        ]),
        const Spacer(),
        ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 55)),
            child: const Text("VERIFY OTP"))
      ]);
  Widget _stepReview() => Column(children: [
        Text("PHP ${widget.amount}",
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: Colors.black)),
        const Divider(height: 60),
        _line("Student", widget.studentName),
        const Spacer(),
        ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 55)),
            child: const Text("CONFIRM"))
      ]);
  Widget _stepSuccess() =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.checkCircle, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        const Text("Payment Success",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSuccess("PM-${DateTime.now().millisecondsSinceEpoch}");
            },
            child: const Text("CLOSE"))
      ]);
  Widget _line(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(color: Colors.grey)),
        Text(v,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black))
      ]));
}
