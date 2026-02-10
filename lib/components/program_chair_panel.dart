import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProgramChairPanel extends StatefulWidget {
  const ProgramChairPanel({super.key});

  @override
  State<ProgramChairPanel> createState() => _ProgramChairPanelState();
}

class _ProgramChairPanelState extends State<ProgramChairPanel> {
  // Theme colors similar to project
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1033);

  // Internal in-memory store for program items
  final List<Map<String, dynamic>> _items = [];
  int _nextId = 1;

  // UI state
  String _selectedAction = 'overview'; // 'create','review','update','archive'
  Map<String, dynamic>? _editingItem;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _effectiveDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _selectedAction = 'create';
      _editingItem = null;
      _titleController.clear();
      _descriptionController.clear();
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
      _effectiveDate = item['effectiveDate'];
    });
  }

  void _startArchive() => setState(() => _selectedAction = 'archive');

  void _submitCreateOrUpdate() {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    if (_editingItem == null) {
      // create
      final newItem = {
        'id': _nextId++,
        'title': title,
        'description': desc,
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
        _editingItem!['title'] = title;
        _editingItem!['description'] = desc;
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
        ? LinearGradient(colors: [aViolet, pViolet])
        : LinearGradient(colors: [Colors.white10, Colors.white12]);
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
            color: selected ? aViolet.withOpacity(0.6) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : Colors.white70,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Program Item',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Description',
            hintStyle: TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitCreateOrUpdate,
                style: ElevatedButton.styleFrom(backgroundColor: aViolet),
                child: Text(
                  _editingItem == null ? 'Create' : 'Update',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                setState(() => _effectiveDate = null);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
              ),
              child: Text(
                'Clear',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewList() {
    final visible = _items.where((i) => i['archived'] == false).toList();
    if (visible.isEmpty)
      return const Text(
        'No program items found.',
        style: TextStyle(color: Colors.white70),
      );
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
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
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
                    icon: const Icon(LucideIcons.edit3, color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: () => _archiveItem(item),
                    icon: const Icon(
                      LucideIcons.archive,
                      color: Colors.white70,
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
    if (archived.isEmpty)
      return const Text(
        'No archived items.',
        style: TextStyle(color: Colors.white70),
      );
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
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _restoreItem(item),
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white70),
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
