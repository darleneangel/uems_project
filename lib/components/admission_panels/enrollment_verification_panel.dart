import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EnrollmentVerificationPanel extends StatefulWidget {
  final bool isDarkMode;
  const EnrollmentVerificationPanel({super.key, required this.isDarkMode});

  @override
  State<EnrollmentVerificationPanel> createState() =>
      _EnrollmentVerificationPanelState();
}

class _EnrollmentVerificationPanelState
    extends State<EnrollmentVerificationPanel> {
  // Mock data for students enrolling for the next semester
  final List<Map<String, dynamic>> _enrollingStudents = [
    {
      "id": "2023-10042",
      "name": "DARLENE ANGEL L. CUSTODIO",
      "program": "BS INFORMATION TECHNOLOGY",
      "year": "3rd Year",
      "status": "Pending Verification",
    },
    {
      "id": "2024-20015",
      "name": "JOY RAMOS",
      "program": "BS COMPUTER SCIENCE",
      "year": "2nd Year",
      "status": "Pending Verification",
    },
    {
      "id": "2022-30089",
      "name": "SEAN KIEFER BENITEZ",
      "program": "BS COMPUTER ENGINEERING",
      "year": "4th Year",
      "status": "Pending Verification",
    },
  ];

  void _verifyStudent(int index) {
    final student = _enrollingStudents[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${student['name']} verified. Forwarded to Program Chair for study load generation.",
        ),
        backgroundColor: const Color(0xFF69F0AE),
      ),
    );
    setState(() {
      _enrollingStudents.removeAt(index);
    });
  }

  void _rejectStudent(int index) {
    final student = _enrollingStudents[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Enrollment request for ${student['name']} rejected."),
        backgroundColor: Colors.redAccent,
      ),
    );
    setState(() {
      _enrollingStudents.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode
        ? const Color(0xFF1E1B4B)
        : Colors.white;
    final Color subTextColor = widget.isDarkMode
        ? Colors.white54
        : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enrollment Verification",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Verify students enrolling for the next semester to proceed with study load generation.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _enrollingStudents.isEmpty
                ? Center(
                    child: Text(
                      "No pending enrollment requests.",
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: _enrollingStudents.length,
                    itemBuilder: (context, index) {
                      final student = _enrollingStudents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.isDarkMode
                                ? Colors.white10
                                : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(
                                0xFF8B5CF6,
                              ).withOpacity(0.1),
                              child: Text(
                                student['name'][0],
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    "${student['id']} • ${student['program']}",
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Target: ${student['year']} (Next Sem)",
                                    style: const TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => _rejectStudent(index),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("REJECT"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _verifyStudent(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF69F0AE),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("VERIFY & FORWARD"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
