import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/supabase_service.dart';

class OfficeRequestForm extends StatefulWidget {
  final bool isDarkMode;
  final String studentId;
  final Map<String, dynamic> studentData;
  final VoidCallback? onRequestSubmitted;

  const OfficeRequestForm({
    super.key,
    required this.isDarkMode,
    required this.studentId,
    required this.studentData,
    this.onRequestSubmitted,
  });

  @override
  State<OfficeRequestForm> createState() => _OfficeRequestFormState();
}

class _OfficeRequestFormState extends State<OfficeRequestForm> {
  final TextEditingController _requestController = TextEditingController();
  Map<String, dynamic>? _selectedDocument;
  List<Map<String, dynamic>> _availableDocuments = [];
  bool _isSubmitting = false;
  String? _generatedRequestId;
  bool _isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final data = await SupabaseService()
          .client
          .from('requestable_documents')
          .select()
          .eq('is_active', true);
      if (mounted) {
        setState(() {
          _availableDocuments = List<Map<String, dynamic>>.from(data);
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

// Inside _submitRequest logic:
  void _submitRequest() async {
    if (_selectedDocument == null) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. GENERATE THE HASH (The 'Data' stored in the QR)
      // Using Student ID + Timestamp ensures uniqueness for the scanner
      final String studentIdNum = widget.studentData['user_id_number'];
      final String qrHash =
          'REQ-$studentIdNum-${DateTime.now().millisecondsSinceEpoch}';

      // 2. SAVE TO CLOUD LEDGER (Supabase)
      await SupabaseService().client.from('office_requests').insert({
        'student_id': widget.studentId,
        'request_type': _selectedDocument!['name'],
        'qr_hash': qrHash,
        'amount_due': _selectedDocument!['price'],
        'payment_status': 'Unpaid',
        'request_status': 'Submitted',
        'remarks': _requestController.text,
      });

      // 3. TRIGGER GMAIL DISPATCH (Simulated using Database Email)
      // Pulling the real email e.g., 'angel.lustre2005@gmail.com'
      final String personalEmail =
          widget.studentData['email'] ?? "your registered email";
      await _showGmailSimulation(
          personalEmail, qrHash, _selectedDocument!['name']);

      if (mounted) {
        setState(() => _generatedRequestId = qrHash);
        _requestController.clear();
      }
    } catch (e) {
      // Handle error...
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showGmailSimulation(String email, String hash, String docType) {
    // Use a Public QR API to make the "Email" look professional
    final String qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$hash";

    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mail, color: Color(0xFF8B5CF6), size: 48),
            const SizedBox(height: 20),
            const Text("GMAIL TICKET DISPATCHED",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            Text("An official stub for your $docType request was sent to:",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(email,
                style: const TextStyle(
                    color: Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Image.network(qrUrl, width: 120, height: 120),
            ),
            const SizedBox(height: 12),
            const Text("Present this QR at the Registrar window for releasing.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    if (_generatedRequestId != null) {
      return _buildSuccessQR(cardColor, textColor);
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Initialize Service Request",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            const SizedBox(height: 24),
            if (_isLoadingDocs)
              const LinearProgressIndicator(color: Color(0xFF8B5CF6))
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedDocument,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Target Document",
                  labelStyle:
                      const TextStyle(color: Colors.blueGrey, fontSize: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(LucideIcons.fileText,
                      size: 20, color: Color(0xFF8B5CF6)),
                ),
                items: _availableDocuments
                    .map((doc) => DropdownMenuItem(
                        value: doc,
                        child: Text("${doc['name']} (₱${doc['price']})")))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDocument = val),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _requestController,
              maxLines: 3,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Reason for request...",
                hintStyle:
                    const TextStyle(color: Colors.blueGrey, fontSize: 13),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)))
                    : const Text("PROCEED TO GMAIL DISPATCH",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessQR(Color cardColor, Color textColor) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: const Color(0xFF69F0AE).withOpacity(0.5))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle,
                color: Color(0xFF69F0AE), size: 48),
            const SizedBox(height: 16),
            Text("Ticket Dispatched",
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            const Text("Digital ticket copy sent to your Gmail inbox.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: QrImageView(
                  data: _generatedRequestId!,
                  version: QrVersions.auto,
                  size: 180.0),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
                onPressed: () => setState(() => _generatedRequestId = null),
                icon: const Icon(LucideIcons.plusCircle),
                label: const Text("NEW REQUEST")),
          ],
        ),
      ),
    );
  }
}
