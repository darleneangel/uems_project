import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class SubjectManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const SubjectManagementPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<SubjectManagementPanel> createState() => _SubjectManagementPanelState();
}

class _SubjectManagementPanelState extends State<SubjectManagementPanel> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _chairDeptId;
  String? _chairDeptName;
  List<Map<String, dynamic>> _subjects = [];

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);
  static const Color danger = Color(0xFFFF5252);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  void initState() {
    super.initState();
    _initSubjectOversight();
  }

  /// 🛰️ INITIALIZE: Resolve Chair's Department and fetch subject catalog
  Future<void> _initSubjectOversight() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final String? userIdNum = widget.userData['user_id_number']?.toString();
      if (userIdNum == null) return;

      final chairContext = await _service.getChairContext(userIdNum);
      if (chairContext != null) {
        _chairDeptId = chairContext['department_id']?.toString();
        _chairDeptName = chairContext['departments']?['name'];
        await _fetchDepartmentalSubjects();
      }
    } catch (e) {
      debugPrint("Subject Management Init Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDepartmentalSubjects() async {
    if (_chairDeptId == null) return;
    try {
      final res = await _service.client
          .from('subjects')
          .select('*')
          .eq('department_id', _chairDeptId!)
          .order('code', ascending: true);

      if (mounted) {
        setState(() => _subjects = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint("Fetch Subjects Error: $e");
    }
  }

  /// 🛰️ DATABASE ACTION: Create or Update Subject
  Future<void> _upsertSubject(Map<String, dynamic> data, {String? id}) async {
    setState(() => _isActionLoading = true);
    try {
      if (id == null) {
        // Create new
        await _service.client.from('subjects').insert({
          ...data,
          'department_id': _chairDeptId,
        });
        _showToast("Subject successfully added to catalog.", success);
      } else {
        // Update existing
        await _service.client.from('subjects').update(data).eq('id', id);
        _showToast("Subject details synchronized.", success);
      }
      await _fetchDepartmentalSubjects();
    } catch (e) {
      _showToast("Ledger Error: Check for duplicate codes.", danger);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// 🛰️ DATABASE ACTION: Delete Subject
  Future<void> _deleteSubject(String id, String code) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Subject",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            "Are you sure you want to remove $code from the institutional catalog? This action cannot be undone.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            child: const Text("DELETE PERMANENTLY"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.client.from('subjects').delete().eq('id', id);
        _showToast("Subject removed from ledger.", Colors.blueGrey);
        await _fetchDepartmentalSubjects();
      } catch (e) {
        _showToast("Constraint Error: Subject may be linked to student loads.",
            danger);
      }
    }
  }

  /// 📐 UI: Subject Composer Modal
  void _showSubjectForm([Map<String, dynamic>? existing]) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: existing?['code']);
    final nameCtrl = TextEditingController(text: existing?['name']);
    final unitsCtrl =
        TextEditingController(text: existing?['units']?.toString() ?? "3");
    final hoursCtrl = TextEditingController(
        text: existing?['hours_per_week']?.toString() ?? "3.0");
    bool isProfessional = existing?['is_professional_course'] ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
              existing == null ? "Add New Subject" : "Modify Subject Details",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalInput(codeCtrl, "Subject Code (e.g. COMP 101)",
                      required: true),
                  const SizedBox(height: 16),
                  _modalInput(nameCtrl, "Subject Description/Title",
                      required: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _modalInput(unitsCtrl, "Academic Units",
                              isNumeric: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _modalInput(hoursCtrl, "Hours Per Week",
                              isNumeric: true)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text("Professional Course",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        "Classify as specialized departmental major.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                    value: isProfessional,
                    activeThumbColor: aViolet,
                    onChanged: (v) => setModalState(() => isProfessional = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  _upsertSubject({
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'name': nameCtrl.text.trim(),
                    'units': int.tryParse(unitsCtrl.text) ?? 3,
                    'hours_per_week': double.tryParse(hoursCtrl.text) ?? 3.0,
                    'is_professional_course': isProfessional,
                  }, id: existing?['id']);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child:
                  Text(existing == null ? "SAVE TO CATALOG" : "UPDATE RECORD"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: aViolet));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textColor),
          const SizedBox(height: 32),
          _buildActionRibbon(cardColor, textColor),
          const SizedBox(height: 24),
          _buildSubjectGrid(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Departmental Catalog Management",
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: t,
                  letterSpacing: -1)),
          Text(
              "Department: ${_chairDeptName ?? 'N/A'} | Manage curriculum subjects and credit standards.",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
        ],
      );

  Widget _buildActionRibbon(Color bg, Color text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(LucideIcons.search, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                style: TextStyle(color: text),
                decoration: const InputDecoration(
                    hintText: "Search Catalog by Code or Title...",
                    border: InputBorder.none),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showSubjectForm(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text("NEW SUBJECT"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: aViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
            ),
          ],
        ),
      );

  Widget _buildSubjectGrid(Color bg, Color text) {
    final query = _searchController.text.toLowerCase();
    final filtered = _subjects
        .where((s) =>
            s['code'].toString().toLowerCase().contains(query) ||
            s['name'].toString().toLowerCase().contains(query))
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final sub = filtered[i];
        final bool isPro = sub['is_professional_course'] ?? true;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: aViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(sub['code'],
                        style: const TextStyle(
                            color: aViolet,
                            fontWeight: FontWeight.w900,
                            fontSize: 11)),
                  ),
                  _badge(isPro ? "MAJOR" : "MINOR",
                      isPro ? Colors.orange : Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(sub['name'],
                    style: TextStyle(
                        color: text, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const Divider(color: Colors.white10),
              Row(
                children: [
                  const Icon(LucideIcons.layers,
                      size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text("${sub['units']} Units",
                      style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => _showSubjectForm(sub),
                      icon: const Icon(LucideIcons.edit3,
                          size: 16, color: Colors.blueGrey)),
                  IconButton(
                      onPressed: () => _deleteSubject(sub['id'], sub['code']),
                      icon: const Icon(LucideIcons.trash2,
                          size: 16, color: danger)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modalInput(TextEditingController c, String l,
          {bool isNumeric = false, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? "Required" : null
              : null,
          decoration: InputDecoration(
            labelText: l,
            labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w900)),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
