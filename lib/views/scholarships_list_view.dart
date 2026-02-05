import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScholarshipsListView extends StatelessWidget {
  const ScholarshipsListView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final scholarships = [
      {'name': 'Academic Excellence Award', 'recipient': 'Anna Reyes', 'amount': '₱150,000'},
      {'name': 'Merit Scholarship', 'recipient': 'David Lopez', 'amount': '₱200,000'},
      {'name': 'STEM Scholarship', 'recipient': 'Rachel Chen', 'amount': '₱180,000'},
      {'name': 'Sports Award', 'recipient': 'Michael Santos', 'amount': '₱120,000'},
      {'name': 'Need-based Grant', 'recipient': 'Sofia Garcia', 'amount': '₱95,000'},
      {'name': 'International Scholarship', 'recipient': 'James Park', 'amount': '₱155,000'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Scholarships Awarded', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Scholarships: ₱800K',
                style: GoogleFonts.inter(
                  color: aViolet,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final scholarship = scholarships[index];
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
                                scholarship['name']!.split(' ').first[0],
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(scholarship['name']!, 
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(scholarship['recipient']!, 
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              scholarship['amount']!,
                              style: GoogleFonts.inter(
                                color: aViolet,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: scholarships.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
