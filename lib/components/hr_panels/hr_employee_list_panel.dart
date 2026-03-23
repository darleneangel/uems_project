import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import '../../services/supabase_service.dart';

/// CUSTOM CONVERTER CLASS
/// This solves the "ListToCsvConverter isn't a class" error by providing
/// a local implementation of the CSV formatting logic.
class ListToCsvConverter {
  const ListToCsvConverter();

  String convert(List<List<dynamic>> rows) {
    if (rows.isEmpty) return "";

    return rows.map((row) {
      return row.map((item) {
        String value = item?.toString() ?? "";
        // If value contains a comma, newline, or double quotes, wrap it in quotes
        if (value.contains(',') ||
            value.contains('\n') ||
            value.contains('"')) {
          value = '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(',');
    }).join('\n');
  }
}

class HrEmployeeListPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HrEmployeeListPanel({
    super.key,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<HrEmployeeListPanel> createState() => _HrEmployeeListPanelState();
}

class _HrEmployeeListPanelState extends State<HrEmployeeListPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _masterList = [];
  bool _isLoading = true;

  // Filter States
  String _roleFilter = 'All Roles';
  String _contractFilter = 'All Contracts';
  String _statusFilter = 'Active';

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  /// Synchronizes with Supabase to fetch all staff and faculty profiles
  Future<void> _fetchMasterData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Direct connection to 'profiles' table joined with 'employee_details'
      final res = await _service.client
          .from('profiles')
          .select('*, employee_details(*)')
          .neq('role', 'student') // Ensures only employees are reflected
          .order('ln', ascending: true);

      if (mounted) {
        setState(() {
          _masterList = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Master Database Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SMART SEARCH & FILTER LOGIC ---
  List<Map<String, dynamic>> get _filteredData {
    return _masterList.where((emp) {
      final details = emp['employee_details'];
      final fullName = "${emp['fn']} ${emp['ln']}".toLowerCase();
      final idNum = (emp['user_id_number'] ?? '').toString().toLowerCase();
      final searchTerm = _searchController.text.toLowerCase();

      final matchesSearch =
          fullName.contains(searchTerm) || idNum.contains(searchTerm);
      final matchesRole = _roleFilter == 'All Roles' ||
          emp['role'] == _roleFilter.toLowerCase();
      final matchesContract = _contractFilter == 'All Contracts' ||
          details?['contract_type'] == _contractFilter;

      // Standardizes status check against the database column
      final bool isArchived = details?['employment_status'] == 'Archived';
      final matchesStatus =
          _statusFilter == 'Archived' ? isArchived : !isArchived;

      return matchesSearch && matchesRole && matchesContract && matchesStatus;
    }).toList();
  }

  // --- CSV EXPORT ---
  Future<void> _exportCSV() async {
    final List<Map<String, dynamic>> data = _filteredData;
    if (data.isEmpty) {
      _showToast("No records available to export.", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<List<dynamic>> csvRows = [];

      // Official Institutional Header Row
      csvRows.add([
        'Employee ID',
        'Name',
        'Role',
        'Position',
        'Contract',
        'Salary',
        'Status'
      ]);

      for (var e in data) {
        final d = e['employee_details'];
        csvRows.add([
          e['user_id_number'] ?? 'N/A',
          "${e['ln']}, ${e['fn']}",
          e['role'].toString().toUpperCase(),
          d?['position_title'] ?? 'N/A',
          d?['contract_type'] ?? 'N/A',
          d?['base_salary'] ?? 0.0,
          d?['employment_status'] ?? 'Active',
        ]);
      }

      const converter = ListToCsvConverter();
      final String csvString = converter.convert(csvRows);

      final Directory directory = await getApplicationDocumentsDirectory();
      final String path =
          "${directory.path}/Workforce_Master_${DateTime.now().millisecondsSinceEpoch}.csv";
      final File file = File(path);

      await file.writeAsString(csvString);
      await OpenFile.open(path);

      _showToast("CSV Ledger Exported successfully.", success);
    } catch (e) {
      _showToast("Export Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PDF EXPORT ---
  Future<void> _exportPDF() async {
    final data = _filteredData;
    if (data.isEmpty) {
      _showToast("No data to generate PDF.", Colors.orangeAccent);
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("BRIGHT FUTURE ACADEMY - WORKFORCE LEDGER",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(
                    "Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'NAME', 'ROLE', 'POSITION', 'CONTRACT', 'SALARY'],
            data: data
                .map((e) => [
                      e['user_id_number'] ?? '',
                      "${e['ln']}, ${e['fn']}",
                      e['role'].toString().toUpperCase(),
                      e['employee_details']?['position_title'] ?? '',
                      e['employee_details']?['contract_type'] ?? '',
                      "PHP ${e['employee_details']?['base_salary'] ?? 0.0}"
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.start, // Ensure alignment from the top
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 40), // Increased spacing for modern feel
          _buildFilterBar(cardColor, textColor),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: aViolet))
                : _buildMasterTable(cardColor, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Workforce Master Ledger",
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            const Text("Administrative oversight and institutional reporting.",
                style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize:
                        14)), // Keep as is, or consider textColor.withOpacity(0.7)
          ],
          // Update: Changed to use textColor for better contrast
        ),
        Row(
          children: [
            _actionBtn("EXCEL / CSV", LucideIcons.fileSpreadsheet, _exportCSV),
            const SizedBox(width: 12),
            _actionBtn("GENERATE PDF", LucideIcons.fileText, _exportPDF),
          ],
        )
      ],
    );
  }

  Widget _buildFilterBar(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
            16), // Slightly smaller radius for a cleaner look
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05) // Softer border in dark mode
                : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchField(textColor)),
          const SizedBox(width: 16),
          _buildDropdown(
              "Role",
              _roleFilter,
              [
                'All Roles',
                'Professor',
                'Faculty',
                'Registrar',
                'Accounting',
                'HR',
                'Admin',
                'Admission',
                'PChair'
              ],
              (v) => setState(() => _roleFilter = v!)),
          const SizedBox(width: 12),
          _buildDropdown(
              "Contract",
              _contractFilter,
              ['All Contracts', 'Regular', 'Probational', 'Part-time'],
              (v) => setState(() => _contractFilter = v!)),
          const SizedBox(width: 12),
          _buildDropdown("Status", _statusFilter, ['Active', 'Archived'],
              (v) => setState(() => _statusFilter = v!)),
        ],
      ),
    );
  }

  Widget _buildMasterTable(Color cardColor, Color textColor) {
    final list = _filteredData;
    if (list.isEmpty) return _emptyState();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _tableHeader(
              ['ID', 'FULL NAME', 'POSITION', 'ROLE', 'SALARY', 'CONTRACT']),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, i) {
                final emp = list[i];
                final d = emp['employee_details'];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(emp['user_id_number'] ?? '---',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: aViolet))),
                      Expanded(
                          flex: 2,
                          child: Text("${emp['fn']} ${emp['ln']}",
                              style: TextStyle(
                                  color:
                                      textColor, // Use theme-aware text color
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text(d?['position_title'] ?? 'N/A',
                              style: TextStyle(
                                  color: textColor.withOpacity(
                                      0.7), // Use theme-aware text color with opacity
                                  fontSize: 12))),
                      Expanded(child: _roleChip(emp['role'])),
                      Expanded(
                          child: Text("₱${d?['base_salary'] ?? 0}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(
                                      255, 255, 255, 255)))),
                      Expanded(
                          child: Text(d?['contract_type'] ?? 'N/A',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withOpacity(
                                      0.7)))), // Use theme-aware text color with opacity
                    ],
                  ),
                );
              },
            ),
          ),
          // Add a subtle footer or pagination if needed, otherwise keep it clean
        ],
      ),
    );
  }

  Widget _buildSearchField(Color textColor) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: "Search Name or ID...",
        hintStyle: TextStyle(
            color:
                textColor.withOpacity(0.5)), // Hint text with better contrast
        prefixIcon: const Icon(LucideIcons.search, size: 18, color: aViolet),
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            // Ensure consistent border style
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(
            // Focused border with accent color
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: aViolet, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 16), // Adjusted padding
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _tableHeader(List<String> titles) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16))), // Match card radius
        child: Row(
            children: titles
                .map((t) => Expanded(
                    flex: t == 'FULL NAME' ? 2 : 1,
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 10, // Keep font size
                            fontWeight: FontWeight.w900,
                            color: Colors
                                .blueGrey, // Keep blueGrey for header, it's a common pattern
                            letterSpacing: 1.2))))
                .toList()),
      );

  Widget _buildDropdown(String label, String value, List<String> items,
          ValueChanged<String?> onChanged) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 8.0,
                  bottom: 4.0), // Add some left padding to align with dropdown
              child: Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey)), // Keep blueGrey for labels
            ),
            DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: value,
                items: items
                    .map((i) => DropdownMenuItem(
                        value: i,
                        child: Text(i, style: const TextStyle(fontSize: 12))))
                    .toList(),
                style: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.white
                        : Colors.black87), // Ensure text color is theme-aware
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: aViolet, width: 1.5),
                  ),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.02),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Adjusted padding
                ),
                dropdownColor: widget.isDarkMode
                    ? const Color(0xFF1E1B4B)
                    : Colors.white, // Keep dropdown color
              ),
            ),
          ],
        ),
      );

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          // Slightly refined chip design
          color: aViolet.withOpacity(0.15), // Slightly more opaque
          borderRadius: BorderRadius.circular(8)), // Slightly more rounded
      child: Text(role.toUpperCase(), // Keep text style
          style: const TextStyle(
              color: aViolet, fontSize: 9, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
            // Keep button style
            backgroundColor: aViolet,
            iconColor: Colors.white, // Keep accent color
            shape: RoundedRectangleBorder(
                // Keep rounded corners
                borderRadius:
                    BorderRadius.circular(12))), // Keep rounded corners
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.users, size: 48, color: Colors.blueGrey),
        const SizedBox(height: 16),
        Text("No personnel found matching filters.",
            style: TextStyle(
                color: Colors.blueGrey
                    .withOpacity(0.5))) // Keep blueGrey with opacity
      ]));

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating));
  }
}
