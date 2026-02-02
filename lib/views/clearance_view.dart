import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/dashboard_view.dart';
import 'dart:ui';

class ClearanceView extends StatelessWidget {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  const ClearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Clearance',
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
                "Clearance Status",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Check your clearance requirements",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildClearanceCard("Library Clearance", true),
              const SizedBox(height: 12),
              _buildClearanceCard("Finance Office", true),
              const SizedBox(height: 12),
              _buildClearanceCard("Registrar's Office", false),
              const SizedBox(height: 12),
              _buildClearanceCard("Guidance Office", true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearanceCard(String office, bool isCleared) {
    Color statusColor = isCleared ? successColor : Colors.orange;
    String statusText = isCleared ? "Cleared" : "Pending";

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.shield,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    office,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCleared ? LucideIcons.check : LucideIcons.clock,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
