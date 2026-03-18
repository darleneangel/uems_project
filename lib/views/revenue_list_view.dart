import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RevenueListView extends StatelessWidget {
  const RevenueListView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    final revenues = [
      {'source': 'Tuition Fees', 'amount': '₱1,200,000', 'date': '2025-12-15'},
      {'source': 'Admission Fees', 'amount': '₱450,000', 'date': '2025-12-10'},
      {'source': 'Lab Fees', 'amount': '₱200,000', 'date': '2025-12-08'},
      {'source': 'Library Fees', 'amount': '₱85,000', 'date': '2025-12-05'},
      {'source': 'Registration Fees', 'amount': '₱320,000', 'date': '2025-12-01'},
      {'source': 'Miscellaneous Fees', 'amount': '₱175,000', 'date': '2025-11-28'},
      {'source': 'Extension Fees', 'amount': '₱95,000', 'date': '2025-11-25'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Revenue Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                'Total Revenue: ₱2.5M',
                style: GoogleFonts.inter(
                  color: success,
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
                      final revenue = revenues[index];
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
                                color: success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up, color: success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(revenue['source']!, 
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(revenue['date']!, 
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              revenue['amount']!,
                              style: GoogleFonts.inter(
                                color: success,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: revenues.length,
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
