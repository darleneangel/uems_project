import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/supabase_service.dart';

class CurriculumCatalogPanel extends StatefulWidget {
  final bool isDarkMode;
  const CurriculumCatalogPanel({super.key, required this.isDarkMode});

  @override
  State<CurriculumCatalogPanel> createState() => _CurriculumCatalogPanelState();
}

class _CurriculumCatalogPanelState extends State<CurriculumCatalogPanel> {
  String? _selectedCourseId;
  String _selectedProgramName = "Institutional Catalog";
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingPrograms = true;

  // Theme Palette
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF69F0AE);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color surfaceLight = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  /// DATABASE: Fetches available programs from the 'courses' table
  Future<void> _fetchPrograms() async {
    setState(() => _isLoadingPrograms = true);
    try {
      final data = await SupabaseService()
          .client
          .from('courses')
          .select('id, name, code');
      if (mounted) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(data);
          _isLoadingPrograms = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPrograms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(textColor, subTextColor),
        const SizedBox(height: 24),

        // Dynamic Program Filter Bar
        if (_isLoadingPrograms)
          const LinearProgressIndicator(color: aViolet)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _programFilter("All Subjects", null),
                ..._courses.map((course) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _programFilter(course['name'], course['id']),
                    )),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // Live Subject Catalog Stream
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService()
                .client
                .from('subjects')
                .stream(primaryKey: ['id']).order('code', ascending: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: aViolet));
              }

              final subjects = snapshot.data!;
              if (subjects.isEmpty) {
                return _buildEmptyState(subTextColor);
              }

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCatalogSection(_selectedProgramName, subjects,
                      cardColor, textColor, subTextColor),
                ],
              );
            },
          ),
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
            Text(
              "Curriculum & Course Catalog",
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
            ),
            Text(
              "Verified institutional subject offerings and credit mapping.",
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text("PROVISION SUBJECT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: aViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _programFilter(String title, String? id) {
    bool isSelected = _selectedCourseId == id;
    return InkWell(
      onTap: () => setState(() {
        _selectedCourseId = id;
        _selectedProgramName = title;
      }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? aViolet : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: aViolet.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCatalogSection(String title, List<Map<String, dynamic>> subjects,
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.library, color: aViolet, size: 20),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: aViolet,
                    letterSpacing: 1,
                    fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 48, color: Colors.white10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(4),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: subTextColor.withOpacity(0.1)))),
                children: [
                  _tableHead("CODE"),
                  _tableHead("SUBJECT TITLE"),
                  _tableHead("UNITS"),
                  _tableHead("CLASSIFICATION"),
                ],
              ),
              ...subjects
                  .map((s) => TableRow(
                        children: [
                          _tableCell(s['code'], aViolet, isBold: true),
                          _tableCell(s['name'], textColor),
                          _tableCell("${s['units']}.0", textColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _classificationBadge(
                                s['is_professional_course'] ?? true),
                          ),
                        ],
                      ))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHead(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: GoogleFonts.inter(
              color: Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5),
        ),
      );

  Widget _tableCell(String text, Color c, {bool isBold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(text,
            style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      );

  Widget _classificationBadge(bool isMajor) {
    final color = isMajor ? aViolet : success;
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          isMajor ? "MAJOR" : "GEN-ED",
          style:
              TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookX,
              color: subTextColor.withOpacity(0.1), size: 64),
          const SizedBox(height: 16),
          Text("Institutional catalog is currently unpopulated.",
              style: TextStyle(color: subTextColor)),
        ],
      ),
    );
  }
}
