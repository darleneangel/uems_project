import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

class StudentPanelContent extends StatelessWidget {
  final String panelType;

  const StudentPanelContent({super.key, required this.panelType});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color tDark = Color(0xFF0F071D);
  static const Color surface = Color(0xFF1E1B4B);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    switch (panelType) {
      case 'subject_load':
        return _buildSubjectLoadPanel();
      case 'assessment':
        return _buildAssessmentPanel();
      case 'grade_book':
        return _buildGradeBookPanel();
      case 'clearance':
        return _buildClearancePanel();
      case 'profile':
        return const ProfilePanel();
      case 'payment_upload':
        return const PaymentUploadPanel();
      default:
        return _buildDefaultPanel();
    }
  }

  Widget _buildSubjectLoadPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "2nd Semester SY 2025-2026",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ...[
                "CS 101 - Data Structures",
                "CS 102 - Web Development",
                "CS 103 - Database Management",
                "CS 104 - Software Engineering",
              ].asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: aViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: aViolet.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(LucideIcons.checkCircle2,
                            color: success, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ...[
                ('CS 101 - Data Structures', '92%', true),
                ('CS 102 - Web Development', '88%', true),
                ('CS 103 - Database Management', '85%', true),
                ('CS 104 - Software Engineering', '90%', true),
              ].map((assessment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            assessment.$1,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            assessment.$2,
                            style: GoogleFonts.inter(
                              color: success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: double.parse(assessment.$2.replaceAll('%', '')) /
                              100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(success),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeBookPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Table(
                border: TableBorder(
                  horizontalInside:
                      BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: aViolet.withOpacity(0.1),
                    ),
                    children: [
                      _tableHeader('Subject'),
                      _tableHeader('Midterm'),
                      _tableHeader('Final'),
                      _tableHeader('Grade'),
                    ],
                  ),
                  ...['CS 101', 'CS 102', 'CS 103', 'CS 104']
                      .asMap()
                      .entries
                      .map((entry) {
                    final grades = ['92', '88', '85', '90'];
                    return TableRow(
                      children: [
                        _tableCell(entry.value),
                        _tableCell(grades[entry.key]),
                        _tableCell(grades[entry.key]),
                        _tableCell('${grades[entry.key]}%'),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClearancePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ...[
                ('Library Clearance', true),
                ('Financial Clearance', true),
                ('Registrar Clearance', false),
                ('Faculty Clearance', true),
              ].map((clearance) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (clearance.$2 ? success : aViolet)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (clearance.$2 ? success : aViolet)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clearance.$1,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          clearance.$2
                              ? LucideIcons.checkCircle2
                              : LucideIcons.clock,
                          color: clearance.$2 ? success : aViolet,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          'Panel not implemented yet',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.white70),
      ),
    );
  }
}

/// Rich profile panel with background and profile picture picker.
class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key});

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.camera),
            title: const Text('Camera'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: const Text('Gallery'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;
  final XFile? picked =
      await _picker.pickImage(source: source, imageQuality: 85);
  if (picked != null) {
    setState(() {
      _imageFile = File(picked.path);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    // Use the static colors from StudentPanelContent
    final pViolet = StudentPanelContent.pViolet;
    final aViolet = StudentPanelContent.aViolet;

    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [pViolet.withOpacity(0.95), aViolet.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Decorative background circle
                Positioned(
                  top: -40,
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white10, Colors.transparent],
                        radius: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(80),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? Text(
                            'DA',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'DARLENE ANGEL',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('Student ID', '2024-00001'),
            _infoRow('Email', 'darlene.angel@student.edu'),
            _infoRow('Program', 'Bachelor of Science in Computer Science'),
            _infoRow('Year Level', '2nd Year'),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(LucideIcons.camera),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: pViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

/// Payment Upload panel: pick image and send (simulated upload).
class PaymentUploadPanel extends StatefulWidget {
  const PaymentUploadPanel({super.key});

  @override
  State<PaymentUploadPanel> createState() => _PaymentUploadPanelState();
}

class _PaymentUploadPanelState extends State<PaymentUploadPanel> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  Future<void> _pickSlip() async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.camera),
            title: const Text('Camera'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: const Text('Gallery'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;
  final XFile? xfile =
      await _picker.pickImage(source: source, imageQuality: 80);
  if (xfile != null) setState(() => _selectedFile = File(xfile.path));
}

  Future<void> _sendSlip() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deposit slip first.')),
      );
      return;
    }
    setState(() => _isSending = true);

    // Simulate upload delay. Replace with your API upload logic.
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposit slip uploaded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = StudentPanelContent.surface;
    final aViolet = StudentPanelContent.aViolet;
    final success = StudentPanelContent.success;
    final pViolet = StudentPanelContent.pViolet;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Deposit Slip',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your deposit slip image and press Send.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            if (_selectedFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedFile!,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: aViolet.withOpacity(0.12)),
                ),
                child: Center(
                  child: Text(
                    'No file selected',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickSlip,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('Choose Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: aViolet.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendSlip,
                  icon: _isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success,
                    foregroundColor: pViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}