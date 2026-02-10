import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseManagementPanel extends StatefulWidget {
  const CourseManagementPanel({super.key});

  @override
  State<CourseManagementPanel> createState() => _CourseManagementPanelState();
}

class _CourseManagementPanelState extends State<CourseManagementPanel> {
  final List<Map<String, String>> _courses = [];
  late TextEditingController _nameCtl;
  late TextEditingController _codeCtl;
  late TextEditingController _deptCtl;
  late TextEditingController _creditsCtl;
  late TextEditingController _descCtl;
  int? _editingIndex;

  final List<String> _departments = ['Computer Science', 'Business Administration', 'Mathematics', 'Engineering', 'Arts & Sciences'];
  final List<String> _statuses = ['Active', 'Inactive', 'Pending'];

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _codeCtl = TextEditingController();
    _deptCtl = TextEditingController();
    _creditsCtl = TextEditingController();
    _descCtl = TextEditingController();
    _seedDemoCourses();
  }

  void _seedDemoCourses() {
    _courses.addAll([
      {
        'name': 'Introduction to Programming',
        'code': 'CS101',
        'department': 'Computer Science',
        'credits': '3',
        'type': 'Core',
        'description': 'Fundamental concepts of programming using Python',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 15)).toString(),
      },
      {
        'name': 'Business Ethics',
        'code': 'BA201',
        'department': 'Business Administration',
        'credits': '2',
        'type': 'Core',
        'description:': 'Ethical principles in business practices',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 10)).toString(),
      },
      {
        'name': 'Calculus I',
        'code': 'MATH101',
        'department': 'Mathematics',
        'credits': '4',
        'type': 'Core',
        'description': 'Differential and integral calculus',
        'status': 'Active',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)).toString(),
      },
    ]);
  }

  void _clearForm() {
    _nameCtl.clear();
    _codeCtl.clear();
    _deptCtl.clear();
    _creditsCtl.clear();
    _descCtl.clear();
    setState(() => _editingIndex = null);
  }

  void _addCourse() {
    if (_nameCtl.text.isEmpty || _codeCtl.text.isEmpty || _deptCtl.text.isEmpty || _creditsCtl.text.isEmpty || _descCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newCourse = {
      'name': _nameCtl.text,
      'code': _codeCtl.text.toUpperCase(),
      'department': _deptCtl.text,
      'credits': _creditsCtl.text,
      'type': 'Core',
      'description': _descCtl.text,
      'status': 'Active',
      'timestamp': DateTime.now().toString(),
    };

    setState(() {
      if (_editingIndex != null) {
        _courses[_editingIndex!] = newCourse;
        _editingIndex = null;
      } else {
        _courses.insert(0, newCourse);
      }
    });

    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex == null ? 'Course added' : 'Course updated', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  void _startEdit(int idx) {
    final course = _courses[idx];
    setState(() {
      _nameCtl.text = course['name'] ?? '';
      _codeCtl.text = course['code'] ?? '';
      _deptCtl.text = course['department'] ?? '';
      _creditsCtl.text = course['credits'] ?? '';
      _descCtl.text = course['description'] ?? '';
      _editingIndex = idx;
    });
  }

  void _deleteCourse(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1033),
        title: Text('Delete Course?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() => _courses.removeAt(idx));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Course deleted', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(int idx, String newStatus) {
    setState(() => _courses[idx]['status'] = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course status updated to $newStatus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF69F0AE)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF69F0AE);
      case 'Inactive':
        return Colors.grey;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCourseDetails(Map<String, String> course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getStatusColor(course['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(course['status'] ?? 'Active', style: GoogleFonts.inter(color: _getStatusColor(course['status'] ?? 'Active'), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('${course['credits']} Credits', style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Course Name: ${course['name']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Course Code: ${course['code']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Department: ${course['department']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Course Type: ${course['type']}', style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('Description:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(course['description'] ?? '', style: GoogleFonts.inter(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 12),
          Text('Created: ${course['timestamp']}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel: Create/Edit Course
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Course Management', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Course Name',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., Introduction to Programming',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _codeCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Course Code',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., CS101',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _deptCtl.text.isEmpty ? null : _deptCtl.text,
                          items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) => setState(() => _deptCtl.text = v ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Department',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Select Department',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF1E1033),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _creditsCtl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Credits',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., 3',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descCtl,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Describe the course...',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          ElevatedButton(
                            onPressed: _addCourse,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                            child: Text(_editingIndex == null ? 'Add Course' : 'Update Course', style: GoogleFonts.inter(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _clearForm,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                            child: Text('Clear', style: GoogleFonts.inter(color: Colors.white70)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Right panel: Courses List
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF1E1033), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Courses Directory (${_courses.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                          child: _courses.isEmpty
                              ? Center(child: Text('No courses yet', style: GoogleFonts.inter(color: Colors.white54)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _courses.length,
                                  itemBuilder: (ctx, idx) {
                                    final course = _courses[idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(course['name'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                                Text('${course['code']} • ${course['department']}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                              ]),
                                              Row(children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: _getStatusColor(course['status'] ?? 'Active').withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(course['status'] ?? '', style: GoogleFonts.inter(color: _getStatusColor(course['status'] ?? 'Active'), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                  child: Text('${course['credits']} cr', style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                              ]),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(course['description'] ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(course['timestamp'] ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: const Color(0xFF1E1033),
                                                        title: Text('Course Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                                                        content: SizedBox(width: 400, child: _buildCourseDetails(course)),
                                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)))],
                                                      ),
                                                    ),
                                                    icon: const Icon(Icons.info, color: Colors.white54, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _startEdit(idx), icon: const Icon(Icons.edit, color: Colors.white54, size: 18)),
                                                  PopupMenuButton(
                                                    onSelected: (status) => _updateStatus(idx, status),
                                                    itemBuilder: (ctx) => _statuses.map((s) => PopupMenuItem(value: s, child: Text(s, style: GoogleFonts.inter()))).toList(),
                                                    child: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                                                  ),
                                                  IconButton(onPressed: () => _deleteCourse(idx), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _codeCtl.dispose();
    _deptCtl.dispose();
    _creditsCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }
}
