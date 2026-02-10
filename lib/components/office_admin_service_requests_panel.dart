import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/announcement_service.dart';

class OfficeAdminServiceRequestsPanel extends StatefulWidget {
  const OfficeAdminServiceRequestsPanel({super.key});

  @override
  State<OfficeAdminServiceRequestsPanel> createState() =>
      _OfficeAdminServiceRequestsPanelState();
}

class _OfficeAdminServiceRequestsPanelState
    extends State<OfficeAdminServiceRequestsPanel> {
  late AnnouncementService _service;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _service = AnnouncementService();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F071D);
    const bgCard = Color(0xFF1E1033);

    return Scaffold(
      backgroundColor: bgDark,
      body: Column(
        children: [
          // Header + Filters
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Office Admin - Service Requests',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('all', 'All'),
                    _filterChip('admissions', 'Admissions'),
                    _filterChip('registrar', 'Registrar'),
                    _filterChip('accounting', 'Accounting'),
                  ],
                ),
              ],
            ),
          ),
          // List of announcements
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _service.notifier,
              builder: (context, announcements, _) {
                final items = _filter == 'all'
                    ? announcements
                    : announcements.where((a) => a.office == _filter).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No announcements found',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: items.length,
                  itemBuilder: (context, idx) => _card(items[idx], bgCard),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String val, String label) {
    final isActive = _filter == val;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => setState(() => _filter = val),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: GoogleFonts.inter(
        color: isActive ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isActive ? const Color(0xFF8B5CF6) : Colors.white30,
      ),
    );
  }

  Widget _card(Announcement a, Color bgCard) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(a.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _statusColor(a.status)),
                ),
                child: Text(
                  a.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(a.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Metadata
          if (a.department != null || a.priority != null)
            Wrap(
              spacing: 16,
              children: [
                if (a.department != null)
                  Text(
                    'Dept: ${a.department}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
                if (a.priority != null)
                  Text(
                    'Priority: ${a.priority}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
              ],
            ),
          if (a.department != null || a.priority != null) const SizedBox(height: 8),
          // Content preview
          Text(
            a.content.length > 100
                ? '${a.content.substring(0, 100)}...'
                : a.content,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (a.status == 'pending') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    _service.reject(a.id);
                    setState(() {});
                  },
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _service.approve(a.id);
                    setState(() {});
                  },
                  icon: const Icon(LucideIcons.check, size: 14),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showDetail(a),
                icon: const Icon(LucideIcons.eye, size: 14),
                label: const Text('View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(Announcement a) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(a.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText('Office: ${_officeLabel(a.office)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (a.department != null)
                SelectableText('Department: ${a.department}'),
              if (a.priority != null)
                SelectableText('Priority: ${a.priority}'),
              if (a.targetAudience != null)
                SelectableText('Audience: ${a.targetAudience}'),
              const SizedBox(height: 12),
              const SelectableText('Content:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(a.content),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _officeLabel(String office) {
    switch (office) {
      case 'admissions':
        return 'Admissions';
      case 'registrar':
        return 'Registrar';
      case 'accounting':
        return 'Accounting';
      default:
        return 'Unknown';
    }
  }
}
