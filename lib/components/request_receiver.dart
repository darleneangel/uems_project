import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/office_request_service.dart';

class RequestReceiver extends StatefulWidget {
  const RequestReceiver({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<RequestReceiver> createState() => _RequestReceiverState();
}

class _RequestReceiverState extends State<RequestReceiver> {
  final OfficeRequestService _service = OfficeRequestService();
  String _selectedOfficeFilter = 'all';

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFB74D);
  static const Color pViolet = Color(0xFF2E1065);
  static const Color lCard = Color(0xFFFFFFFF);
  
  late bool _isDarkMode;

  static const Map<String, Map<String, dynamic>> officeInfo = {
    'admissions': {
      'name': 'Admissions',
      'icon': LucideIcons.userPlus,
      'color': Color(0xFF42A5F5),
    },
    'registrar': {
      'name': 'Registrar',
      'icon': LucideIcons.users,
      'color': Color(0xFF66BB6A),
    },
    'accounting': {
      'name': 'Accounting',
      'icon': LucideIcons.wallet,
      'color': Color(0xFFFFA726),
    },
  };

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _seedDemoRequests();
  }

  void _seedDemoRequests() {
    // Demo data is automatically seeded when OfficeRequestService is instantiated
    // No need to call _seedDemoData() here as it's private
  }

  List<OfficeRequest> _getFilteredRequests(List<OfficeRequest> allRequests) {
    // Show only pending requests (not approved, rejected, or archived)
    List<OfficeRequest> pending =
        allRequests.where((r) => r.status == 'pending').toList();

    if (_selectedOfficeFilter == 'all') {
      return pending;
    }
    return pending.where((r) => r.office == _selectedOfficeFilter).toList();
  }

  void _approveRequest(int id) {
    _service.approve(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Request approved'),
        backgroundColor: success,
      ),
    );
  }

  void _rejectRequest(int id) {
    _service.reject(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Request rejected'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showRequestDetails(OfficeRequest request) {
    // Theme-aware colors for dialogs
    final dialogBgColor = _isDarkMode ? surfaceDark : lCard;
    final dialogTextColor = _isDarkMode ? Colors.white : pViolet;
    final dialogSubTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          '${officeInfo[request.office]?['name'] ?? request.office} - ${request.requestType}',
          style: GoogleFonts.inter(
            color: dialogTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display different content based on whether this is an announcement
              if (request.isAnnouncement) ...[
                // Announcement Format
                Text(
                  'Office:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  officeInfo[request.office]?['name'] ?? request.office,
                  style: GoogleFonts.inter(color: dialogTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Department:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.department ?? 'N/A',
                  style: GoogleFonts.inter(color: dialogTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(request.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.priority ?? 'N/A',
                    style: GoogleFonts.inter(
                      color: _getPriorityColor(request.priority),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Target Audience:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.targetAudience ?? 'N/A',
                  style: GoogleFonts.inter(color: dialogTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Proposed Announcement:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? aViolet.withOpacity(0.08) : pViolet.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isDarkMode ? aViolet.withOpacity(0.2) : pViolet.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    request.proposedAnnouncement?.isNotEmpty == true
                        ? request.proposedAnnouncement!
                        : (request.details.isNotEmpty
                            ? request.details
                            : 'No announcement content'),
                    style: GoogleFonts.inter(color: dialogSubTextColor, fontSize: 13, height: 1.5),
                  ),
                ),
              ] else ...[
                // Regular Request Format
                Text(
                  'Office:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  officeInfo[request.office]?['name'] ?? request.office,
                  style: GoogleFonts.inter(color: dialogTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Request Type:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.requestType,
                  style: GoogleFonts.inter(color: dialogTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Details:',
                  style: GoogleFonts.inter(
                    color: dialogSubTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.details.isNotEmpty
                      ? request.details
                      : 'No additional details',
                  style: GoogleFonts.inter(color: dialogSubTextColor, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Submitted:',
                style: GoogleFonts.inter(
                  color: dialogSubTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(request.createdAt),
                style: GoogleFonts.inter(color: _isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: dialogSubTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _rejectRequest(request.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _approveRequest(request.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success,
            ),
            child: Text(
              'Approve',
              style: GoogleFonts.inter(
                color: surfaceDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF5350); // Red
      case 'high':
        return const Color(0xFFFF9800); // Orange
      case 'medium':
        return const Color(0xFFFFD54F); // Yellow
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.blueGrey;
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;
    final fillColor = Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter by Office
        Text(
          'Filter by Office',
          style: GoogleFonts.inter(
            color: subTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOfficeFilter = 'all'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedOfficeFilter == 'all'
                          ? (_isDarkMode ? aViolet.withOpacity(0.3) : pViolet.withValues(alpha:0.15))
                          : (_isDarkMode ? aViolet.withOpacity(0.04) : Colors.grey.shade100),
                      border: Border.all(
                        color: _selectedOfficeFilter == 'all'
                            ? (_isDarkMode ? aViolet : pViolet)
                            : (_isDarkMode ? aViolet.withOpacity(0.12) : Colors.grey.shade300),
                        width: _selectedOfficeFilter == 'all' ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'All Offices',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: _selectedOfficeFilter == 'all'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedOfficeFilter == 'all'
                            ? (_isDarkMode ? Colors.white : pViolet)
                            : subTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              ...officeInfo.entries.map((entry) {
                final key = entry.key;
                final info = entry.value;
                final isSelected = _selectedOfficeFilter == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOfficeFilter = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? info['color'].withOpacity(0.2)
                            : (_isDarkMode ? aViolet.withOpacity(0.04) : Colors.grey.shade100),
                        border: Border.all(
                          color: isSelected 
                              ? info['color'] 
                              : (_isDarkMode ? aViolet.withOpacity(0.12) : Colors.grey.shade300),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            info['icon'],
                            size: 16,
                            color: isSelected
                                ? info['color']
                                : subTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            info['name'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? info['color']
                                  : subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Requests List
        ValueListenableBuilder<List<OfficeRequest>>(
          valueListenable: OfficeRequestService.notifier,
          builder: (context, allRequests, _) {
            final filtered = _getFilteredRequests(allRequests);

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _isDarkMode ? aViolet.withOpacity(0.02) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDarkMode ? aViolet.withOpacity(0.08) : Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.inbox,
                        size: 48,
                        color: _isDarkMode ? Colors.white30 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: GoogleFonts.inter(
                          color: subTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All requests have been reviewed',
                        style: GoogleFonts.inter(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = filtered[index];
                final info = officeInfo[request.office];
                final color = info?['color'] ?? Colors.white60;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isDarkMode ? aViolet.withOpacity(0.08) : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              info?['icon'] ?? LucideIcons.building2,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info?['name'] ?? request.office,
                                  style: GoogleFonts.inter(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request.requestType,
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pending',
                              style: GoogleFonts.inter(
                                color: warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                        if (request.details.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.details,
                            style: GoogleFonts.inter(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(request.createdAt),
                            style: GoogleFonts.inter(
                              color: _isDarkMode ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _rejectRequest(request.id),
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                            ),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _approveRequest(request.id),
                            icon: const Icon(
                              LucideIcons.check,
                              size: 16,
                            ),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: success,
                              foregroundColor: surfaceDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showRequestDetails(request),
                            icon: const Icon(
                              LucideIcons.eye,
                              size: 16,
                            ),
                            label: const Text('Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDarkMode ? aViolet : pViolet,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
