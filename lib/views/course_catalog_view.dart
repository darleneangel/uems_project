import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseCatalogView extends StatelessWidget {
  const CourseCatalogView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final courses = [
      {'courseCode': 'CS 101', 'courseName': 'Data Structures', 'credits': '3', 'semester': '1st Sem'},
      {'courseCode': 'CS 102', 'courseName': 'Web Development', 'credits': '4', 'semester': '1st Sem'},
      {'courseCode': 'CS 103', 'courseName': 'Database Management', 'credits': '3', 'semester': '2nd Sem'},
      {'courseCode': 'CS 104', 'courseName': 'Software Engineering', 'credits': '4', 'semester': '2nd Sem'},
      {'courseCode': 'CS 201', 'courseName': 'Artificial Intelligence', 'credits': '3', 'semester': '1st Sem'},
      {'courseCode': 'CS 202', 'courseName': 'Mobile App Development', 'credits': '4', 'semester': '2nd Sem'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Course Catalog', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                final course = courses[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: aViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.book, color: aViolet, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  course['courseCode']!,
                                  style: GoogleFonts.inter(
                                    color: aViolet,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    course['courseName']!,
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${course['credits']} credits • ${course['semester']}',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: courses.length,
            ),
          ),
        ),
      ),
    );
  }
}
