import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/dashboard_view.dart';
import 'dart:ui';

class AssessmentView extends StatelessWidget {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  const AssessmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Assessment',
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
                "My Assessments",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Upcoming and completed assessments",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildAssessmentCard("Midterm Exam", "CS-101", "March 15, 2026", "Pending", Colors.orange),
              const SizedBox(height: 12),
              _buildAssessmentCard("Quiz 3", "CS-102", "March 10, 2026", "Completed", successColor),
              const SizedBox(height: 12),
              _buildAssessmentCard("Project Submission", "CS-103", "March 20, 2026", "Pending", Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(String title, String code, String date, String status, Color statusColor) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.bookOpen, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    code,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.calendar, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
