import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProgramChairPanel extends StatefulWidget {
  const ProgramChairPanel({super.key, this.isDarkMode = true});
  final bool isDarkMode;

  @override
  State<ProgramChairPanel> createState() => _ProgramChairPanelState();
}

class _ProgramChairPanelState extends State<ProgramChairPanel> {
  // Theme colors similar to project
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);
  static const Color lCard = Color(0xFFFFFFFF);
  
  late bool _isDarkMode;

  // Internal in-memory store for program items
  final List<Map<String, dynamic>> _items = [];
  int _nextId = 1;

  // UI state
  String _selectedAction = 'overview'; // 'create','review','update','archive'
  Map<String, dynamic>? _editingItem;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _effectiveDate;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _selectedAction = 'create';
      _editingItem = null;
      _titleController.clear();
      _descriptionController.clear();
      _nameController.clear();
      _departmentController.clear();
      _emailController.clear();
      _employeeIdController.clear();
      _passwordController.clear();
      _effectiveDate = null;
    });
  }

  void _startReview() => setState(() => _selectedAction = 'review');
  void _startUpdate(Map<String, dynamic> item) {
    setState(() {
      _selectedAction = 'update';
      _editingItem = item;
      _titleController.text = item['title'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      _nameController.text = item['name'] ?? '';
      _departmentController.text = item['department'] ?? '';
      _emailController.text = item['email'] ?? '';
      _employeeIdController.text = item['employeeId'] ?? '';
      _passwordController.text = item['password'] ?? '';
      _effectiveDate = item['effectiveDate'];
    });
  }

  void _startArchive() => setState(() => _selectedAction = 'archive');

  void _submitCreateOrUpdate() {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final email = _emailController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final password = _passwordController.text.trim();
    
    // Validate all required fields
    if (title.isEmpty || name.isEmpty || department.isEmpty || email.isEmpty || employeeId.isEmpty || password.isEmpty) {
      List<String> missingFields = [];
      if (title.isEmpty) missingFields.add('Title');
      if (name.isEmpty) missingFields.add('Name');
      if (department.isEmpty) missingFields.add('Department');
      if (email.isEmpty) missingFields.add('Email');
      if (employeeId.isEmpty) missingFields.add('Employee ID');
      if (password.isEmpty) missingFields.add('Password');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields: ${missingFields.join(', ')}')),
      );
      return;
    }

    if (_editingItem == null) {
      // create
      final newItem = {
        'id': _nextId++,
        'title': title,
        'description': desc,
        'name': _nameController.text,
        'department': _departmentController.text,
        'email': _emailController.text,
        'employeeId': _employeeIdController.text,
        'password': _passwordController.text,
        'effectiveDate': _effectiveDate,
        'archived': false,
      };
      setState(() => _items.insert(0, newItem));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Program item created')));
    } else {
      // update
      setState(() {
        _editingItem!['name'] = _nameController.text;
        _editingItem!['title'] = title;
        _editingItem!['description'] = desc;
        _editingItem!['department'] = _departmentController.text;
        _editingItem!['email'] = _emailController.text;
        _editingItem!['employeeId'] = _employeeIdController.text;
        _editingItem!['password'] = _passwordController.text;
        _editingItem!['effectiveDate'] = _effectiveDate;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Program item updated')));
    }

    // go to review
    setState(() => _selectedAction = 'review');
  }

  void _archiveItem(Map<String, dynamic> item) {
    setState(() => item['archived'] = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Archived')));
  }

  void _restoreItem(Map<String, dynamic> item) {
    setState(() => item['archived'] = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Restored')));
  }

  // Styled action card
  Widget _actionCard(String key, String label, IconData icon, bool selected) {
    final bg = selected
        ? LinearGradient(colors: [_isDarkMode ? aViolet : pViolet, _isDarkMode ? pViolet : aViolet.withValues(alpha:0.8)])
        : LinearGradient(colors: [_isDarkMode ? Colors.white10 : Colors.grey.shade100, _isDarkMode ? Colors.white12 : Colors.grey.shade200]);
    return GestureDetector(
      onTap: () {
        switch (key) {
          case 'create':
            _startCreate();
            break;
          case 'review':
            _startReview();
            break;
          case 'update':
            // if no items, jump to create
            if (_items.isEmpty) {
              _startCreate();
            } else {
              _startUpdate(_items.first);
            }
            break;
          case 'archive':
            _startArchive();
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected 
                ? (_isDarkMode ? aViolet : pViolet)
                : (_isDarkMode ? Colors.white10 : Colors.grey.shade300),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? (_isDarkMode ? Colors.white24 : Colors.black12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected 
                      ? (_isDarkMode ? Colors.white38 : Colors.black26)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Icon(icon, color: selected ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black54), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black54),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create form
  Widget _buildCreateForm() {
    // Theme-aware colors
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final hintColor = _isDarkMode ? Colors.white30 : Colors.grey.shade500;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;
    final borderColor = _isDarkMode ? Colors.white24 : Colors.grey.shade300;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Administrator Details', style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _departmentController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Department',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Personal Email',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _employeeIdController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Employee ID',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          style: TextStyle(color: textColor),
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password (Temporary)',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitCreateOrUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode ? aViolet : pViolet,
                  side: BorderSide(color: _isDarkMode ? aViolet : pViolet, width: 2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _editingItem == null ? 'Create' : 'Update',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                _nameController.clear();
                _departmentController.clear();
                _emailController.clear();
                _employeeIdController.clear();
                _passwordController.clear();
                setState(() => _effectiveDate = null);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor, width: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: subTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewList() {
    final visible = _items.where((i) => i['archived'] == false).toList();
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;
    final borderColor = _isDarkMode ? Colors.white24 : Colors.grey.shade300;
    
    if (visible.isEmpty) {
      return Text(
        'No program items found.',
        style: TextStyle(color: subTextColor),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = visible[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _startUpdate(item),
                    icon: Icon(LucideIcons.edit3, color: subTextColor),
                  ),
                  IconButton(
                    onPressed: () => _archiveItem(item),
                    icon: Icon(
                      LucideIcons.archive,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchiveList() {
    final archived = _items.where((i) => i['archived'] == true).toList();
    final textColor = _isDarkMode ? Colors.white : pViolet;
    final subTextColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final fillColor = _isDarkMode ? Colors.white10 : Colors.grey.shade50;
    final borderColor = _isDarkMode ? Colors.white24 : Colors.grey.shade300;
    
    if (archived.isEmpty) {
      return Text(
        'No archived items.',
        style: TextStyle(color: subTextColor),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: archived.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = archived[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _restoreItem(item),
                icon: Icon(LucideIcons.refreshCw, color: subTextColor),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCreate = _selectedAction == 'create';
    final selectedReview = _selectedAction == 'review';
    final selectedUpdate = _selectedAction == 'update';
    final selectedArchive = _selectedAction == 'archive';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page-level title is shown in the dashboard header; remove
        // the duplicate title here to keep the UI professional.
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.5,
          children: [
            _actionCard(
              'create',
              'Create',
              LucideIcons.plusSquare,
              selectedCreate,
            ),
            _actionCard(
              'review',
              'Review',
              LucideIcons.clipboardList,
              selectedReview,
            ),
            _actionCard('update', 'Update', LucideIcons.edit3, selectedUpdate),
            _actionCard(
              'archive',
              'Archive',
              LucideIcons.archive,
              selectedArchive,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Builder(
            key: ValueKey(_selectedAction),
            builder: (context) {
              switch (_selectedAction) {
                case 'create':
                case 'update':
                  return _buildCreateForm();
                case 'review':
                  return _buildReviewList();
                case 'archive':
                  return _buildArchiveList();
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }
}
