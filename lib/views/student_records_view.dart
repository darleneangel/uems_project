import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentRecordsView extends StatelessWidget {
  const StudentRecordsView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final records = [
      {'studentId': '2025-001', 'name': 'James Mitchell', 'program': 'BSCS', 'year': '4th Year', 'gpa': '3.85'},
      {'studentId': '2025-002', 'name': 'Sarah Johnson', 'program': 'BSIT', 'year': '3rd Year', 'gpa': '3.72'},
      {'studentId': '2025-003', 'name': 'Michael Chen', 'program': 'BSBA', 'year': '2nd Year', 'gpa': '3.65'},
      {'studentId': '2025-004', 'name': 'Jennifer Lee', 'program': 'BSCS', 'year': '1st Year', 'gpa': '3.91'},
      {'studentId': '2025-005', 'name': 'David Rodriguez', 'program': 'BSEd', 'year': '3rd Year', 'gpa': '3.54'},
      {'studentId': '2025-006', 'name': 'Amanda Williams', 'program': 'BSIT', 'year': '4th Year', 'gpa': '3.78'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Student Records Management', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                final record = records[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: aViolet,
                        child: Text(
                          record['name']!.split(' ').first[0],
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record['name']!,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${record['studentId']} • ${record['program']} • ${record['year']}',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GPA',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                          ),
                          Text(
                            record['gpa']!,
                            style: GoogleFonts.inter(
                              color: aViolet,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: records.length,
            ),
          ),
        ),
      ),
    );
  }
}
