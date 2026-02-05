import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefundsListView extends StatelessWidget {
  const RefundsListView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final refunds = [
      {'name': 'Emily Thompson', 'amount': '₱15,000', 'reason': 'Withdrawal', 'date': '2025-12-10'},
      {'name': 'Robert Jackson', 'amount': '₱22,500', 'reason': 'Course Cancellation', 'date': '2025-12-09'},
      {'name': 'Patricia Brown', 'amount': '₱18,000', 'reason': 'Fee Adjustment', 'date': '2025-12-08'},
      {'name': 'Joseph Martin', 'amount': '₱12,000', 'reason': 'Duplicate Payment', 'date': '2025-12-07'},
      {'name': 'Jennifer Lee', 'amount': '₱25,000', 'reason': 'Scholarship Credited', 'date': '2025-12-06'},
      {'name': 'Christopher Davis', 'amount': '₱32,500', 'reason': 'Overpayment', 'date': '2025-12-05'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Refunds Processed', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                'Total Refunds: ₱125K',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
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
                      final refund = refunds[index];
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
                                refund['name']!.split(' ').first[0],
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(refund['name']!, 
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('${refund['reason']} • ${refund['date']}', 
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              refund['amount']!,
                              style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: refunds.length,
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
