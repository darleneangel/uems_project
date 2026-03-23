import 'dart:io';
import 'dart:convert';
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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _service = SupabaseService();

  // Controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _birthdateController;
  late TextEditingController _lrdController;

  // State variables
  String _gender = 'Female';
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSyncing = true;

  // Local copy of student data to ensure UI reflects DB changes immediately
  late Map<String, dynamic> _currentStudentData;

  @override
  void initState() {
    super.initState();
    _currentStudentData = Map<String, dynamic>.from(widget.studentData);

    // Initialize controllers once
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _birthdateController = TextEditingController();
    _lrdController = TextEditingController();

    _syncControllersFromState();
  }

  /// 🛰️ SYNC ENGINE: Explicitly updates the text in the controllers
  /// This ensures that after a database fetch, the UI fields are repopulated.
  /// Fixed to handle Supabase returning joined tables as Lists.
  void _syncControllersFromState() {
    final dynamic detailsRaw = _currentStudentData['student_details'];

    // Supabase often returns joined tables as a List of Maps
    Map<String, dynamic>? details;
    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw.first;
    } else if (detailsRaw is Map<String, dynamic>) {
      details = detailsRaw;
    }

    setState(() {
      // Prioritize the phone number from the details map (student_details table)
      _phoneController.text =
          (details?['phone'] ?? _currentStudentData['phone'] ?? "").toString();
      _emailController.text = (_currentStudentData['email'] ?? "").toString();
      _birthdateController.text = (_currentStudentData['dob'] ?? "").toString();
      _lrdController.text =
          (_currentStudentData['user_id_number'] ?? "").toString();
      _gender = _currentStudentData['gender'] ?? 'Female';
      _isSyncing = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _lrdController.dispose();
    super.dispose();
  }

  /// 🛰️ DATABASE SYNC: Persists changes to 'profiles' and 'student_details'
  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);
    final String profileId = _currentStudentData['id'];

    try {
      // 1. UPDATE 'profiles' TABLE (Email, Gender, DOB)
      await _service.client.from('profiles').update({
        'email': _emailController.text.trim(),
        'gender': _gender,
        'dob': _birthdateController.text.trim(),
      }).eq('id', profileId);

      // 2. UPDATE 'student_details' TABLE (Phone)
      // Linked via profile_id as per your schema
      await _service.client.from('student_details').update({
        'phone': _phoneController.text.trim(),
      }).eq('profile_id', profileId);

      // 3. RE-FETCH FRESH DATA: Pull verified data back from Supabase
      // Using .single() handles the root object, but joined records usually remain a list
      final freshData = await _service.client
          .from('profiles')
          .select('*, student_details(*, courses(name))')
          .eq('id', profileId)
          .single();

      if (mounted) {
        setState(() {
          // Update the source of truth for the header and initials
          _currentStudentData = freshData;
          _isEditing = false;
          _isSaving = false;
        });

        // 4. REFRESH CONTROLLERS: Force the text fields to show the newly saved data
        _syncControllersFromState();

        _showToast(
            "Institutional Ledger Synchronized", const Color(0xFF69F0AE));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast(
            "Sync Error: Unable to write to database. $e", Colors.redAccent);
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    DateTime initial =
        DateTime.tryParse(_birthdateController.text) ?? DateTime(2005, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
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
          _buildProfileHeader(textColor),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            onPressed: () {
                              if (_isEditing) {
                                _saveProfileChanges();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                            icon: Icon(_isEditing
                                ? LucideIcons.save
                                : LucideIcons.edit3),
                            color: const Color(0xFF8B5CF6),
                            tooltip: _isEditing
                                ? "Save to Database"
                                : "Modify Information",
                          ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel("Gender Representation *", textColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGenderOption("Male", textColor),
                    const SizedBox(width: 24),
                    _buildGenderOption("Female", textColor),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _birthdateController,
                  label: "Legal Date of Birth (DOB) *",
                  icon: LucideIcons.calendar,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _phoneController,
                  label: "Verified Contact Number *",
                  icon: LucideIcons.phone,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: "Institutional Email Address *",
                  icon: LucideIcons.mail,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),
                _buildLabel(
                    "Institutional LRD Identifier (User ID)", textColor),
                const SizedBox(height: 8),
                _staticValueField(_lrdController.text, textColor, inputFill),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Color textColor) {
    final String fn = _currentStudentData['fn'] ?? '';
    final String ln = _currentStudentData['ln'] ?? '';
    final String fullName = "$fn $ln";

    // Safe extraction for program name from potentially nested student_details list
    final dynamic detailsRaw = _currentStudentData['student_details'];
    Map<String, dynamic>? details;
    if (detailsRaw is List && detailsRaw.isNotEmpty) {
      details = detailsRaw.first;
    } else if (detailsRaw is Map<String, dynamic>) {
      details = detailsRaw;
    }

    final String program = details?['courses']?['name'] ??
        _currentStudentData['program'] ??
        "General Education";

    final String initials =
        (fn.isNotEmpty ? fn[0] : 'S') + (ln.isNotEmpty ? ln[0] : 'U');

    ImageProvider? profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_currentStudentData['profile_picture_url'] != null &&
        _currentStudentData['profile_picture_url'].toString().isNotEmpty) {
      profileImage =
          NetworkImage(_currentStudentData['profile_picture_url'].toString());
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDarkMode
              ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
              : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white24,
                  backgroundImage: profileImage,
                  child: (profileImage == null)
                      ? Text(
                          initials.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.camera,
                              size: 14, color: Color(0xFF8B5CF6)))),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName.toUpperCase(),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
                const SizedBox(height: 4),
                Text(program,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _statusBadge(details?['enrollment_status'] ?? "ENROLLED"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFF69F0AE),
            borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(),
            style: GoogleFonts.inter(
                color: const Color(0xFF1E1B4B),
                fontSize: 9,
                fontWeight: FontWeight.w900)),
      );

  Widget _buildLabel(String label, Color textColor) => Text(label.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor.withOpacity(0.6),
          letterSpacing: 0.5));

  Widget _staticValueField(String value, Color textColor, Color fill) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration:
            BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12)),
        child: Text(value,
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color fillColor,
    bool readOnly = false,
    VoidCallback? onTap,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label, textColor),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, size: 18, color: textColor.withOpacity(0.5)),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      );

  Widget _buildGenderOption(String value, Color textColor) {
    final bool isSelected = _gender == value;
    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _gender = value) : null,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : textColor.withOpacity(0.3),
                    width: 2)),
            child: isSelected
                ? Center(
                    child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6), shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.inter(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  void _showToast(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
