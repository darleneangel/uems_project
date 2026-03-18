import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class PayrollPanel extends StatelessWidget {
  final bool isDarkMode;
  const PayrollPanel({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Institution Payroll",
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
        const Text(
            "Synchronizing with HR attendance and 201 files for disbursement.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        const SizedBox(height: 32),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService()
                .client
                .from('employee_details')
                .stream(primaryKey: ['profile_id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final employees = snapshot.data!;

              return ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, i) {
                  final emp = employees[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(LucideIcons.user, color: Colors.white)),
                        const SizedBox(width: 20),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(emp['position'],
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text("Base Salary: ₱${emp['base_salary']}",
                                  style: const TextStyle(
                                      color: Colors.blueGrey, fontSize: 12)),
                            ])),
                        ElevatedButton(
                            onPressed: () {},
                            child: const Text("RELEASE SALARY")),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
