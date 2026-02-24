# Smart Search - Cross-Departmental Search Implementation

## Overview
This implementation provides a powerful **Smart Search** feature with **cross-departmental search capabilities** for the Registrar and Accounting offices in the UEMS (Unified Education Management System).

## Features Implemented

### ✨ Core Features
1. **Unified Search** - Search across both Registrar and Accounting departments simultaneously
2. **Smart Filtering** - Filter by department, category, and various criteria
3. **Real-time Results** - Instant search results as you type
4. **Relevance Scoring** - Results ranked by relevance to your query
5. **Advanced Sorting** - Sort by relevance, name, date, or amount
6. **Beautiful UI** - Modern, animated interface with glassmorphism effects
7. **Department Pre-filtering** - Each dashboard can default to its own department

### 🔍 Searchable Data Types

#### Registrar Department
- **Student Records** - Search by name, ID, course, section
- **Enrollments** - Find enrollment records, semesters, units
- **Credentials** - Document requests, transcripts, certificates
- **Academic Records** - Grades, curriculum, courses

#### Accounting Department
- **Student Payments** - Payment records, balances, status
- **Fees** - Tuition structures, fee schedules
- **Transactions** - Payment history, receipts, references
- **Scholarships** - Scholarship programs, discounts, types

### 🎯 Search Capabilities
- **Multi-field Search** - Searches across title, subtitle, description, ID, status
- **Case-insensitive** - Finds results regardless of capitalization
- **Partial Matching** - Finds results with partial keyword matches
- **Status Filtering** - Filter by Active, Pending, Overdue, etc.
- **Amount Sorting** - Sort financial records by amount
- **Date Sorting** - Sort by most recent or oldest first

## Files Created

### 1. Services
**`lib/services/smart_search_service.dart`** - Core search engine
- Unified database aggregation
- Search algorithm with relevance scoring
- Filter and sort functionality
- Department and category management
- Real-time state management using ChangeNotifier

### 2. Components
**`lib/components/smart_search_widget.dart`** - Search UI component
- Beautiful search bar with focus animations
- Expandable search overlay with glassmorphism
- Filter chips for departments and categories
- Search results with badges and metadata
- Loading and empty states
- Click-to-close functionality

### 3. Modified Files
- **`lib/views/registrar_dashboard_view.dart`** - Integrated search with "Registrar" pre-filter
- **`lib/views/accounting_dashboard_view.dart`** - Integrated search with "Accounting" pre-filter

## Architecture

### Search Flow
```
User Types Query
    ↓
SmartSearchService.search()
    ↓
Filter by Department & Category
    ↓
Search across all fields
    ↓
Calculate Relevance Score
    ↓
Sort Results
    ↓
Update UI via ChangeNotifier
```

### Data Structure
```dart
SearchResult {
  - id: Unique identifier
  - type: Record type (student_record, payment, etc.)
  - department: Registrar or Accounting
  - category: Students, Payments, etc.
  - title: Main display text
  - subtitle: Secondary info
  - description: Additional details
  - status: Current status
  - date: Associated date
  - amount: Optional monetary value
  - metadata: Additional data
  - relevanceScore: Search ranking
}
```

## How to Use

### 1. Access the Search
Both Registrar and Accounting dashboards now have a search bar in the top navigation:

**Registrar Dashboard:**
- Pre-filtered to show Registrar results
- Can expand filter to include Accounting data

**Accounting Dashboard:**
- Pre-filtered to show Accounting results
- Can expand filter to include Registrar data

### 2. Searching

#### Basic Search
1. Click the search bar or press Tab to focus
2. Type your search query
3. Results appear instantly in an overlay

#### Example Searches
```
"Darlene"       → Finds student records, payments
"2024-001"      → Finds by student ID
"BSCS"          → Finds all Computer Science students
"Pending"       → Finds all pending items
"Overdue"       → Finds overdue payments
"Scholarship"   → Finds scholarship programs
"Tuition"       → Finds tuition fees
"Enrollment"    → Finds enrollment records
```

### 3. Filtering

#### Department Filter
- **All** - Search across both departments
- **Registrar** - Only Registrar records
- **Accounting** - Only Accounting records

#### Category Filter
- **All** - All types
- **Students** - Student records
- **Payments** - Payment records
- **Enrollments** - Enrollment data
- **Fees** - Fee structures
- **Transactions** - Transaction history
- **Records** - Academic records
- **Scholarships** - Scholarship info

### 4. Sorting Options
- **Relevance** (Default) - Best matches first
- **Name** - Alphabetical order
- **Date** - Most recent first
- **Amount** - Highest amount first

### 5. Viewing Results
Each result card shows:
- **Department Badge** - Color-coded (Purple gradient)
- **Category** - Type of record
- **Status Badge** - Color-coded status (Green=Active, Orange=Pending, Red=Overdue)
- **Title** - Main identifier
- **Subtitle** - Key information
- **Description** - Additional details
- **Amount** - If applicable (payments, fees)
- **Date** - Associated date
- **Arrow Icon** - Click to view details

## Testing the Feature

### Test Scenario 1: Basic Search
1. Navigate to Registrar or Accounting dashboard
2. Click the search bar
3. Type "Darlene"
4. **Expected**: See student record and payment info

### Test Scenario 2: Cross-Department Search
1. In Registrar dashboard, click search
2. Click the filter icon
3. Select "All" for departments
4. Search for "2024-001"
5. **Expected**: See both Registrar and Accounting records

### Test Scenario 3: Status Search
1. Click search bar
2. Type "Pending"
3. **Expected**: All pending items across departments

### Test Scenario 4: Amount Sorting
1. Search for "payment"
2. Click filter icon
3. Select "Amount" in Sort by
4. **Expected**: Results sorted by payment amount

### Test Scenario 5: Filter by Category
1. Open search
2. Click filter icon
3. Select "Payments" category only
4. Search query
5. **Expected**: Only payment-related results

## Sample Data

The system includes mock data for testing:

### Students
- **DARLENE ANGEL** (2024-00001) - BSCS 4A
- **JUAN DELA CRUZ** (2024-00002) - BSIT 3B

### Payments
- Darlene Angel - ₱15,000 Balance (Pending)
- Juan Dela Cruz - ₱8,500 Balance (Overdue)

### Enrollments
- 2nd Semester 2025-2026 records

### Fees
- BSCS Tuition - ₱7,500/term

### Transactions
- Payment receipts with references

### Scholarships
- Academic Excellence (100%)
- Athletic Grant (50%)
- Financial Aid (25%)

## Customization

### Add More Search Fields
In `smart_search_service.dart`:
```dart
// Add new fields to search
final email = (item['email'] as String?)?.toLowerCase() ?? '';
if (email.contains(queryLower)) {
  score += 25.0;
}
```

### Change Default Filters
In dashboard files:
```dart
SmartSearchWidget(
  isDarkMode: _isDarkMode,
  defaultDepartment: 'All', // Change from 'Registrar'
  // ...
)
```

### Customize Colors
In `smart_search_service.dart`, modify:
```dart
Color getStatusColor() {
  switch (status.toLowerCase()) {
    case 'active':
      return const Color(0xFF00FF00); // Change color
    // ...
  }
}
```

### Add New Data Types
In `smart_search_service.dart`, add to `_unifiedDatabase`:
```dart
{
  'id': 'NEW-001',
  'type': 'new_type',
  'department': 'Registrar',
  'category': 'New Category',
  'title': 'New Record',
  // ... other fields
},
```

### Adjust Relevance Scoring
In `_calculateRelevance()` method:
```dart
// Give higher score to specific fields
if (item['course'].contains(query)) {
  score += 60.0; // Increase importance
}
```

## Advanced Features

### 1. Result Actions
Currently shows a snackbar. Extend to navigate to specific panels:
```dart
onResultTap: (result) {
  if (result.type == 'student_record') {
    // Navigate to student details
    setState(() => _selectedIndex = 1);
  } else if (result.type == 'student_payment') {
    // Navigate to payment panel
    setState(() => _selectedIndex = 2);
  }
},
```

### 2. Search History
Add to `SmartSearchService`:
```dart
List<String> _searchHistory = [];

void addToHistory(String query) {
  _searchHistory.insert(0, query);
  if (_searchHistory.length > 10) {
    _searchHistory.removeLast();
  }
}
```

### 3. Saved Searches
```dart
Map<String, SearchFilter> _savedSearches = {};

void saveSearch(String name, SearchFilter filter) {
  _savedSearches[name] = filter;
  notifyListeners();
}
```

### 4. Export Results
```dart
void exportResults(List<SearchResult> results) {
  // Convert to CSV or PDF
  final csv = results.map((r) =>
    '${r.id},${r.title},${r.department},${r.amount}'
  ).join('\n');
  // Save file...
}
```

## Production Considerations

### Current State (Development)
- Uses mock in-memory database
- Includes sample test data
- Simulates instant search

### For Production Deployment

#### 1. Backend Integration
Replace mock database with API calls:
```dart
Future<void> search(String query) async {
  _isSearching = true;
  notifyListeners();
  
  final response = await http.post(
    Uri.parse('https://your-api.com/search'),
    body: jsonEncode({
      'query': query,
      'departments': _selectedDepartments,
      'categories': _selectedCategories,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    _searchResults = (data['results'] as List)
      .map((r) => SearchResult.fromJson(r))
      .toList();
  }
  
  _isSearching = false;
  notifyListeners();
}
```

#### 2. Database Indexing
For fast searches, ensure your database has indexes on:
- Student IDs
- Student names
- Course codes
- Payment references
- Transaction dates
- Status fields

#### 3. Caching
Implement search result caching:
```dart
final Map<String, List<SearchResult>> _cache = {};

Future<void> search(String query) async {
  if (_cache.containsKey(query)) {
    _searchResults = _cache[query]!;
    notifyListeners();
    return;
  }
  
  // ... perform search
  _cache[query] = _searchResults;
}
```

#### 4. Pagination
For large result sets:
```dart
int _currentPage = 1;
final int _pageSize = 20;
bool _hasMoreResults = true;

Future<void> loadMore() async {
  if (!_hasMoreResults) return;
  _currentPage++;
  // Fetch next page...
}
```

#### 5. Security
- Add authentication checks
- Implement role-based access control
- Sanitize search queries
- Rate limit search requests

#### 6. Analytics
Track search queries for insights:
```dart
void _logSearch(String query, int resultCount) {
  // Log to analytics service
  analytics.logEvent(
    name: 'search',
    parameters: {
      'query': query,
      'department': _selectedDepartments,
      'results': resultCount,
    },
  );
}
```

## Performance Optimization

### 1. Debouncing
Already implemented! Search triggers after 300ms delay to avoid excessive calls.

### 2. Virtual Scrolling
For very long result lists, use `ListView.builder` (already implemented).

### 3. Lazy Loading
Load metadata only when result card is expanded:
```dart
Widget buildResultCard(SearchResult result) {
  return ExpansionTile(
    title: Text(result.title),
    children: [
      FutureBuilder(
        future: loadFullDetails(result.id),
        builder: (context, snapshot) {
          // Show full details
        },
      ),
    ],
  );
}
```

## Troubleshooting

### Issue: No results appear
**Solution**: 
- Check if filters are too restrictive
- Verify search query spelling
- Try selecting "All" for department and category

### Issue: Search is slow
**Solution**:
- Reduce dataset size
- Implement backend search
- Add database indexing
- Enable result caching

### Issue: Overlay doesn't close
**Solution**:
- Click outside the results area
- Press Escape key (if implemented)
- Click the X button in search bar

### Issue: Wrong results shown
**Solution**:
- Check relevance scoring algorithm
- Verify data field names match
- Review filter logic

## Future Enhancements

### Planned Features
- [ ] Voice search integration
- [ ] Barcode/QR code scanning for student IDs
- [ ] Advanced query syntax (AND, OR, NOT)
- [ ] Search suggestions/autocomplete
- [ ] Recently viewed items
- [ ] Bulk actions on search results
- [ ] Export to CSV/PDF
- [ ] Share search results
- [ ] Email search results
- [ ] Save favorite searches
- [ ] Search templates
- [ ] Multi-language support
- [ ] OCR for document search
- [ ] AI-powered semantic search

### Integration Ideas
- Connect to student portal for self-service search
- Add to mobile app for on-the-go access
- Integrate with notification system
- Link to report generation
- Connect to payment gateway

## API Reference

### SmartSearchService

#### Methods
```dart
// Perform search
Future<void> search(String query)

// Set department filter
void setDepartmentFilter(List<String> departments)

// Set category filter
void setCategoryFilter(List<String> categories)

// Update sort order
void setSortBy(String sortBy)

// Clear search
void clearSearch()

// Get statistics
Map<String, int> getSearchStats()
```

#### Properties
```dart
String searchQuery              // Current search query
List<SearchResult> searchResults // Current results
bool isSearching                // Loading state
List<String> selectedDepartments // Active department filters
List<String> selectedCategories  // Active category filters
String sortBy                   // Current sort method
```

### SearchResult Model
```dart
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
  
  Color getStatusColor()      // Status badge color
  Color getDepartmentColor()  // Department badge color
}
```

## Best Practices

### 1. Keep Queries Specific
- Use specific terms for faster results
- Include student IDs when known
- Use status keywords (Active, Pending, etc.)

### 2. Use Filters Effectively
- Start with department filter
- Narrow down with categories
- Apply date ranges when available

### 3. Sort Appropriately
- Use relevance for broad searches
- Use date for recent items
- Use amount for financial queries

### 4. Handle Results
- Review top results first (best relevance)
- Use badges to quickly identify type
- Check status before taking action

## Support & Documentation

### Quick Reference
- **Search Bar**: Top of dashboard
- **Filter Button**: Right side of search bar
- **Close Search**: Click outside or X button
- **Result Action**: Click any result card

### Keyboard Shortcuts (Future)
- `Ctrl+K` or `Cmd+K` - Focus search
- `Escape` - Close search
- `Arrow Keys` - Navigate results
- `Enter` - Open selected result

### Help Resources
- See sample searches above
- Check troubleshooting section
- Review test scenarios
- Contact system administrator

---

**Version**: 1.0  
**Last Updated**: February 24, 2026  
**Status**: Production Ready (with backend integration)  
**Compatibility**: Flutter 3.10.7+  
**Dependencies**: google_fonts, lucide_icons, flutter/material
