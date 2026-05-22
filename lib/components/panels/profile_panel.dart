import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class ProfilePanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> studentData;

  const ProfilePanel({
    super.key,
    required this.isDarkMode,
    required this.studentData,
  });

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  final SupabaseService _service = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  // 🛡️ INITIALIZATION: Direct initialization prevents LateInitializationErrors
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _lrdController = TextEditingController();
  final TextEditingController _programController = TextEditingController();

  // State flags
  String _gender = 'Female';
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSyncing = true;

  // Standardized variable name to match error log context
  Map<String, dynamic> _currentData = {};

  @override
  void initState() {
    super.initState();
    // Immediate assignment to prevent build-time crashes
    _currentData = Map<String, dynamic>.from(widget.studentData);
    _syncControllersFromLedger();
  }

  @override
  void didUpdateWidget(ProfilePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentData != widget.studentData) {
      setState(() {
        _currentData = Map<String, dynamic>.from(widget.studentData);
        _syncControllersFromLedger();
      });
    }
  }

  /// 🛰️ LEDGER SYNC: Robust extraction for institutional data
  void _syncControllersFromLedger() {
    final dynamic detailsRaw = _currentData['student_details'];
    Map<String, dynamic>? details;

    // Supabase joins often return a List or a Map
    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw.first;
    } else if (detailsRaw is Map<String, dynamic>) {
      details = detailsRaw;
    }

    setState(() {
      _phoneController.text =
          (details?['phone'] ?? _currentData['phone'] ?? "").toString();
      _emailController.text = (_currentData['email'] ?? "").toString();
      _birthdateController.text = (_currentData['dob'] ?? "").toString();
      _lrdController.text = (_currentData['user_id_number'] ?? "").toString();

      // 🎓 PROGRAM CITATION: Mapping 'BS Computer Science' or similar from course join
      _programController.text =
          (details?['courses']?['name'] ?? _currentData['program_name'] ?? "")
              .toString();

      _gender = _currentData['gender'] ?? 'Female';
      _isSyncing = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _lrdController.dispose();
    _programController.dispose();
    super.dispose();
  }

  /// 🛰️ DATABASE PERSISTENCE: Atomic commit to Ledger
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final String uuid = _currentData['id'] ?? '';

    try {
      // 1. Update Core Identity
      await _service.client.from('profiles').update({
        'email': _emailController.text.trim(),
        'gender': _gender,
        'dob': _birthdateController.text.trim(),
      }).eq('id', uuid);

      // 2. Update Student Specifics
      await _service.client.from('student_details').update({
        'phone': _phoneController.text.trim(),
      }).eq('profile_id', uuid);

      // 3. Full Data Reconciliation
      final fresh = await _service.client
          .from('profiles')
          .select('*, student_details(*, courses(name))')
          .eq('id', uuid)
          .single();

      if (mounted) {
        setState(() {
          _currentData = fresh;
          _isEditing = false;
          _isSaving = false;
        });
        _syncControllersFromLedger();
        _showToast("Institutional Identity Verified & Updated",
            const Color(0xFF69F0AE));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast("Sync Error: Ledger Connectivity Failed.", Colors.redAccent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    if (_isSyncing) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(textColor),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Cloud Identity Ledger",
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            onPressed: () => _isEditing
                                ? _saveChanges()
                                : setState(() => _isEditing = true),
                            icon: Icon(_isEditing
                                ? LucideIcons.save
                                : LucideIcons.edit3),
                            color: const Color(0xFF8B5CF6),
                            tooltip: _isEditing
                                ? "Finalize Changes"
                                : "Modify Record",
                          ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- CITATION: ACADEMIC PROGRAM ---

                const SizedBox(height: 24),
                _buildSectionLabel("Gender Representation *"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _genderOption("Male", textColor),
                    const SizedBox(width: 32),
                    _genderOption("Female", textColor),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInputField(
                  controller: _birthdateController,
                  label: "Date of Birth *",
                  icon: LucideIcons.calendar,
                  textColor: textColor,
                  fill: inputFill,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _phoneController,
                  label: "Mobile Contact Number *",
                  icon: LucideIcons.phone,
                  textColor: textColor,
                  fill: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _emailController,
                  label: "Institutional Email *",
                  icon: LucideIcons.mail,
                  textColor: textColor,
                  fill: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 24),
                _buildSectionLabel("Institutional LRD Identifier"),
                const SizedBox(height: 8),
                _staticDisplayField(_lrdController.text, textColor, inputFill),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Color textColor) {
    // 🛡️ Safe identity resolution
    final String fn =
        (_currentData['fn'] ?? _currentData['first_name'] ?? '').toString();
    final String ln =
        (_currentData['ln'] ?? _currentData['last_name'] ?? '').toString();
    final String program = _programController.text;
    final String initials =
        (fn.isNotEmpty ? fn[0] : 'S') + (ln.isNotEmpty ? ln[0] : 'U');

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDarkMode
              ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
              : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white12,
            child: Text(initials.toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32)),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    (fn.isEmpty ? 'Identifying User...' : '$fn $ln')
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26)),
                Text(program,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("OFFICIAL ENROLLEE",
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1E1B4B),
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey,
          letterSpacing: 1));

  Widget _staticDisplayField(String v, Color t, Color f) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration:
            BoxDecoration(color: f, borderRadius: BorderRadius.circular(16)),
        child: Text(v,
            style: GoogleFonts.inter(
                color: t, fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _buildInputField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      required Color textColor,
      required Color fill,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey),
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _genderOption(String label, Color textColor) {
    bool active = _gender == label;
    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _gender = label) : null,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: active ? const Color(0xFF8B5CF6) : Colors.blueGrey,
                    width: 2)),
            child: active
                ? Center(
                    child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6), shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2005),
        firstDate: DateTime(1980),
        lastDate: DateTime.now());
    if (picked != null) {
      setState(() =>
          _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
