import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class RequestReceiver extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> userData; // Required as per system architecture

  const RequestReceiver({
    super.key,
    this.isDarkMode = true,
    required this.userData,
  });

  @override
  State<RequestReceiver> createState() => _RequestReceiverState();
}

class _RequestReceiverState extends State<RequestReceiver> {
  final SupabaseService _service = SupabaseService();
  String _selectedOfficeFilter = 'all';

  // Institutional Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);
  static const Color pViolet = Color(0xFF2E1065);

  // Office Metadata Mapping (Syncs request types to departments)
  static const Map<String, Map<String, dynamic>> officeInfo = {
    'admissions': {
      'name': 'Admissions',
      'icon': LucideIcons.userPlus,
      'color': Color(0xFF42A5F5),
      'types': ['Registration Fee', 'Document Submission', 'Entrance Exam']
    },
    'registrar': {
      'name': 'Registrar',
      'icon': LucideIcons.bookOpen,
      'color': Color(0xFF66BB6A),
      'types': [
        'Transcript of Records',
        'Certification of Grades',
        'Certificate of Good Moral',
        'Official Document'
      ]
    },
    'accounting': {
      'name': 'Accounting',
      'icon': LucideIcons.wallet,
      'color': Color(0xFFFFA726),
      'types': ['Financial Clearance', 'Promissory Note', 'Tuition Payment']
    },
  };

  /// 🛰️ DATABASE: Approves the institutional request and stamps the admin's ID
  Future<void> _processRequest(String id, String status) async {
    try {
      await _service.client.from('office_requests').update({
        'request_status': status,
        'processed_at': DateTime.now().toIso8601String(),
        'processed_by': widget.userData['id'], // Audit trail link
      }).eq('id', id);

      _showToast("Institutional status updated to $status",
          status == 'Approved' ? success : Colors.redAccent);
    } catch (e) {
      _showToast(
          "Ledger Update Failed: Connection Interrupted", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.blueGrey;

    // FIX: mainAxisSize.max is now enabled because the Dashboard provides bounded height.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildFilterBar(subTextColor),
        const SizedBox(height: 32),

        // DYNAMIC DATA STREAM
        // FIX: Wrapped in Expanded to utilize bounded height and prevent RenderFlex overflow.
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.client.from('office_requests').stream(
                primaryKey: ['id']).order('date_applied', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(subTextColor,
                    "Institutional Sync Error: Ledger unreachable.");
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: aViolet));
              }

              final rawData = snapshot.data ?? [];

              // 📐 FILTER ENGINE: Logic verified for cross-office audit
              final filtered = rawData.where((req) {
                if (req == null) return false;

                final status =
                    (req['request_status'] ?? req['status'] ?? '').toString();

                // Finalized items are moved to archives/history
                if (status == 'Approved' ||
                    status == 'Rejected' ||
                    status == 'Released' ||
                    status == 'Archived') return false;

                if (_selectedOfficeFilter == 'all') return true;

                final String type = (req['request_type'] ?? '').toString();
                final List<String> officeTypes = List<String>.from(
                    officeInfo[_selectedOfficeFilter]?['types'] ?? []);
                return officeTypes.contains(type);
              }).toList();

              if (filtered.isEmpty) return _buildEmptyState(subTextColor);

              // FIX: shrinkWrap: false and default scroll physics enabled.
              // This allows the list to scroll independently within the panel.
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                padding: const EdgeInsets.only(bottom: 40),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _buildRequestCard(
                    filtered[i], cardColor, textColor, subTextColor),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("OFFICE QUEUE SELECTION",
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: sub,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'Universal Feed', LucideIcons.layers, aViolet),
              const SizedBox(width: 8),
              ...officeInfo.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChip(e.key, e.value['name'], e.value['icon'],
                        e.value['color']),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String id, String label, IconData icon, Color color) {
    bool isSelected = _selectedOfficeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOfficeFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 10),
            Text(label.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : color,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
      Map<String, dynamic> req, Color bg, Color text, Color sub) {
    final String type = (req['request_type'] ?? 'Service Ticket').toString();
    final String hash = (req['qr_hash'] ?? 'LRD-TX-PENDING').toString();

    String date = "Pending Audit";
    if (req['date_applied'] != null) {
      try {
        date = DateFormat('MMMM dd, hh:mm a')
            .format(DateTime.parse(req['date_applied'].toString()));
      } catch (e) {
        date = "Invalid Date";
      }
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: widget.isDarkMode
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  // FIX: Robust null guard for req['student_id'] and id string conversion
                  future: (req['student_id'] == null)
                      ? Future.value(null)
                      : _service.client
                          .from('profiles')
                          .select('fn, ln, user_id_number')
                          .eq('id', req['student_id'].toString())
                          .maybeSingle(),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final String firstName =
                        (profile?['fn'] ?? 'TBA').toString();
                    final String lastName = (profile?['ln'] ?? '').toString();
                    final String name = profile != null
                        ? "$firstName $lastName"
                        : "Identifying Applicant...";
                    final String lrd =
                        profile?['user_id_number']?.toString() ?? "ID-PENDING";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                color: text,
                                fontSize: 16,
                                letterSpacing: -0.2)),
                        Text("LRD-ID: $lrd • Submitted: $date",
                            style: TextStyle(
                                color: sub,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    );
                  },
                ),
              ),
              _statusChip("Pending Processing", Colors.orangeAccent),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),
          Row(
            children: [
              _infoBlock("REQUEST CATEGORY", type, aViolet),
              _infoBlock(
                  "AUTHENTICATION HASH",
                  hash.length > 20 ? "${hash.substring(0, 18)}..." : hash,
                  Colors.blueGrey),
              const Spacer(),
              _actionBtn(LucideIcons.x, "REJECT", Colors.redAccent,
                  () => _processRequest(req['id'].toString(), 'Rejected')),
              const SizedBox(width: 12),
              _actionBtn(LucideIcons.check, "APPROVE", success,
                  () => _processRequest(req['id'].toString(), 'Approved')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String l, String v, Color c) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l,
                style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(v,
                style: GoogleFonts.inter(
                    color: c, fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _actionBtn(IconData i, String l, Color c, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(i, size: 14),
        label: Text(l,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.withOpacity(0.1),
          foregroundColor: c,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.withOpacity(0.2))),
        ),
      );

  Widget _statusChip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                color: c,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      );

  Widget _buildEmptyState(Color sub) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle),
                child: Icon(LucideIcons.clipboardCheck,
                    size: 48, color: sub.withOpacity(0.2)),
              ),
              const SizedBox(height: 24),
              Text("Institutional Queue Clear",
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sub.withOpacity(0.5))),
              const SizedBox(height: 4),
              const Text("All incoming service requests have been audited.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildErrorState(Color sub, String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const Icon(LucideIcons.alertTriangle,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text(msg,
                  style: TextStyle(color: sub, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  void _showToast(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }
}
