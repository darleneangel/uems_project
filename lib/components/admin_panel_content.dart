import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../views/admissions_list_view.dart';
import '../views/revenue_list_view.dart';
import '../views/payments_list_view.dart';
import '../views/scholarships_list_view.dart';
import '../views/refunds_list_view.dart';
import '../views/enrollment_statistics_view.dart';
import '../views/student_records_view.dart';
import '../views/transcript_generation_view.dart';
import '../views/academic_calendar_view.dart';
import '../views/course_catalog_view.dart';
import '../services/office_request_service.dart';
import 'office_request_form.dart';
import 'request_receiver.dart';
import 'office_admin_service_requests_panel.dart';

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
      case 'office_admin':
        return _buildOfficeAdminPanel();
      case 'admissions':
        return _buildAdmissionsPanel(context);
      case 'registrar':
        return _buildRegistrarPanel(context);
      case 'accounting':
        return _buildAccountingPanel(context);
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
              fillColor: AdminPanelContent.aViolet.withOpacity(0.06),
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
              fillColor: AdminPanelContent.aViolet.withOpacity(0.06),
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

  Widget _buildAdmissionsPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatBox(context, 'Total Applications', '245', aViolet),
            _buildStatBox(context, 'Pending Review', '43', Colors.orangeAccent),
            _buildStatBox(context, 'Approved', '182', success),
            _buildStatBox(context, 'Rejected', '20', Colors.redAccent),
          ],
        ),
        const SizedBox(height: 24),
        _buildAdmissionsList(context),
      ],
    );
  }

  Widget _buildRegistrarPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildRegistrarStatBox(context, 'Enrollment Statistics', '1,245', aViolet),
            _buildRegistrarStatBox(context, 'Student Records', '892', Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRegistrarStatBox(context, 'Transcript Generation', '156', Colors.blueAccent),
            _buildRegistrarStatBox(context, 'Academic Calendar', '7', Colors.yellowAccent),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRegistrarStatBox(context, 'Course Catalog', '45', Colors.cyanAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildRegistrarStatBox(BuildContext context, String label, String value, Color color) {
    void handleTap() {
      final lower = label.toLowerCase();
      if (lower.contains('enrollment')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => const EnrollmentStatisticsView(),
        ));
      } else if (lower.contains('student')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => const StudentRecordsView(),
        ));
      } else if (lower.contains('transcript')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => const TranscriptGenerationView(),
        ));
      } else if (lower.contains('academic')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => const AcademicCalendarView(),
        ));
      } else if (lower.contains('course')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => const CourseCatalogView(),
        ));
      }
    }

    return Expanded(
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildAccountingPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatBox(context, 'Total Revenue', '₱2.5M', success),
            _buildStatBox(context, 'Pending Payments', '₱450K', Colors.orangeAccent),
            _buildStatBox(context, 'Scholarships Awarded', '₱800K', aViolet),
            _buildStatBox(context, 'Refunds Processed', '₱125K', Colors.redAccent),
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

  Widget _buildOfficeAdminPanel() {
    // instantiate non-const to ensure state/init runs reliably
    return OfficeAdminServiceRequestsPanel();
  }

  // DELETE both old versions and paste this ONE version:
  Widget _buildGradeRecordingPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      // We wrap it in a Column so it has a Header title like your other panels
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grade Recording",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // This is the functional UI card you wrote
          Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    valueColor: const AlwaysStoppedAnimation(success),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    bool isAccountingStat = label.toLowerCase().contains('revenue') ||
        label.toLowerCase().contains('payment') ||
        label.toLowerCase().contains('scholarship') ||
        label.toLowerCase().contains('refund');

    bool isApplicationsStat = !isAccountingStat && (
        label.toLowerCase().contains('application') ||
        label.toLowerCase().contains('pending') ||
        label.toLowerCase().contains('approved') ||
        label.toLowerCase().contains('rejected'));

    void handleTap() {
      if (isAccountingStat) {
        final lower = label.toLowerCase();
        if (lower.contains('revenue')) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => const RevenueListView(),
          ));
        } else if (lower.contains('payment')) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => const PaymentsListView(),
          ));
        } else if (lower.contains('scholarship')) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => const ScholarshipsListView(),
          ));
        } else if (lower.contains('refund')) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => const RefundsListView(),
          ));
        }
      } else if (isApplicationsStat) {
        String filter = 'all';
        final lower = label.toLowerCase();
        if (lower.contains('pending')) filter = 'pending';
        if (lower.contains('approved')) filter = 'approved';
        if (lower.contains('rejected')) filter = 'rejected';
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => AdmissionsListView(filter: filter),
        ));
      }
    }

    return Expanded(
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildAdmissionsList(BuildContext context) {
    final students = [
      {'name': 'Alice Santos', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Ben Delacruz', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Carla Reyes', 'status': 'rejected', 'program': 'BSBA'},
      {'name': 'Daniel Cruz', 'status': 'approved', 'program': 'BSCS'},
      {'name': 'Eve Navarro', 'status': 'pending', 'program': 'BSIT'},
      {'name': 'Francis Lopez', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Gina Morales', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Hector Ramos', 'status': 'rejected', 'program': 'BSEd'},
      {'name': 'Ivy Santos', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Jill Tan', 'status': 'approved', 'program': 'BSBA'},
      {'name': 'Karl Ong', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Lara Medina', 'status': 'approved', 'program': 'BSIT'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Applications',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.search, color: Colors.white60),
                onPressed: () async {
                  await showSearch(
                    context: context,
                    delegate: _AdmissionsSearchDelegate(students),
                  );
                },
                tooltip: 'Search applications',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = students[index];
                  final status = s['status'] ?? 'pending';
                  Color statusColor = status == 'approved'
                      ? success
                      : (status == 'rejected' ? Colors.redAccent : Colors.orangeAccent);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: aViolet,
                        child: Text(
                          s['name']!.split(' ').first[0],
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(s['name']!, style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text(s['program']!, style: GoogleFonts.inter(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(LucideIcons.check, color: success, size: 18),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.x, color: Colors.redAccent, size: 18),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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

class OfficeAdminPanel extends StatefulWidget {
  const OfficeAdminPanel({super.key});

  @override
  State<OfficeAdminPanel> createState() => _OfficeAdminPanelState();
}

class _OfficeAdminPanelState extends State<OfficeAdminPanel> {
  final OfficeRequestService _service = OfficeRequestService();

  @override
  Widget build(BuildContext context) {
    // Render the Request Receiver directly — tabs removed because actions
    // (Details, Approve, Reject, Archive) are available on each request card.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AdminPanelContent.surfaceDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: const RequestReceiver(),
    );
  }


  Widget _buildReviewTab() {
    return Container(
      key: const ValueKey('review'),
      child: ValueListenableBuilder<List<OfficeRequest>>(
        valueListenable: _service.notifier,
        builder: (context, list, _) {
          final pending = list.where((r) => r.status == 'pending').toList();
          if (pending.isEmpty) return const Text('No pending requests.', style: TextStyle(color: Colors.white70));
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = pending[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminPanelContent.aViolet.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminPanelContent.aViolet.withOpacity(0.08))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.office.toUpperCase()} - ${r.requestType}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(r.details, style: GoogleFonts.inter(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Text('Submitted: ${r.createdAt}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _service.approve(r.id),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminPanelContent.success),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _service.reject(r.id),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _showDetailsDialog(context, r),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUpdateTab() {
    return Container(
      key: const ValueKey('update'),
      child: ValueListenableBuilder<List<OfficeRequest>>(
        valueListenable: _service.notifier,
        builder: (context, list, _) {
          final items = list.where((r) => r.status != 'archived').toList();
          if (items.isEmpty) return const Text('No records to update.', style: TextStyle(color: Colors.white70));
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = items[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminPanelContent.aViolet.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminPanelContent.aViolet.withOpacity(0.08))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.office.toUpperCase()} - ${r.requestType}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(r.details, style: GoogleFonts.inter(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _showEditDialog(context, r),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminPanelContent.aViolet),
                          child: const Text('Edit'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _service.archive(r.id),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                          child: const Text('Archive'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArchiveTab() {
    return Container(
      key: const ValueKey('archive'),
      child: ValueListenableBuilder<List<OfficeRequest>>(
        valueListenable: _service.notifier,
        builder: (context, list, _) {
          final items = list.where((r) => r.status == 'archived').toList();
          if (items.isEmpty) return const Text('No archived items.', style: TextStyle(color: Colors.white70));
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = items[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminPanelContent.aViolet.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminPanelContent.aViolet.withOpacity(0.08))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.office.toUpperCase()} - ${r.requestType}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(r.details, style: GoogleFonts.inter(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _service.restore(r.id),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminPanelContent.success),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext ctx, OfficeRequest r) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AdminPanelContent.surfaceDark,
        title: Text('${r.office.toUpperCase()} - ${r.requestType}', style: GoogleFonts.inter(color: Colors.white)),
        content: SingleChildScrollView(child: Text(r.details, style: GoogleFonts.inter(color: Colors.white70))),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, OfficeRequest r) {
    final typeCtl = TextEditingController(text: r.requestType);
    final detailsCtl = TextEditingController(text: r.details);
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AdminPanelContent.surfaceDark,
        title: Text('Edit Request', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeCtl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Request Type',
                labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                filled: true,
                  fillColor: AdminPanelContent.aViolet.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminPanelContent.aViolet, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsCtl,
              maxLines: 4,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Details',
                labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                filled: true,
                fillColor: AdminPanelContent.aViolet.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminPanelContent.aViolet, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              _service.updateRequest(r.id, requestType: typeCtl.text.trim(), details: detailsCtl.text.trim());
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminPanelContent.aViolet),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AdmissionsSearchDelegate extends SearchDelegate<Map<String, String>?> {
  final List<Map<String, String>> students;

  _AdmissionsSearchDelegate(this.students);

  @override
  String? get searchFieldLabel => 'Search applicants by name, program, status';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = students.where((s) {
      final q = query.toLowerCase();
      return s['name']!.toLowerCase().contains(q) ||
          s['program']!.toLowerCase().contains(q) ||
          s['status']!.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return Container(
        color: const Color(0xFF0F071D),
        child: Center(child: Text('No results', style: GoogleFonts.inter(color: Colors.white54))),
      );
    }

    return Container(
      color: const Color(0xFF0F071D),
      child: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final s = results[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: AdminPanelContent.aViolet, child: Text(s['name']!.split(' ').first[0], style: GoogleFonts.inter(color: Colors.white))),
            title: Text(s['name']!, style: GoogleFonts.inter(color: Colors.white)),
            subtitle: Text('${s['program']} • ${s['status']}', style: GoogleFonts.inter(color: Colors.white54)),
            onTap: () => close(context, s),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? students
        : students.where((s) {
            final q = query.toLowerCase();
            return s['name']!.toLowerCase().contains(q) ||
                s['program']!.toLowerCase().contains(q) ||
                s['status']!.toLowerCase().contains(q);
          }).toList();

    return Container(
      color: const Color(0xFF0F071D),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: AdminPanelContent.aViolet, child: Text(s['name']!.split(' ').first[0], style: GoogleFonts.inter(color: Colors.white))),
            title: Text(s['name']!, style: GoogleFonts.inter(color: Colors.white)),
            subtitle: Text('${s['program']} • ${s['status']}', style: GoogleFonts.inter(color: Colors.white54)),
            onTap: () => query = s['name']!,
          );
        },
      ),
    );
  }
}
