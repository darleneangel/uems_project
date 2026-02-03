import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        return _buildProfilePanel();
      case 'health_declaration':
        return _buildHealthDeclarationPanel();
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

  Widget _buildProfilePanel() {
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
              CircleAvatar(
                radius: 50,
                backgroundColor: aViolet,
                child: Text(
                  'DA',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _profileField('Name', 'DARLENE ANGEL'),
              _profileField('Student ID', '2024-00001'),
              _profileField('Email', 'darlene.angel@student.edu'),
              _profileField('Program', 'Bachelor of Science in Computer Science'),
              _profileField('Year Level', '2nd Year'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDeclarationPanel() {
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
                'Latest Declaration Status: SUBMITTED',
                style: GoogleFonts.inter(
                  color: success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...[
                'I certify that I am in good health.',
                'I am free from any contagious diseases.',
                'I have received all necessary vaccinations.',
                'I understand the health protocols.',
              ].map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCircle2,
                          color: success, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        item,
                        style: GoogleFonts.inter(color: Colors.white70),
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

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
