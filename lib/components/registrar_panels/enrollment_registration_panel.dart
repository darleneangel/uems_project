import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class EnrollmentRegistrationPanel extends StatefulWidget {
  final bool isDarkMode;
  const EnrollmentRegistrationPanel({super.key, required this.isDarkMode});

  @override
  State<EnrollmentRegistrationPanel> createState() =>
      _EnrollmentRegistrationPanelState();
}

class _EnrollmentRegistrationPanelState
    extends State<EnrollmentRegistrationPanel> {
  bool _isProcessing = false;

  // Standardized Tonal Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

  /// DATABASE ACTION: Finalizes enrollment by updating status
  Future<void> _approveEnrollment(String profileId, String name) async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService().client.from('student_details').update(
          {'enrollment_status': 'Enrolled'}).eq('profile_id', profileId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: success,
              content: Text("Student $name officially Enrolled.")),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Approval Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(textColor, subTextColor),
        const SizedBox(height: 24),
        if (_isProcessing)
          const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(color: aViolet)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Live Approval Queue from Supabase
              Expanded(
                flex: 6,
                child: _buildQueueList(cardColor, textColor, subTextColor),
              ),
              const SizedBox(width: 20),
              // Right Side: Quick Actions & Stats
              Expanded(
                flex: 4,
                child:
                    _buildEnrollmentStats(cardColor, textColor, subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Registration Validation Hub",
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
        Text(
            "Confirm block assignments and finalize official enrollment for cleared students.",
            style: TextStyle(color: subTextColor, fontSize: 13)),
      ],
    );
  }

  Widget _buildQueueList(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Registration Approval Queue",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // FETCH: Students who are 'Unenrolled' (Cleard by Admission/Accounting)
              stream: SupabaseService()
                  .client
                  .from('student_details')
                  .stream(primaryKey: ['profile_id']).eq(
                      'enrollment_status', 'Unenrolled'),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                final list = snapshot.data!;

                if (list.isEmpty)
                  return Center(
                      child: Text("No pending registrations.",
                          style: TextStyle(color: subTextColor)));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final student = list[index];
                    return _queueTile(student, textColor, subTextColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueTile(
      Map<String, dynamic> item, Color textColor, Color subTextColor) {
    return FutureBuilder(
      // Joining profile data to get the name
      future: SupabaseService()
          .client
          .from('profiles')
          .select('fn, ln, user_id_number')
          .eq('id', item['profile_id'])
          .single(),
      builder: (context, snap) {
        final String name = snap.hasData
            ? "${snap.data!['fn']} ${snap.data!['ln']}"
            : "Loading Identity...";
        final String idNum =
            snap.hasData ? snap.data!['user_id_number'] : "...";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: aViolet.withOpacity(0.1),
                  child:
                      const Icon(LucideIcons.user, size: 16, color: aViolet)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.bold)),
                    Text("$idNum • ${item['section_block'] ?? 'NO BLOCK'}",
                        style: TextStyle(color: subTextColor, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _approveEnrollment(item['profile_id'], name),
                style: ElevatedButton.styleFrom(
                    backgroundColor: success.withOpacity(0.1),
                    foregroundColor: success,
                    elevation: 0),
                child: const Text("FINALIZE",
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentStats(
      Color cardColor, Color textColor, Color subTextColor) {
    return Column(
      children: [
        _actionCard("GENERATE CLASS ROSTER", LucideIcons.users, aViolet,
            cardColor, textColor),
        const SizedBox(height: 16),
        _actionCard("ADD/DROP WORKFLOW", LucideIcons.gitPullRequest,
            Colors.orangeAccent, cardColor, textColor),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10)),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService()
                .client
                .from('student_details')
                .stream(primaryKey: ['profile_id']),
            builder: (context, snapshot) {
              int total = snapshot.hasData
                  ? snapshot.data!
                      .where((s) => s['enrollment_status'] == 'Enrolled')
                      .length
                  : 0;
              int pending = snapshot.hasData
                  ? snapshot.data!
                      .where((s) => s['enrollment_status'] == 'Unenrolled')
                      .length
                  : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Global Statistics",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 20),
                  _statRow("Total Enrolled", total.toString(), success),
                  _statRow("Pending Validation", pending.toString(),
                      Colors.orangeAccent),
                  _statRow("Dropped/Withdrawn", "0", textColor),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
      String label, IconData icon, Color color, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(label,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
