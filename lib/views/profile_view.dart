import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/dashboard_view.dart';
import 'dart:ui';

class ProfileView extends StatelessWidget {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
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
              // Profile Header
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [accentColor, successColor]),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryDark,
                              borderRadius: BorderRadius.circular(56),
                            ),
                            child: Icon(
                              LucideIcons.user,
                              size: 40,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "KURT ANDREI",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "2023-10294",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Profile Information
              Text(
                "Personal Information",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard("Email", "kurt.andrei@student.edu"),
              const SizedBox(height: 10),
              _buildInfoCard("Phone", "+63 912 345 6789"),
              const SizedBox(height: 10),
              _buildInfoCard("Course", "Bachelor of Science in Computer Science"),
              const SizedBox(height: 10),
              _buildInfoCard("Year Level", "2nd Year"),
              const SizedBox(height: 24),
              
              // Academic Information
              Text(
                "Academic Information",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard("Current GPA", "3.75"),
              const SizedBox(height: 10),
              _buildInfoCard("Total Units Taken", "45"),
              const SizedBox(height: 10),
              _buildInfoCard("Enrollment Status", "Enrolled"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
