import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/login_view.dart';
import 'package:uems_project/views/subject_load_view.dart';
import 'package:uems_project/views/assessment_view.dart';
import 'package:uems_project/views/grade_book_view.dart';
import 'package:uems_project/views/clearance_view.dart';
import 'package:uems_project/views/profile_view.dart';
import 'package:uems_project/views/health_declaration_view.dart';
import 'dart:ui';

class StudentDashboard extends StatelessWidget {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.clipboardList, size: 18),
              label: const Text("Enroll Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: primaryDark,
              ),
            ),
          )
        ],
      ),
      drawer: _buildModernSidebar(context),
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
                "Home > Dashboard",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _buildEnrollmentTrack(),
              const SizedBox(height: 30),
              _buildAnnouncements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: primaryDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.2), secondaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.school, color: successColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  "UEMS Portal",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _modernSidebarItem(LucideIcons.layoutDashboard, "Dashboard", context, isSelected: true),
          _modernSidebarItem(LucideIcons.bookOpen, "Subject Load", context, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SubjectLoadView()))),
          _modernSidebarItem(LucideIcons.barChart3, "Assessment", context, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AssessmentView()))),
          _modernSidebarItem(LucideIcons.book, "Grade Book", context, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GradeBookView()))),
          _modernSidebarItem(LucideIcons.shield, "Clearance", context, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClearanceView()))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Account",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
          ),
          _modernSidebarItem(LucideIcons.user, "KURT ANDREI", context, color: accentColor, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileView()))),
          _modernSidebarItem(LucideIcons.heart, "Health Declaration", context, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HealthDeclarationView()))),
          _modernSidebarItem(
            LucideIcons.logOut,
            "Logout",
            context,
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const UEMSLoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _modernSidebarItem(
    IconData icon,
    String title,
    BuildContext context, {
    bool isSelected = false,
    Color color = Colors.white70,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? accentColor : color),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? accentColor : color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  // 2. The Enrollment Track (The Green Progress Bar)
  Widget _buildEnrollmentTrack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enrollment Tracks",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "School Year: 2025-2026 | Semester: 2nd Semester",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),

              // Progress Bar Container
              Stack(
                children: [
                  Container(
                    height: 28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.85,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(colors: [successColor, accentColor]),
                      ),
                      child: Center(
                        child: Text(
                          "You are Now Enrolled",
                          style: GoogleFonts.inter(
                            color: primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusLabel("Application Submitted"),
                  _StatusLabel("Paid", isCheck: true),
                  _StatusLabel("Advising"),
                  _StatusLabel("Assessment", color: successColor, isBold: true),
                ],
              ),
              const SizedBox(height: 30),

              // Upload Button Section
              Text(
                "For BANK PAYMENT, upload a picture of your payment/deposit slip here.",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.upload, size: 18),
                  label: const Text("Upload & Send"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "NOTED: You should be in the payment step to be able to upload.",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Announcements Section
  Widget _buildAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Announcements",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.megaphone, color: accentColor, size: 24),
                ),
                title: Text(
                  "Academic Affairs Office",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "Grades for the 2nd Semester are now available for viewing. Check your Grade Book.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  "03/26/2026",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final bool isCheck;
  final Color color;
  final bool isBold;
  const _StatusLabel(this.label, {this.isCheck = false, this.color = Colors.white, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCheck)
          const Icon(LucideIcons.check, size: 16, color: Colors.white)
        else
          Icon(
            LucideIcons.circle,
            size: 12,
            color: isBold ? Colors.white : Colors.white54,
          ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: isBold ? color : Colors.white70,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}