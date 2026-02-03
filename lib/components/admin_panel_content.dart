import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminPanelContent extends StatelessWidget {
  final String panelType;

  const AdminPanelContent({super.key, required this.panelType});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);
  static const Color pViolet = Color(0xFF2E1065);

  @override
  Widget build(BuildContext context) {
    switch (panelType) {
      case 'announcements':
        return _buildAnnouncementsPanel();
      case 'admissions':
        return _buildAdmissionsPanel();
      case 'registrar':
        return _buildRegistrarPanel();
      case 'accounting':
        return _buildAccountingPanel();
      case 'study_loads':
        return _buildStudyLoadsPanel();
      case 'grade_recording':
        return _buildGradeRecordingPanel();
      default:
        return _buildDefaultPanel();
    }
  }

  Widget _buildAnnouncementsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnnouncementForm(),
        const SizedBox(height: 32),
        _buildAnnouncementList(),
      ],
    );
  }

  Widget _buildAnnouncementForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Announcement',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Announcement Title',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              hintStyle: GoogleFonts.inter(color: Colors.white54),
            ),
            style: GoogleFonts.inter(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Announcement Content',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              hintStyle: GoogleFonts.inter(color: Colors.white54),
            ),
            style: GoogleFonts.inter(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.send, size: 18),
              label: const Text('PUBLISH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: success,
                foregroundColor: pViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Announcements',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('Semester 2 Starts Monday', '2 hours ago'),
            ('Grade Submission Deadline Extended', '1 day ago'),
            ('New Course Registration Guidelines', '3 days ago'),
          ].map((announcement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: aViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: aViolet.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.$1,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            announcement.$2,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.edit, color: aViolet, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdmissionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatBox('Total Applications', '245', aViolet),
            _buildStatBox('Pending Review', '43', Colors.orangeAccent),
            _buildStatBox('Approved', '182', success),
            _buildStatBox('Rejected', '20', Colors.redAccent),
          ],
        ),
        const SizedBox(height: 24),
        _buildAdmissionsList(),
      ],
    );
  }

  Widget _buildRegistrarPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ...[
            'Enrollment Statistics',
            'Student Records Management',
            'Transcript Generation',
            'Academic Calendar',
            'Course Catalog',
          ].map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(LucideIcons.fileText, color: aViolet),
                title: Text(
                  service,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                trailing: Icon(LucideIcons.chevronRight, color: aViolet),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatBox('Total Revenue', '₱2.5M', success),
            _buildStatBox('Pending Payments', '₱450K', Colors.orangeAccent),
            _buildStatBox('Scholarships Awarded', '₱800K', aViolet),
            _buildStatBox('Refunds Processed', '₱125K', Colors.redAccent),
          ],
        ),
        const SizedBox(height: 24),
        _buildFinancialReport(),
      ],
    );
  }

  Widget _buildStudyLoadsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester: 2nd Semester SY 2025-2026',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...[
            ('CS 101 - Data Structures', '120 students', true),
            ('CS 102 - Web Development', '95 students', true),
            ('CS 103 - Database Management', '87 students', true),
            ('CS 104 - Software Engineering', '102 students', true),
          ].map((load) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(LucideIcons.bookOpen, color: aViolet),
                title: Text(
                  load.$1,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  load.$2,
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
                trailing: Icon(
                  load.$3
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  color: load.$3 ? success : Colors.white54,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGradeRecordingPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grade Submissions Status',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '85% Complete',
                  style: GoogleFonts.inter(
                    color: success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.85,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(success),
            ),
          ),
          const SizedBox(height: 20),
          ...[
            'CS 101: Submitted',
            'CS 102: Submitted',
            'CS 103: Submitted',
            'CS 104: Pending',
          ].map((subject) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    subject.contains('Submitted')
                        ? LucideIcons.checkCircle2
                        : LucideIcons.clock,
                    color: subject.contains('Submitted')
                        ? success
                        : Colors.orangeAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    subject,
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.barChart3, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmissionsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Applications',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: aViolet,
                  child: Text(
                    'A${index + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Applicant ${index + 1}',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  'BSCS Program',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.check,
                            color: success, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x,
                            color: Colors.redAccent, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFinancialReport() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Financial Summary',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final values = [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 0.6];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 35,
                      height: 150 * values[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [aViolet, aViolet.withOpacity(0.3)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceDark,
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
}
