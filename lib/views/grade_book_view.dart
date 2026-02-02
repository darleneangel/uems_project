import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/dashboard_view.dart';
import 'dart:ui';

class GradeBookView extends StatelessWidget {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  const GradeBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Grade Book',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard())),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryDark, secondaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Grades",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "School Year: 2025-2026 | Semester: 2nd Semester",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildGradeCard("Introduction to Computer Science", "CS-101", "A", 4.0),
              const SizedBox(height: 12),
              _buildGradeCard("Data Structures", "CS-102", "A-", 3.7),
              const SizedBox(height: 12),
              _buildGradeCard("Web Development", "CS-103", "B+", 3.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeCard(String subject, String code, String grade, double gpa) {
    Color gradeColor = grade.startsWith('A') ? successColor : accentColor;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            code,
                            style: GoogleFonts.inter(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "GPA: $gpa",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade,
                  style: GoogleFonts.inter(
                    color: gradeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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
