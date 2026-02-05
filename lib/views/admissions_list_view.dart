import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdmissionsListView extends StatelessWidget {
  final String filter; // 'all', 'pending', 'approved', 'rejected'

  const AdmissionsListView({super.key, required this.filter});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  List<Map<String, String>> _students() {
    final all = [
      {'name': 'Alice Santos', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Ben Delacruz', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Carla Reyes', 'status': 'rejected', 'program': 'BSBA'},
      {'name': 'Daniel Cruz', 'status': 'approved', 'program': 'BSCS'},
      {'name': 'Eve Navarro', 'status': 'pending', 'program': 'BSIT'},
    ];

    if (filter == 'all') return all;
    return all.where((s) => s['status'] == filter).toList();
  }

  String _title() {
    switch (filter) {
      case 'pending':
        return 'Pending Applications';
      case 'approved':
        return 'Approved Applications';
      case 'rejected':
        return 'Rejected Applications';
      default:
        return 'All Applications';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return success;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text(_title(), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
          child: students.isEmpty
              ? Center(
                  child: Text('No applications', style: GoogleFonts.inter(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final status = s['status'] ?? 'pending';
                    return InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
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
                                s['name']!.split(' ').first[0],
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(s['program']!, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _statusColor(status).withOpacity(0.25)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.inter(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.white70),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: students.length,
                ),
        ),
      ),
    );
  }
}
