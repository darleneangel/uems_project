import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class AdmissionOverviewPanel extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const AdmissionOverviewPanel(
      {super.key, required this.isDarkMode, required this.userData});

  @override
  State<AdmissionOverviewPanel> createState() => _AdmissionOverviewPanelState();
}

class _AdmissionOverviewPanelState extends State<AdmissionOverviewPanel> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentApplicants = [];

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.client
          .from('applicants')
          .select('*, courses(code, name)')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _recentApplicants = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Overview Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: aViolet));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Active Intake Feed",
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10)),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _recentApplicants.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, i) {
                final app = _recentApplicants[i];
                final status = app['status'] ?? "Pending";
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: aViolet.withOpacity(0.1),
                      child: const Icon(LucideIcons.user,
                          color: aViolet, size: 18)),
                  title: Text(app['full_name'],
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${app['application_no']} • ${app['courses']?['code'] ?? 'GEN'}",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 12)),
                  trailing: _statusBadge(status),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String s) {
    Color c = s == "Verified"
        ? success
        : (s == "Rejected" ? Colors.redAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
