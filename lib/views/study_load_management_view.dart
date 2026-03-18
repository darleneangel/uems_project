import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudyLoadManagementView extends StatefulWidget {
  const StudyLoadManagementView({super.key});

  @override
  State<StudyLoadManagementView> createState() => _StudyLoadManagementViewState();
}

class _StudyLoadManagementViewState extends State<StudyLoadManagementView> {
  // Theme Constants (Unified with your project)
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color tDark = Color(0xFF0F071D);

  // State Management
  String _viewMode = 'Individual'; // 'Individual' or 'Section'
  String? _selectedId;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  // Mock Data derived from your records
  final List<Map<String, String>> _students = [
    {'studentId': '2025-001', 'name': 'James Mitchell', 'program': 'BSCS', 'year': '4th Year', 'section': 'A'},
    {'studentId': '2025-002', 'name': 'Sarah Johnson', 'program': 'BSIT', 'year': '3rd Year', 'section': 'B'},
    {'studentId': '2025-003', 'name': 'Michael Chen', 'program': 'BSBA', 'year': '2nd Year', 'section': 'A'},
  ];

  // Mock Subjects Data
  final List<Map<String, String>> _subjects = [
    {'code': 'CS101', 'name': 'Introduction to Computing', 'units': '3'},
    {'code': 'CS102', 'name': 'Programming Fundamentals', 'units': '4'},
    {'code': 'MATH101', 'name': 'Calculus I', 'units': '3'},
    {'code': 'ENG101', 'name': 'English Composition', 'units': '2'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SIDEBAR: Search & Selection
                Expanded(flex: 1, child: _buildSelectionSidebar()),
                const SizedBox(width: 24),
                // MAIN CONTENT: Study Load Editor
                Expanded(flex: 3, child: _buildLoadEditor()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Study Load Management",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Enroll subjects and manage academic loads",
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        // Toggle Switch for View Mode
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: surfaceDark, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _modeButton('Individual', LucideIcons.user),
              _modeButton('Section', LucideIcons.users),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String mode, IconData icon) {
    bool isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? aViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white54),
            const SizedBox(width: 8),
            Text(mode, style: GoogleFonts.inter(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSidebar() {
    final filteredList = _students.where((s) => 
      s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      s['studentId']!.contains(_searchQuery)
    ).toList();

    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _viewMode == 'Individual' ? "Search Name/ID..." : "Search Section...",
            prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
            filled: true,
            fillColor: surfaceDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final item = filteredList[index];
              bool isSelected = _selectedId == item['studentId'];
              return ListTile(
                onTap: () => setState(() => _selectedId = item['studentId']),
                selected: isSelected,
                selectedTileColor: aViolet.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                title: Text(item['name']!, style: const TextStyle(color: Colors.white)),
                subtitle: Text("${item['program']} - ${item['year']}", style: const TextStyle(color: Colors.white54)),
                trailing: isSelected ? const Icon(LucideIcons.checkCircle2, color: aViolet, size: 18) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadEditor() {
    if (_selectedId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.mousePointer2, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text("Select a ${_viewMode.toLowerCase()} to manage study load", style: const TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Card(
      color: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Study Load: $_selectedId", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  onPressed: () => _showAddSubjectModal(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text("Add Subject"),
                  style: ElevatedButton.styleFrom(backgroundColor: aViolet, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Scrollable Table of Subjects
          Expanded(child: _buildSubjectTable()),
        ],
      ),
    );
  }

  Widget _buildSubjectTable() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        if (index >= _subjects.length) return const SizedBox.shrink();
        final subject = _subjects[index];
        return _subjectCard(
          subject['code']!,
          subject['name']!,
          subject['units']!,
          Colors.white,
        );
      },
    );
  }

  Widget _subjectCard(String code, String name, String units, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: aViolet,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                onPressed: () {
                  // Handle delete
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            "$units Units",
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectModal() {
    // This logic can now reference course_catalog_view.dart
    showModalBottomSheet(
      context: context,
      backgroundColor: tDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Select Subject from Catalog", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: const [ /* List courses from course_catalog_view.dart */ ])),
          ],
        ),
      ),
    );
  }
}