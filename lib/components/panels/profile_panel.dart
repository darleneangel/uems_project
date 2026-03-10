import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
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

  // Controllers initialized with empty strings; values will be synced from DB
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _lrnController;
  late TextEditingController _birthdateController;

  // State variables
  String _gender = 'Female';
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use data passed from parent or fallback to defaults
    _phoneController =
        TextEditingController(text: widget.studentData['phone'] ?? "");
    _emailController =
        TextEditingController(text: widget.studentData['email'] ?? "");
    _lrnController =
        TextEditingController(text: widget.studentData['lrn'] ?? "");
    _birthdateController =
        TextEditingController(text: widget.studentData['dob'] ?? "");
    _gender = widget.studentData['gender'] ?? 'Female';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _lrnController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  /// DATABASE SYNC: Persists profile changes to Supabase
  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);
    final client = SupabaseService().client;
    final String profileId = widget.studentData['id'];

    try {
      // 1. Update Core Profile (Names/Email/Gender/DOB)
      await client.from('profiles').update({
        'email': _emailController.text,
        'gender': _gender,
        'dob': _birthdateController.text,
      }).eq('id', profileId);

      // 2. Update Student Details (Phone/LRN)
      // Note: LRN might be stored in student_details or user_id_number
      await client.from('student_details').update({
        'phone': _phoneController.text,
        'lrn': _lrnController.text,
      }).eq('profile_id', profileId);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cloud Identity Synchronized Successfully"),
              backgroundColor: Color(0xFF69F0AE)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Sync Error: $e"),
              backgroundColor: Colors.redAccent),
        );
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 8, 9),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;
    final Color inputFill = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profile Card
          _buildProfileHeader(cardColor, textColor, subTextColor),
          const SizedBox(height: 24),

          // Form Section
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
                    Text(
                      "Personal Identity Ledger",
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
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
                                ? "Save to Cloud"
                                : "Modify Information",
                          ),
                  ],
                ),
                const SizedBox(height: 24),

                // Gender
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

                // Birthdate
                _buildTextField(
                  controller: _birthdateController,
                  label: "Legal Birthdate (YYYY-MM-DD) *",
                  icon: LucideIcons.calendar,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),

                // Mobile/Phone
                _buildTextField(
                  controller: _phoneController,
                  label: "Verified Contact Number *",
                  icon: LucideIcons.phone,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: "Institutional Email Address *",
                  icon: LucideIcons.mail,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),

                // Student Category (Read-Only)
                _buildLabel("Institutional Classification *", textColor),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white10
                            : Colors.transparent),
                  ),
                  child: Text(
                    widget.studentData['student_type'] ?? "Regular Student",
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // LRN
                _buildTextField(
                  controller: _lrnController,
                  label: "Learner Reference Number (LRN) *",
                  icon: LucideIcons.hash,
                  textColor: textColor,
                  fillColor: inputFill,
                  readOnly: !_isEditing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      Color cardColor, Color textColor, Color subTextColor) {
    final String fullName =
        "${widget.studentData['fn'] ?? 'DARLENE'} ${widget.studentData['ln'] ?? 'ANGEL'}";
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
            offset: const Offset(0, 10),
          ),
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
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (widget.studentData['profile_picture_url'] != null
                          ? NetworkImage(
                                  widget.studentData['profile_picture_url'])
                              as ImageProvider
                          : null),
                  child: (_imageFile == null &&
                          widget.studentData['profile_picture_url'] == null)
                      ? const Icon(LucideIcons.user,
                          color: Colors.white, size: 40)
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
                          size: 14, color: Color(0xFF8B5CF6)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  "${widget.studentData['user_id_number']} • ${widget.studentData['program'] ?? 'BS Computer Science'}",
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    widget.studentData['enrollment_status']
                            ?.toString()
                            .toUpperCase() ??
                        "ENROLLED",
                    style: GoogleFonts.inter(
                        color: const Color(0xFF1E1B4B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(label.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textColor.withOpacity(0.6),
            letterSpacing: 0.5));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color fillColor,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, textColor),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style:
              GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: textColor.withOpacity(0.5)),
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
  }

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
                  width: 2),
            ),
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
}
