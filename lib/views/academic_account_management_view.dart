import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/academic_account_management_panel.dart';

class AcademicAccountManagementView extends StatelessWidget {
  const AcademicAccountManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Account Management',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage Program Chair, Teacher, and Student accounts',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Main Content
              const Expanded(
                child: AcademicAccountManagementPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
