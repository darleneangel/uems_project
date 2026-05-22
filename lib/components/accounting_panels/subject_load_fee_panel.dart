import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubjectLoadFeePanel extends StatefulWidget {
  final bool isDarkMode;
  const SubjectLoadFeePanel({super.key, required this.isDarkMode});

  @override
  State<SubjectLoadFeePanel> createState() => _SubjectLoadFeePanelState();
}

class _SubjectLoadFeePanelState extends State<SubjectLoadFeePanel> {
  // Mock data for pending subject loads from Program Chair
  final List<Map<String, dynamic>> _pendingLoads = [
    {
      "id": "2024-00001",
      "name": "DARLENE ANGEL",
      "course": "BS Computer Science",
      "subjects": [
        {
          "code": "ITCC 411",
          "title": "Systems Integration & Architecture",
          "units": 3,
          "fee": 1550.0,
        },
        {
          "code": "ITCC 412",
          "title": "Information Assurance & Security",
          "units": 3,
          "fee": 1550.0,
        },
        {
          "code": "ITCP 413",
          "title": "Capstone Project 1",
          "units": 3,
          "fee": 1550.0,
        },
      ],
    },
    {
      "id": "2024-00042",
      "name": "JOHN DOE",
      "course": "BS Information Technology",
      "subjects": [
        {
          "code": "IT210",
          "title": "Advanced Database Systems",
          "units": 3,
          "fee": 1550.0,
        },
        {
          "code": "IT203",
          "title": "Quantitative Methods",
          "units": 3,
          "fee": 1550.0,
        },
      ],
    },
  ];

  int? _selectedStudentIndex;
  List<TextEditingController> _feeControllers = [];

  // Mock storage for saved templates
  final Map<String, List<double>> _savedTemplates = {
    "BSCS Standard Load": [1550.0, 1550.0, 1550.0],
  };

  @override
  void dispose() {
    for (var controller in _feeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStudentSelected(int index) {
    setState(() {
      _selectedStudentIndex = index;
      // Dispose old controllers
      for (var controller in _feeControllers) {
        controller.dispose();
      }
      // Initialize new controllers with current subject fees
      _feeControllers = List.generate(
        _pendingLoads[index]['subjects'].length,
        (i) => TextEditingController(
          text: _pendingLoads[index]['subjects'][i]['fee'].toString(),
        ),
      );
    });
  }

  void _saveAsTemplate() {
    if (_selectedStudentIndex == null) return;
    final student = _pendingLoads[_selectedStudentIndex!];
    final String templateName = "${student['course']} Template";

    setState(() {
      _savedTemplates[templateName] =
          _feeControllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Template '$templateName' saved successfully."),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  void _applyTemplate(String name) {
    final fees = _savedTemplates[name];
    if (fees == null) return;

    setState(() {
      for (int i = 0; i < _feeControllers.length; i++) {
        if (i < fees.length) {
          _feeControllers[i].text = fees[i].toString();
        }
      }
    });
  }

  void _bulkApplyTemplate(String name) {
    final fees = _savedTemplates[name];
    if (fees == null || _selectedStudentIndex == null) return;

    final targetCourse = _pendingLoads[_selectedStudentIndex!]['course'];
    int count = 0;

    setState(() {
      for (var student in _pendingLoads) {
        if (student['course'] == targetCourse) {
          for (int i = 0; i < student['subjects'].length; i++) {
            if (i < fees.length) {
              student['subjects'][i]['fee'] = fees[i];
            }
          }
          count++;
        }
      }
      // Refresh current controllers if the selected student was part of the bulk
      _onStudentSelected(_selectedStudentIndex!);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Bulk applied '$name' to $count students in $targetCourse.",
        ),
        backgroundColor: const Color(0xFF69F0AE),
      ),
    );
  }

  void _finalizeAssessment() {
    if (_selectedStudentIndex == null) return;
    final student = _pendingLoads[_selectedStudentIndex!];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Assessment finalized for ${student['name']}. Subject load completed.",
        ),
        backgroundColor: const Color(0xFF69F0AE),
      ),
    );

    setState(() {
      _pendingLoads.removeAt(_selectedStudentIndex!);
      _selectedStudentIndex = null;
      _feeControllers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF2E1065);
    final Color cardColor =
        widget.isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white54 : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subject Load Fee Assessment",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Assign fees to subject loads forwarded by the Program Chair to finalize student enrollment.",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PENDING LIST
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          widget.isDarkMode ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              color: Color(0xFF8B5CF6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Pending Loads",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.layers,
                                color: Color(0xFF8B5CF6),
                                size: 18,
                              ),
                              onPressed: () =>
                                  _showTemplatesDialog(textColor, cardColor),
                              tooltip: "Manage Templates",
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _pendingLoads.isEmpty
                            ? Center(
                                child: Text(
                                  "No pending loads",
                                  style: TextStyle(color: subTextColor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _pendingLoads.length,
                                itemBuilder: (context, index) {
                                  final s = _pendingLoads[index];
                                  bool isSelected =
                                      _selectedStudentIndex == index;
                                  return ListTile(
                                    onTap: () => _onStudentSelected(index),
                                    selected: isSelected,
                                    selectedTileColor: const Color(
                                      0xFF8B5CF6,
                                    ).withOpacity(0.1),
                                    title: Text(
                                      s['name'],
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      s['id'],
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      LucideIcons.chevronRight,
                                      size: 14,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // 2. ASSESSMENT PANEL
                Expanded(
                  child: _selectedStudentIndex == null
                      ? Center(
                          child: Text(
                            "Select a student to begin assessment",
                            style: TextStyle(color: subTextColor),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white10
                                  : Colors.black12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pendingLoads[_selectedStudentIndex!]['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "${_pendingLoads[_selectedStudentIndex!]['course']} • ${_pendingLoads[_selectedStudentIndex!]['id']}",
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _saveAsTemplate,
                                    icon: const Icon(
                                      LucideIcons.save,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      "SAVE AS TEMPLATE",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                "SUBJECT BREAKDOWN",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: subTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount:
                                      _pendingLoads[_selectedStudentIndex!]
                                              ['subjects']
                                          .length,
                                  itemBuilder: (context, idx) {
                                    final sub =
                                        _pendingLoads[_selectedStudentIndex!]
                                            ['subjects'][idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: widget.isDarkMode
                                            ? Colors.white.withOpacity(0.03)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sub['code'],
                                                style: const TextStyle(
                                                  color: Color(0xFF8B5CF6),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                sub['title'],
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            width: 150,
                                            child: TextField(
                                              controller: _feeControllers[idx],
                                              decoration: InputDecoration(
                                                prefixText: "₱ ",
                                                hintText: "Enter Fee",
                                                filled: true,
                                                fillColor: cardColor,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _finalizeAssessment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF69F0AE),
                                    foregroundColor: const Color(0xFF2E1065),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "FINALIZE ASSESSMENT & COMPLETE LOAD",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplatesDialog(Color textColor, Color cardColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          "Fee Templates",
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 450,
          child: _savedTemplates.isEmpty
              ? const Text("No templates saved yet.")
              : ListView(
                  shrinkWrap: true,
                  children: _savedTemplates.keys.map((name) {
                    return ListTile(
                      title: Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "${_savedTemplates[name]!.length} subjects",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              LucideIcons.copy,
                              size: 18,
                              color: Color(0xFF8B5CF6),
                            ),
                            onPressed: () {
                              _applyTemplate(name);
                              Navigator.pop(context);
                            },
                            tooltip: "Apply to selected",
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.users,
                              size: 18,
                              color: Color(0xFF69F0AE),
                            ),
                            onPressed: () {
                              _bulkApplyTemplate(name);
                              Navigator.pop(context);
                            },
                            tooltip: "Bulk Apply to Course",
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}
