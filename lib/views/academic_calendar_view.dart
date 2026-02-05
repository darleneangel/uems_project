import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcademicCalendarView extends StatelessWidget {
  const AcademicCalendarView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final events = [
      {'event': 'Classes Begin', 'date': '2025-01-06', 'type': 'Academic'},
      {'event': 'Midterm Examinations', 'date': '2025-03-03', 'type': 'Examination'},
      {'event': 'Spring Break', 'date': '2025-03-17', 'type': 'Holiday'},
      {'event': 'Final Examinations', 'date': '2025-05-05', 'type': 'Examination'},
      {'event': 'Semester Ends', 'date': '2025-05-16', 'type': 'Academic'},
      {'event': 'Summer Term Begins', 'date': '2025-06-02', 'type': 'Academic'},
      {'event': 'Graduation Ceremony', 'date': '2025-06-21', 'type': 'Event'},
    ];

    Color _typeColor(String type) {
      switch (type) {
        case 'Academic':
          return aViolet;
        case 'Examination':
          return Colors.orangeAccent;
        case 'Holiday':
          return success;
        case 'Event':
          return Colors.redAccent;
        default:
          return Colors.white54;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Academic Calendar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                final event = events[index];
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
                          color: _typeColor(event['type']!).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_month, color: _typeColor(event['type']!), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['event']!,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event['date']!,
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _typeColor(event['type']!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event['type']!,
                          style: GoogleFonts.inter(
                            color: _typeColor(event['type']!),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: events.length,
            ),
          ),
        ),
      ),
    );
  }
}
