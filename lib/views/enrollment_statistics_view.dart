import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnrollmentStatisticsView extends StatelessWidget {
  const EnrollmentStatisticsView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final enrollments = [
      {'semester': '1st Semester SY 2025-2026', 'totalStudents': '1,245', 'newStudents': '342', 'status': 'Active'},
      {'semester': '2nd Semester SY 2025-2026', 'totalStudents': '1,189', 'newStudents': '256', 'status': 'Active'},
      {'semester': '1st Semester SY 2024-2025', 'totalStudents': '1,156', 'newStudents': '298', 'status': 'Completed'},
      {'semester': '2nd Semester SY 2024-2025', 'totalStudents': '1,243', 'newStudents': '315', 'status': 'Completed'},
      {'semester': 'Summer 2025', 'totalStudents': '456', 'newStudents': '89', 'status': 'Completed'},
      {'semester': 'Summer 2024', 'totalStudents': '412', 'newStudents': '76', 'status': 'Completed'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Enrollment Statistics', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      backgroundColor: const Color(0xFF0F0820),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final enrollment = enrollments[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              enrollment['semester']!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: enrollment['status'] == 'Active'
                                  ? success.withOpacity(0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              enrollment['status']!,
                              style: GoogleFonts.inter(
                                color: enrollment['status'] == 'Active' ? success : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Students',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                              ),
                              Text(
                                enrollment['totalStudents']!,
                                style: GoogleFonts.inter(
                                  color: aViolet,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Students',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                              ),
                              Text(
                                enrollment['newStudents']!,
                                style: GoogleFonts.inter(
                                  color: success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: enrollments.length,
            ),
          ),
        ),
      ),
    );
  }
}
