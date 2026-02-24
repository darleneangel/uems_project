import 'package:flutter/material.dart';

/// Smart Search Service
/// Provides cross-departmental search functionality across Registrar and Accounting
class SmartSearchService extends ChangeNotifier {
  static final SmartSearchService _instance = SmartSearchService._internal();
  factory SmartSearchService() => _instance;
  SmartSearchService._internal();

  // Search state
  String _searchQuery = '';
  List<String> _selectedDepartments = ['All'];
  List<String> _selectedCategories = ['All'];
  String _sortBy = 'relevance'; // relevance, name, date, amount
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  // Getters
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<String> get selectedDepartments => _selectedDepartments;
  List<String> get selectedCategories => _selectedCategories;
  String get sortBy => _sortBy;

  // Available filters
  final List<String> departments = ['All', 'Registrar', 'Accounting'];
  final List<String> categories = [
    'All',
    'Students',
    'Payments',
    'Enrollments',
    'Fees',
    'Transactions',
    'Records',
    'Scholarships',
  ];

  // Mock unified database (In production, this would query from backend)
  final List<Map<String, dynamic>> _unifiedDatabase = [
    // Registrar Records
    {
      'id': '2024-00001',
      'type': 'student_record',
      'department': 'Registrar',
      'category': 'Students',
      'title': 'DARLENE ANGEL',
      'subtitle': 'BS Computer Science - 4th Year',
      'description': 'Student ID: 2024-00001 | Section: BSCS-4A',
      'status': 'Active',
      'email': 'darlene.a@sscr.edu.ph',
      'phone': '+63 912 345 6789',
      'date': '2024-01-15',
      'metadata': {
        'course': 'BS Computer Science',
        'year': '4th Year',
        'section': 'BSCS-4A',
        'enrollment': 'Enrolled (2nd Sem 2025-2026)',
      },
    },
    {
      'id': '2024-00002',
      'type': 'student_record',
      'department': 'Registrar',
      'category': 'Students',
      'title': 'JUAN DELA CRUZ',
      'subtitle': 'BS Info Tech - 3rd Year',
      'description': 'Student ID: 2024-00002 | Section: BSIT-3B',
      'status': 'Active',
      'email': 'juan.dc@sscr.edu.ph',
      'phone': '+63 915 555 1234',
      'date': '2024-01-10',
      'metadata': {
        'course': 'BS Info Tech',
        'year': '3rd Year',
        'section': 'BSIT-3B',
        'enrollment': 'Enrolled (2nd Sem 2025-2026)',
      },
    },
    // Accounting Records
    {
      'id': '2024-001',
      'type': 'student_payment',
      'department': 'Accounting',
      'category': 'Payments',
      'title': 'Darlene Angel - Payment Record',
      'subtitle': 'Balance: ₱15,000.00',
      'description': 'BSCS 4A | Status: Pending Payment',
      'status': 'Pending',
      'date': '2024-01-15',
      'amount': 15000.0,
      'metadata': {
        'student_id': '2024-001',
        'course': 'BSCS',
        'year': '4A',
        'scholarship': 'None',
      },
    },
    {
      'id': '2024-089',
      'type': 'student_payment',
      'department': 'Accounting',
      'category': 'Payments',
      'title': 'Juan Dela Cruz - Payment Record',
      'subtitle': 'Balance: ₱8,500.00',
      'description': 'BSIT 1B | Status: Overdue',
      'status': 'Overdue',
      'date': '2024-01-10',
      'amount': 8500.0,
      'metadata': {
        'student_id': '2024-089',
        'course': 'BSIT',
        'year': '1B',
        'scholarship': 'None',
      },
    },
    // Enrollments
    {
      'id': 'ENR-2024-001',
      'type': 'enrollment',
      'department': 'Registrar',
      'category': 'Enrollments',
      'title': 'Enrollment: DARLENE ANGEL',
      'subtitle': '2nd Semester 2025-2026',
      'description': 'BSCS 4A | 21 Units | Regular Student',
      'status': 'Confirmed',
      'date': '2024-08-15',
      'metadata': {
        'student_id': '2024-00001',
        'semester': '2nd Semester',
        'academic_year': '2025-2026',
        'units': 21,
      },
    },
    // Fee Structures
    {
      'id': 'FEE-BSCS-2024',
      'type': 'fee_structure',
      'department': 'Accounting',
      'category': 'Fees',
      'title': 'BS Computer Science Tuition',
      'subtitle': 'Midterm Block A: ₱7,500.00',
      'description': 'Semester fee breakdown for BSCS program',
      'status': 'Active',
      'date': '2024-01-01',
      'amount': 7500.0,
      'metadata': {
        'program': 'BSCS',
        'term': 'Midterm Block A',
        'total_semester': 15000.0,
      },
    },
    // Transactions
    {
      'id': 'TXN-20240215-001',
      'type': 'transaction',
      'department': 'Accounting',
      'category': 'Transactions',
      'title': 'Payment Received - Darlene Angel',
      'subtitle': 'Amount: ₱5,000.00',
      'description': 'Cash payment for Tuition Fee',
      'status': 'Completed',
      'date': '2024-02-15',
      'amount': 5000.0,
      'metadata': {
        'student_id': '2024-001',
        'payment_method': 'Cash',
        'reference': 'CASH-001',
      },
    },
    // Scholarships
    {
      'id': 'SCH-ACADEMIC-001',
      'type': 'scholarship',
      'department': 'Accounting',
      'category': 'Scholarships',
      'title': 'Academic Excellence Scholarship',
      'subtitle': '100% Tuition Discount',
      'description': 'Merit-based scholarship for top students',
      'status': 'Active',
      'date': '2024-01-01',
      'metadata': {
        'type': 'Merit',
        'discount': 1.0,
        'requirements': 'GPA 3.75 or higher',
      },
    },
    // Credentials
    {
      'id': 'CRED-2024-001',
      'type': 'credential',
      'department': 'Registrar',
      'category': 'Records',
      'title': 'Transcript Request - DARLENE ANGEL',
      'subtitle': 'Official Transcript of Records',
      'description': 'Requested on: Feb 24, 2026',
      'status': 'Processing',
      'date': '2026-02-24',
      'metadata': {
        'student_id': '2024-00001',
        'document_type': 'Transcript',
        'purpose': 'Employment',
      },
    },
  ];

  /// Perform search across all departments
  Future<void> search(String query) async {
    _searchQuery = query.trim();
    _isSearching = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Filter by departments
    List<Map<String, dynamic>> filtered = _unifiedDatabase;
    
    if (!_selectedDepartments.contains('All')) {
      filtered = filtered.where((item) =>
        _selectedDepartments.contains(item['department'])
      ).toList();
    }

    // Filter by categories
    if (!_selectedCategories.contains('All')) {
      filtered = filtered.where((item) =>
        _selectedCategories.contains(item['category'])
      ).toList();
    }

    // Search across multiple fields
    final queryLower = _searchQuery.toLowerCase();
    final results = filtered.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final subtitle = (item['subtitle'] as String).toLowerCase();
      final description = (item['description'] as String).toLowerCase();
      final id = (item['id'] as String).toLowerCase();
      final status = (item['status'] as String).toLowerCase();
      
      return title.contains(queryLower) ||
             subtitle.contains(queryLower) ||
             description.contains(queryLower) ||
             id.contains(queryLower) ||
             status.contains(queryLower);
    }).toList();

    // Convert to SearchResult objects with relevance scoring
    _searchResults = results.map((item) {
      final relevance = _calculateRelevance(item, queryLower);
      return SearchResult(
        id: item['id'],
        type: item['type'],
        department: item['department'],
        category: item['category'],
        title: item['title'],
        subtitle: item['subtitle'],
        description: item['description'],
        status: item['status'],
        date: item['date'],
        amount: item['amount'],
        metadata: item['metadata'],
        relevanceScore: relevance,
      );
    }).toList();

    // Sort results
    _sortResults();

    _isSearching = false;
    notifyListeners();
  }

  /// Calculate relevance score for search result
  double _calculateRelevance(Map<String, dynamic> item, String query) {
    double score = 0.0;
    
    // Exact match in title gets highest score
    if ((item['title'] as String).toLowerCase() == query) {
      score += 100.0;
    } else if ((item['title'] as String).toLowerCase().contains(query)) {
      score += 50.0;
    }
    
    // Match in ID or subtitle
    if ((item['id'] as String).toLowerCase().contains(query)) {
      score += 40.0;
    }
    if ((item['subtitle'] as String).toLowerCase().contains(query)) {
      score += 30.0;
    }
    
    // Match in description
    if ((item['description'] as String).toLowerCase().contains(query)) {
      score += 20.0;
    }
    
    // Match in status
    if ((item['status'] as String).toLowerCase().contains(query)) {
      score += 10.0;
    }

    return score;
  }

  /// Sort search results
  void _sortResults() {
    switch (_sortBy) {
      case 'name':
        _searchResults.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date':
        _searchResults.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount':
        _searchResults.sort((a, b) {
          final amtA = a.amount ?? 0.0;
          final amtB = b.amount ?? 0.0;
          return amtB.compareTo(amtA);
        });
        break;
      case 'relevance':
      default:
        _searchResults.sort((a, b) =>
          b.relevanceScore.compareTo(a.relevanceScore)
        );
        break;
    }
  }

  /// Update department filter
  void setDepartmentFilter(List<String> departments) {
    _selectedDepartments = departments;
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
  }

  /// Update category filter
  void setCategoryFilter(List<String> categories) {
    _selectedCategories = categories;
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
  }

  /// Update sort order
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _sortResults();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _selectedDepartments = ['All'];
    _selectedCategories = ['All'];
    notifyListeners();
  }

  /// Get quick stats
  Map<String, int> getSearchStats() {
    return {
      'total': _searchResults.length,
      'registrar': _searchResults.where((r) => r.department == 'Registrar').length,
      'accounting': _searchResults.where((r) => r.department == 'Accounting').length,
    };
  }
}

/// Search Result Model
class SearchResult {
  final String id;
  final String type;
  final String department;
  final String category;
  final String title;
  final String subtitle;
  final String description;
  final String status;
  final String date;
  final double? amount;
  final Map<String, dynamic> metadata;
  final double relevanceScore;

  SearchResult({
    required this.id,
    required this.type,
    required this.department,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.status,
    required this.date,
    this.amount,
    required this.metadata,
    this.relevanceScore = 0.0,
  });

  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'completed':
      case 'cleared':
        return const Color(0xFF69F0AE);
      case 'pending':
      case 'processing':
        return const Color(0xFFFFA726);
      case 'overdue':
      case 'rejected':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  // Get department color
  Color getDepartmentColor() {
    switch (department) {
      case 'Registrar':
        return const Color(0xFF4C1D95);
      case 'Accounting':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF2E1065);
    }
  }
}
