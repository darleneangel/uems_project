import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uems_project/views/dashboard_view.dart';
import 'dart:ui';

class HealthDeclarationView extends StatefulWidget {
  const HealthDeclarationView({super.key});

  @override
  State<HealthDeclarationView> createState() => _HealthDeclarationViewState();
}

class _HealthDeclarationViewState extends State<HealthDeclarationView> {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  bool hasSymptoms = false;
  bool isVaccinated = true;
  bool agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tertiaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Health Declaration',
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
                "Health Declaration Form",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please complete your health declaration form",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              
              // Symptoms Question
              _buildCheckboxCard(
                "Do you have any COVID-19 symptoms?",
                hasSymptoms,
                (value) => setState(() => hasSymptoms = value ?? false),
              ),
              const SizedBox(height: 12),
              
              // Vaccination Question
              _buildCheckboxCard(
                "Are you fully vaccinated?",
                isVaccinated,
                (value) => setState(() => isVaccinated = value ?? false),
              ),
              const SizedBox(height: 12),
              
              // Terms Agreement
              _buildCheckboxCard(
                "I agree to the health declaration terms",
                agreeTerms,
                (value) => setState(() => agreeTerms = value ?? false),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: agreeTerms
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Health declaration submitted successfully!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: successColor,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(LucideIcons.send, size: 18),
                  label: const Text("Submit Declaration"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: agreeTerms ? successColor : Colors.grey.shade600,
                    foregroundColor: primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxCard(String label, bool value, Function(bool?) onChanged) {
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
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: successColor,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
