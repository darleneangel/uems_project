import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class GradesManagementPanel extends StatefulWidget {
  final bool isDarkMode;
  const GradesManagementPanel({super.key, required this.isDarkMode});

  @override
  State<GradesManagementPanel> createState() => _GradesManagementPanelState();
}

class _GradesManagementPanelState extends State<GradesManagementPanel> {
  String? _selectedStudentId;
  final TextEditingController _searchController = TextEditingController();

  // Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);

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
        Expanded(
          child: _selectedStudentId == null
              ? _buildCloudStudentList(cardColor, textColor, subTextColor)
              : _buildLiveGradeView(cardColor, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scholastic Records Hub",
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
            Text(
                "Audit grade distribution, compute institutional GWAs, and verify transcripts.",
                style: TextStyle(color: subTextColor, fontSize: 13)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.fileText, size: 16),
          label: const Text("GENERATE TRANSCRIPT"),
          style: ElevatedButton.styleFrom(
              backgroundColor: aViolet,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      ],
    );
  }

  Widget _buildCloudStudentList(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Lookup Student for Grade Audit...",
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService()
                  .client
                  .from('profiles')
                  .stream(primaryKey: ['id']).eq('role', 'student'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: aViolet));
                }
                final list = snapshot.data!
                    .where((s) =>
                        s['user_id_number']
                            .toString()
                            .contains(_searchController.text) ||
                        s['fn']
                            .toString()
                            .toUpperCase()
                            .contains(_searchController.text.toUpperCase()))
                    .toList();

                if (list.isEmpty) {
                  return Center(
                      child: Text("No students found in cloud.",
                          style: TextStyle(color: subTextColor)));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final student = list[i];
                    return ListTile(
                      onTap: () =>
                          setState(() => _selectedStudentId = student['id']),
                      leading: CircleAvatar(
                          backgroundColor: aViolet.withOpacity(0.1),
                          child: const Icon(LucideIcons.star,
                              size: 16, color: aViolet)),
                      title: Text("${student['fn']} ${student['ln']}",
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${student['user_id_number']}",
                          style: TextStyle(color: subTextColor, fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight,
                          size: 16, color: Colors.white24),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLiveGradeView(
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: textColor),
                  onPressed: () => setState(() => _selectedStudentId = null)),
              const SizedBox(width: 8),
              Text("Detailed Academic Roster",
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const Spacer(),
              _statBadge("CLOUD SYNC ACTIVE", success),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // JOIN: grades -> study_loads -> subjects
              future: SupabaseService()
                  .client
                  .from('grades')
                  .select('''
                midterm_grade, final_grade, final_numeric_grade, status,
                study_loads!inner (
                  student_id,
                  subjects (code, name)
                )
              ''')
                  .eq('study_loads.student_id', _selectedStudentId!)
                  .then((res) => List<Map<String, dynamic>>.from(res)),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grades = snapshot.data!;

                if (grades.isEmpty) {
                  return Center(
                      child: Text("No grades encoded for this student.",
                          style: TextStyle(color: subTextColor)));
                }

                return Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(1)
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.white10))),
                      children: [
                        _tableHead("CODE"),
                        _tableHead("SUBJECT"),
                        _tableHead("GRADE")
                      ],
                    ),
                    ...grades.map((g) {
                      final s = g['study_loads']?['subjects'];
                      return TableRow(
                        children: [
                          _tableCell(s?['code'] ?? 'N/A', textColor),
                          _tableCell(
                              s?['name'] ?? 'Unknown Subject', textColor),
                          _tableCell(g['final_grade'] ?? '-', aViolet,
                              isBold: true),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _tableHead(String text) => Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text,
          style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.bold)));
  Widget _tableCell(String text, Color c, {bool isBold = false}) => Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text,
          style: TextStyle(
              color: c,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal)));
  Widget _statBadge(String text, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text(text,
          style: GoogleFonts.inter(
              color: c, fontSize: 10, fontWeight: FontWeight.w900)));
}
