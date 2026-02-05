import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentsListView extends StatelessWidget {
  const PaymentsListView({super.key});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  @override
  Widget build(BuildContext context) {
    final payments = [
      {'name': 'John Smith', 'amount': '₱45,000', 'status': 'pending', 'dueDate': '2025-12-20'},
      {'name': 'Maria Garcia', 'amount': '₱38,500', 'status': 'pending', 'dueDate': '2025-12-18'},
      {'name': 'Ahmed Hassan', 'amount': '₱52,000', 'status': 'pending', 'dueDate': '2025-12-25'},
      {'name': 'Lisa Wong', 'amount': '₱41,200', 'status': 'pending', 'dueDate': '2025-12-15'},
      {'name': 'Carlos Mendez', 'amount': '₱48,800', 'status': 'pending', 'dueDate': '2025-12-22'},
      {'name': 'Angela Santos', 'amount': '₱39,500', 'status': 'pending', 'dueDate': '2025-12-17'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text('Pending Payments', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                'Total Pending: ₱450K',
                style: GoogleFonts.inter(
                  color: Colors.orangeAccent,
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
                      final payment = payments[index];
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
                                payment['name']!.split(' ').first[0],
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(payment['name']!, 
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Due: ${payment['dueDate']}', 
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              payment['amount']!,
                              style: GoogleFonts.inter(
                                color: Colors.orangeAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: payments.length,
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
