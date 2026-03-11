import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class RegistrarOverviewPanel extends StatelessWidget {
  final bool isDarkMode;
  const RegistrarOverviewPanel({super.key, required this.isDarkMode});

  // Standardized Tonal Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = isDarkMode ? surfaceDark : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registrar Intelligence Overview",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // REAL-TIME ANALYTICS ROW
          Row(
            children: [
              // 1. Live Active Student Counter
              _buildLiveStatCard(
                label: "Active Students",
                icon: LucideIcons.users,
                color: aViolet,
                cardBg: cardColor,
                text: textColor,
                stream: SupabaseService()
                    .client
                    .from('student_details')
                    .stream(primaryKey: ['profile_id']).eq(
                        'enrollment_status', 'Enrolled'),
              ),

              // 2. Pending Transitions (Derived from 4th Year Students)
              _buildLiveStatCard(
                label: "Graduation Track",
                icon: LucideIcons.graduationCap,
                color: success,
                cardBg: cardColor,
                text: textColor,
                stream: SupabaseService().client.from('student_details').stream(
                    primaryKey: ['profile_id']).eq('year_level_id', '4th Year'),
              ),

              // 3. Live Document Requests queue
              _buildLiveStatCard(
                label: "Requests Pending",
                icon: LucideIcons.fileText,
                color: Colors.orangeAccent,
                cardBg: cardColor,
                text: textColor,
                stream: SupabaseService().client.from('office_requests').stream(
                    primaryKey: ['id']).eq('request_status', 'Submitted'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildActivityPlaceholder(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildLiveStatCard({
    required String label,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color text,
    required Stream<List<Map<String, dynamic>>> stream,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                String count =
                    snapshot.hasData ? snapshot.data!.length.toString() : "0";
                return Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                );
              },
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPlaceholder(Color cardBg, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.activity,
                color: aViolet.withOpacity(0.2), size: 48),
            const SizedBox(height: 16),
            Text(
              "Institutional Audit Sync: Active",
              style: TextStyle(
                  color: text.withOpacity(0.4), fontWeight: FontWeight.bold),
            ),
            Text(
              "Administrative modifications are logged in real-time.",
              style: TextStyle(color: text.withOpacity(0.2), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
