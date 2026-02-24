import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../services/smart_search_service.dart';

/// Smart Search Widget
/// Universal search component for cross-departmental search
class SmartSearchWidget extends StatefulWidget {
  final bool isDarkMode;
  final String? defaultDepartment; // Optional: Pre-filter by department
  final Function(SearchResult)? onResultTap;

  const SmartSearchWidget({
    super.key,
    required this.isDarkMode,
    this.defaultDepartment,
    this.onResultTap,
  });

  @override
  State<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends State<SmartSearchWidget>
    with SingleTickerProviderStateMixin {
  final SmartSearchService _searchService = SmartSearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _overlayFocusNode = FocusNode();
  
  bool _showFilters = false;
  bool _isOverlayOpen = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Theme colors
  static const Color pViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    
    if (widget.defaultDepartment != null) {
      _searchService.setDepartmentFilter([widget.defaultDepartment!]);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchService.addListener(_onSearchUpdate);
  }

  @override
  void dispose() {
    _searchService.removeListener(_onSearchUpdate);
    _animationController.dispose();
    _searchController.dispose();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  void _onSearchUpdate() {
    if (mounted) setState(() {});
  }

  void _handleSearch(String query) {
    _searchService.search(query);
  }

  void _openSearchOverlay() {
    if (_isOverlayOpen) return;

    setState(() => _isOverlayOpen = true);
    _animationController.forward();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        final textColor = widget.isDarkMode ? Colors.white : pViolet;
        final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;
        final bgColor = widget.isDarkMode
            ? const Color(0xFF0F071D)
            : const Color(0xFFF8FAFC);

        return SafeArea(
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: AnimatedBuilder(
                animation: _searchService,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: Alignment.topCenter,
                      child: _buildSearchResults(textColor, cardColor, bgColor),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() => _isOverlayOpen = false);
      _animationController.reverse();
      _overlayFocusNode.unfocus();
    });

    // Ensure the overlay text field receives focus when opened.
    Future.microtask(() {
      if (mounted) {
        _overlayFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : pViolet;
    final cardColor = widget.isDarkMode ? surfaceDark : Colors.white;

    return _buildSearchBar(textColor, cardColor);
  }

  Widget _buildSearchBar(Color textColor, Color cardColor) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverlayOpen
              ? aViolet
              : (widget.isDarkMode ? Colors.white10 : Colors.black12),
          width: _isOverlayOpen ? 2 : 1,
        ),
        boxShadow: _isOverlayOpen
            ? [
                BoxShadow(
                  color: aViolet.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            LucideIcons.search,
            color: textColor.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              readOnly: true,
              enableInteractiveSelection: false,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search across departments...',
                hintStyle: GoogleFonts.inter(
                  color: textColor.withOpacity(0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: _openSearchOverlay,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                LucideIcons.x,
                color: textColor.withOpacity(0.6),
                size: 18,
              ),
              onPressed: () {
                _searchController.clear();
                _searchService.clearSearch();
              },
            ),
          IconButton(
            icon: Icon(
              _showFilters ? LucideIcons.filterX : LucideIcons.filter,
              color: _showFilters ? aViolet : textColor.withOpacity(0.6),
              size: 18,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Color textColor, Color cardColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          color: aViolet,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search Results',
                                style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_searchService.searchResults.isNotEmpty)
                                Text(
                                  '${_searchService.searchResults.length} results found',
                                  style: GoogleFonts.inter(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: textColor.withOpacity(0.6),
                          ),
                          onPressed: _closeSearch,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      focusNode: _overlayFocusNode,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type to search...',
                        hintStyle: GoogleFonts.inter(
                          color: textColor.withOpacity(0.4),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: textColor.withOpacity(0.6),
                          size: 18,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: textColor.withOpacity(0.6),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchService.clearSearch();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: widget.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        _handleSearch(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // Filters (if visible)
              if (_showFilters) _buildFilters(textColor),

              // Stats bar
              if (_searchService.searchResults.isNotEmpty)
                _buildStatsBar(textColor),

              // Results list
              Expanded(
                child: _searchService.isSearching
                    ? _buildLoadingState(textColor)
                    : _searchService.searchResults.isEmpty
                        ? _buildEmptyState(textColor)
                        : _buildResultsList(textColor, cardColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._searchService.departments.map((dept) => _buildFilterChip(
                    dept,
                    _searchService.selectedDepartments.contains(dept),
                    () {
                      final selected = List<String>.from(
                        _searchService.selectedDepartments,
                      );
                      if (dept == 'All') {
                        _searchService.setDepartmentFilter(['All']);
                      } else {
                        selected.remove('All');
                        if (selected.contains(dept)) {
                          selected.remove(dept);
                          if (selected.isEmpty) selected.add('All');
                        } else {
                          selected.add(dept);
                        }
                        _searchService.setDepartmentFilter(selected);
                      }
                    },
                    textColor,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          // Sort options
          Row(
            children: [
              Text(
                'Sort by:',
                style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              ...[
                {'value': 'relevance', 'label': 'Relevance'},
                {'value': 'name', 'label': 'Name'},
                {'value': 'date', 'label': 'Date'},
                {'value': 'amount', 'label': 'Amount'},
              ].map(
                (sort) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    sort['label']!,
                    _searchService.sortBy == sort['value'],
                    () => _searchService.setSortBy(sort['value']!),
                    textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color textColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? aViolet.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? aViolet : textColor.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? aViolet : textColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(Color textColor) {
    final stats = _searchService.getSearchStats();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Registrar',
            stats['registrar']!,
            const Color(0xFF4C1D95),
            textColor,
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            'Accounting',
            stats['accounting']!,
            aViolet,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    int count,
    Color color,
    Color textColor,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: GoogleFonts.inter(
            color: textColor.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: aViolet,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.searchX,
            color: textColor.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Start typing to search'
                : 'No results found',
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Search across departments, students, payments, and more'
                : 'Try adjusting your search or filters',
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.4),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(Color textColor, Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchService.searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchService.searchResults[index];
        return _buildResultCard(result, textColor, cardColor);
      },
    );
  }

  Widget _buildResultCard(
    SearchResult result,
    Color textColor,
    Color cardColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onResultTap != null) {
            widget.onResultTap!(result);
          }
          _closeSearch();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Department badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: result.getDepartmentColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      result.department,
                      style: GoogleFonts.inter(
                        color: result.getDepartmentColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category
                  Text(
                    result.category,
                    style: GoogleFonts.inter(
                      color: textColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: result.getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      result.status,
                      style: GoogleFonts.inter(
                        color: result.getStatusColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                result.title,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                result.subtitle,
                style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                result.description,
                style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              // Amount if exists
              if (result.amount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.coins,
                      color: success,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₱${result.amount!.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: success,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              // Footer
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: textColor.withOpacity(0.4),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    result.date,
                    style: GoogleFonts.inter(
                      color: textColor.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.arrowRight,
                    color: aViolet,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
