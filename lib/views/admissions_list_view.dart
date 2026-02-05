import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdmissionsListView extends StatelessWidget {
  final String filter; // 'all', 'pending', 'approved', 'rejected'

  const AdmissionsListView({super.key, required this.filter});

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color success = Color(0xFF69F0AE);

  List<Map<String, String>> _students() {
    final all = [
      {'name': 'Alice Santos', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Ben Delacruz', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Carla Reyes', 'status': 'rejected', 'program': 'BSBA'},
      {'name': 'Daniel Cruz', 'status': 'approved', 'program': 'BSCS'},
      {'name': 'Eve Navarro', 'status': 'pending', 'program': 'BSIT'},
      {'name': 'Francis Lopez', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Gina Morales', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Hector Ramos', 'status': 'rejected', 'program': 'BSEd'},
      {'name': 'Ivy Santos', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Jill Tan', 'status': 'approved', 'program': 'BSBA'},
      {'name': 'Karl Ong', 'status': 'pending', 'program': 'BSCS'},
      {'name': 'Lara Medina', 'status': 'approved', 'program': 'BSIT'},
      {'name': 'Miguel Santos', 'status': 'pending', 'program': 'BSBA'},
      {'name': 'Nina Cruz', 'status': 'approved', 'program': 'BSCS'},
      {'name': 'Oscar Villar', 'status': 'rejected', 'program': 'BSIT'},
      {'name': 'Paula Gonzales', 'status': 'pending', 'program': 'BSEd'},
    ];

    if (filter == 'all') return all;
    return all.where((s) => s['status'] == filter).toList();
  }

  String _title() {
    switch (filter) {
      case 'pending':
        return 'Pending Applications';
      case 'approved':
        return 'Approved Applications';
      case 'rejected':
        return 'Rejected Applications';
      default:
        return 'All Applications';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return success;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Text(_title(), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      backgroundColor: const Color(0xFF0F0820),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white60),
                    onPressed: () async {
                      await showSearch(
                        context: context,
                        delegate: _ApplicationsSearchDelegate(students),
                      );
                    },
                    tooltip: 'Search applications',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Text('No applications', style: GoogleFonts.inter(color: Colors.white54)))
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final s = students[index];
                            final status = s['status'] ?? 'pending';
                            return InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: aViolet,
                                      child: Text(
                                        s['name']!.split(' ').first[0],
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['name']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(s['program']!, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _statusColor(status).withOpacity(0.25)),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: GoogleFonts.inter(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: Colors.white70),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: students.length,
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

class _ApplicationsSearchDelegate extends SearchDelegate<Map<String, String>?> {
  final List<Map<String, String>> applications;

  _ApplicationsSearchDelegate(this.applications);

  @override
  String? get searchFieldLabel => 'Search by name, program, or status';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = applications.where((app) {
      final q = query.toLowerCase();
      return app['name']!.toLowerCase().contains(q) ||
          app['program']!.toLowerCase().contains(q) ||
          app['status']!.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return Container(
        color: const Color(0xFF0F071D),
        child: Center(
          child: Text('No results',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 16,
              )),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0F071D),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final app = results[index];
          final status = app['status'] ?? 'pending';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(app['name']!.split(' ').first[0], style: GoogleFonts.inter(color: Colors.white)),
            ),
            title: Text(app['name']!,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${app['program']} • ${_statusColor(status)}',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            onTap: () => close(context, app),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? applications
        : applications.where((app) {
            final q = query.toLowerCase();
            return app['name']!.toLowerCase().contains(q) ||
                app['program']!.toLowerCase().contains(q) ||
                app['status']!.toLowerCase().contains(q);
          }).toList();

    return Container(
      color: const Color(0xFF0F071D),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final app = suggestions[index];
          final status = app['status'] ?? 'pending';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(app['name']!.split(' ').first[0],
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
            title: Text(app['name']!,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${app['program']} • ${_statusColor(status)}',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            onTap: () => query = app['name']!,
          );
        },
      ),
    );
  }

  String _statusColor(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}
