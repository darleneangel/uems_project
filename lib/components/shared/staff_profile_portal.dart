import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';

class StaffProfilePortal extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const StaffProfilePortal({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<StaffProfilePortal> createState() => _StaffProfilePortalState();
}

class _StaffProfilePortalState extends State<StaffProfilePortal> {
  final SupabaseService _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  Map<String, dynamic>? _fullDetails;

  // Form Controllers
  final TextEditingController _reasonController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _leaveType = 'Sick';

  // Visual Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchCompleteProfile();
  }

  Future<void> _fetchCompleteProfile() async {
    setState(() => _isLoading = true);
    try {
      // Fetch profile joined with employee_details
      final res = await _service.client
          .from('profiles')
          .select('*, employee_details(*)')
          .eq('id', widget.userData['id'])
          .single();

      if (mounted) {
        setState(() {
          _fullDetails = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// --- PDF GENERATION ENGINE ---
  /// Creates a formal letter and allows the user to SAVE/DOWNLOAD it
  Future<void> _generateSickLeavePDF() async {
    if (_reasonController.text.isEmpty || _selectedDateRange == null) {
      _showToast("Enter dates and a reason to generate the letter.",
          Colors.orangeAccent);
      return;
    }

    final pdf = pw.Document();
    final bool isHR = widget.userData['role']?.toString().toLowerCase() == 'hr';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(48),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Institutional Header
                pw.Text('BRIGHT FUTURE ACADEMY',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900)),
                pw.Text('Institutional Human Resources Office',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 32),

                // Date
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.SizedBox(height: 32),

                // Recipient - Conditional logic for HR department
                pw.Text(
                    isHR
                        ? 'TO: Office of the School Administrator'
                        : 'TO: Human Resources Management Office',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('Bright Future Academy',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 24),

                // Subject
                pw.Text('SUBJECT: FORMAL APPLICATION FOR SICK LEAVE',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 32),

                // Salutation
                pw.Text('To Whom It May Concern,',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 16),

                // Body text
                pw.Text(
                    'I am writing to formally request a sick leave of absence from my duties as '
                    '${_fullDetails?['employee_details']?['position_title'] ?? "Staff Member"} '
                    'at Bright Future Academy. I will be unable to report to work for a period of '
                    '${_selectedDateRange!.duration.inDays + 1} day(s), effective from '
                    '${DateFormat('MMMM dd').format(_selectedDateRange!.start)} to '
                    '${DateFormat('MMMM dd, yyyy').format(_selectedDateRange!.end)}.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.normal,
                      height: 1.5,
                      letterSpacing: 0.5,
                    )),

                pw.SizedBox(height: 16),
                pw.Text('REASON FOR ABSENCE:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(_reasonController.text,
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.4)),
                pw.SizedBox(height: 24),
                pw.Text(
                  'I have made the necessary arrangements to ensure that my pending tasks are handled or delegated appropriately during this period. I will keep the office updated should there be any changes to my recovery timeline.',
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 64),

                // Signature block
                pw.Text('Respectfully yours,',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 48),
                pw.Container(
                    // Fixed: pw.Container does not have a 'border' parameter directly.
                    width:
                        180, // It expects a 'decoration' which takes a pw.BoxDecoration.
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 1)),
                    )),
                pw.Text('${widget.userData['fn']} ${widget.userData['ln']}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text(
                    'Employee ID: ${widget.userData['user_id_number'] ?? "N/A"}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
                if (isHR)
                  pw.Text('Role: HR Department Personnel',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.red900)),
              ],
            ),
          );
        },
      ),
    );

    try {
      final bytes = await pdf.save();
      await Printing.sharePdf(
          bytes: bytes,
          filename: 'Sick_Leave_Letter_${widget.userData['ln']}.pdf');
    } catch (e) {
      _showToast(
          "Could not save PDF. Check app permissions.", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildInfoSection(
                        "Institutional Identity",
                        [
                          _infoTile(
                              "Full Name",
                              "${widget.userData['fn']} ${widget.userData['ln']}",
                              LucideIcons.user),
                          _infoTile("Email Address", widget.userData['email'],
                              LucideIcons.mail),
                          _infoTile(
                              "Employee ID",
                              widget.userData['user_id_number'] ?? 'N/A',
                              LucideIcons.fingerprint),
                          _infoTile(
                              "Position",
                              _fullDetails?['employee_details']
                                      ?['position_title'] ??
                                  'Not Set',
                              LucideIcons.briefcase),
                        ],
                        cardColor,
                        textColor),
                    const SizedBox(height: 24),
                    _buildInfoSection(
                        "Government & Statutory IDs",
                        [
                          _infoTile(
                              "TIN Number",
                              _fullDetails?['employee_details']
                                      ?['tin_number'] ??
                                  '---',
                              LucideIcons.fileText),
                          _infoTile(
                              "SSS Number",
                              _fullDetails?['employee_details']
                                      ?['sss_number'] ??
                                  '---',
                              LucideIcons.shield),
                          _infoTile(
                              "PhilHealth ID",
                              _fullDetails?['employee_details']
                                      ?['philhealth_id'] ??
                                  '---',
                              LucideIcons.heart),
                          _infoTile(
                              "Pag-IBIG ID",
                              _fullDetails?['employee_details']
                                      ?['pagibig_id'] ??
                                  '---',
                              LucideIcons.home),
                        ],
                        cardColor,
                        textColor),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: _buildLeaveApplicationForm(cardColor, textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Employee Profile Portal",
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5)),
        const Text(
            "Manage your digital credentials and administrative requests.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
      ],
    );
  }

  Widget _buildInfoSection(
      String title, List<Widget> children, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: aViolet,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: aViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: aViolet, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: GoogleFonts.inter(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveApplicationForm(Color cardColor, Color textColor) {
    final bool isHR = widget.userData['role']?.toString().toLowerCase() == 'hr';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? LinearGradient(
                  colors: widget.isDarkMode
                      ? [surfaceDark, const Color(0xFF1E1033)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isHR
                  ? Colors.orangeAccent.withOpacity(0.5)
                  : aViolet.withOpacity(0.2),
              width: 2),
          boxShadow: [
            BoxShadow(
                color: aViolet.withOpacity(0.05),
                blurRadius: 40,
                offset: const Offset(0, 20))
          ]),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isHR ? LucideIcons.shieldAlert : LucideIcons.calendarPlus,
                    color: isHR ? Colors.orangeAccent : aViolet, size: 24),
                const SizedBox(width: 12),
                Text("File Leave Request",
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
              ],
            ),
            if (isHR)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    "NOTICE: HR requests are routed to Administration for approval.",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 32),
            _buildLabel("Type of Leave"),
            DropdownButtonFormField<String>(
              value: _leaveType,
              dropdownColor: surfaceDark,
              style: TextStyle(color: textColor),
              decoration: _inputStyle(),
              items: ['Sick', 'Vacation', 'Emergency', 'Maternity', 'Paternity']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _leaveType = v!),
            ),
            const SizedBox(height: 20),
            _buildLabel("Select Period"),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _containerStyle(),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: aViolet),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDateRange == null
                          ? "Choose Dates..."
                          : "${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}",
                      style: TextStyle(
                          color: _selectedDateRange == null
                              ? Colors.blueGrey
                              : textColor,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel("Reason / Justification"),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              style: TextStyle(color: textColor),
              decoration: _inputStyle(hint: "Provide context for review..."),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Reason required" : null,
            ),
            const SizedBox(height: 32),
            if (_leaveType == 'Sick')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _generateSickLeavePDF,
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: const Text("GENERATE & SAVE PDF",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: aViolet,
                      side: const BorderSide(color: aViolet),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitLeaveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHR ? Colors.orangeAccent : aViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(isHR ? "SUBMIT TO ADMIN" : "SUBMIT TO HR OFFICE",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: widget.isDarkMode
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: aViolet,
                    onPrimary: Colors.white,
                    surface: surfaceDark,
                    onSurface: Colors.white),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: aViolet),
              ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate() || _selectedDateRange == null) {
      _showToast(
          "Please complete the form and select dates.", Colors.orangeAccent);
      return;
    }

    final bool isHR = widget.userData['role']?.toString().toLowerCase() == 'hr';

    try {
      await _service.client.from('leave_requests').insert({
        'employee_id': widget.userData['id'],
        'leave_type': _leaveType,
        'start_date': _selectedDateRange!.start.toIso8601String(),
        'end_date': _selectedDateRange!.end.toIso8601String(),
        'reason': _reasonController.text.trim(),
        'status': 'Pending',
        // Functional Logic: Tagging this as an HR request so it is ignored by standard HR modules
        'is_hr_request': isHR,
      });

      _showToast(
          isHR
              ? "Request submitted to Administration."
              : "Leave request submitted to HR.",
          success);
      _reasonController.clear();
      setState(() => _selectedDateRange = null);
    } catch (e) {
      _showToast("Submission Error: $e", Colors.redAccent);
    }
  }

  Widget _buildLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  InputDecoration _inputStyle({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: aViolet.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: aViolet.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: aViolet)),
      );

  BoxDecoration _containerStyle() => BoxDecoration(
        color:
            widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aViolet.withOpacity(0.1)),
      );

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
