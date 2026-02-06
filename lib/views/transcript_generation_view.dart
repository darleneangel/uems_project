import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TranscriptGenerationView extends StatelessWidget {
  const TranscriptGenerationView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final transcripts = [
      {'studentId': '2025-001', 'name': 'James Mitchell', 'requestDate': '2025-12-10', 'status': 'Completed', 'daysAgo': '2 days'},
      {'studentId': '2025-002', 'name': 'Sarah Johnson', 'requestDate': '2025-12-09', 'status': 'Completed', 'daysAgo': '3 days'},
      {'studentId': '2025-003', 'name': 'Michael Chen', 'requestDate': '2025-12-12', 'status': 'Processing', 'daysAgo': 'Today'},
      {'studentId': '2025-004', 'name': 'Jennifer Lee', 'requestDate': '2025-12-12', 'status': 'Pending', 'daysAgo': 'Today'},
      {'studentId': '2025-005', 'name': 'David Rodriguez', 'requestDate': '2025-12-11', 'status': 'Completed', 'daysAgo': '1 day'},
      {'studentId': '2025-006', 'name': 'Amanda Williams', 'requestDate': '2025-12-08', 'status': 'Completed', 'daysAgo': '4 days'},
    ];

    Color statusColor(String status) {
      switch (status) {
        case 'Completed':
          return success;
        case 'Processing':
          return Colors.orangeAccent;
        case 'Pending':
          return Colors.redAccent;
        default:
          return Colors.white54;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Transcript Generation', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                final transcript = transcripts[index];
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
                          transcript['name']!.split(' ').first[0],
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transcript['name']!,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transcript['studentId']} • ${transcript['daysAgo']}',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor(transcript['status']!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor(transcript['status']!).withOpacity(0.25)),
                        ),
                        child: Text(
                          transcript['status']!,
                          style: GoogleFonts.inter(
                            color: statusColor(transcript['status']!),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: transcripts.length,
            ),
          ),
        ),
      ),
    );
  }
}
