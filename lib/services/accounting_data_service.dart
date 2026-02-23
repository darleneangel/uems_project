import 'package:flutter/foundation.dart';

class AccountingDataService extends ChangeNotifier {
  // Singleton pattern for easy access across the module
  static final AccountingDataService _instance =
      AccountingDataService._internal();
  factory AccountingDataService() => _instance;
  AccountingDataService._internal();

  final List<Map<String, dynamic>> _students = [
    {
      'id': '2024-001',
      'name': 'Darlene Angel',
      'course': 'BSCS',
      'year': '4A',
      'section': 'BSCS 4A',
      'balance': 15000.0,
      'status': 'Pending',
      'cleared': false,
      'scholarship': 'None',
      'tuition_breakdown': {
        'Midterm Block A': 7500.0,
        'Finals Block B': 7500.0,
      },
      'ledger': [
        {
          'date': '2024-01-15',
          'desc': 'Tuition Fee - 1st Sem',
          'debit': 15000.0,
          'credit': 0.0,
        },
      ],
    },
    {
      'id': '2024-089',
      'name': 'Juan Dela Cruz',
      'course': 'BSIT',
      'year': '1B',
      'section': 'BSIT 1B',
      'balance': 8500.0,
      'status': 'Overdue',
      'cleared': false,
      'scholarship': 'None',
      'tuition_breakdown': {
        'Midterm Block A': 4250.0,
        'Finals Block B': 4250.0,
      },
      'ledger': [
        {
          'date': '2024-01-10',
          'desc': 'Tuition Fee - 1st Sem',
          'debit': 8500.0,
          'credit': 0.0,
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _cartItems = [];

  final List<Map<String, dynamic>> _availableScholarships = [
    {"name": "Academic Excellence", "discount": 1.0, "type": "Merit"},
    {"name": "Athletic Grant", "discount": 0.5, "type": "Athletics"},
    {"name": "Financial Aid", "discount": 0.25, "type": "Needs-Based"},
    {"name": "Presidential Scholarship", "discount": 1.0, "type": "Special"},
  ];

  List<Map<String, dynamic>> get availableScholarships =>
      _availableScholarships;
  List<Map<String, dynamic>> get cartItems => _cartItems;

  double get cartTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + (item['amount'] * item['qty']));

  void addToCart(String category, String item, double amount, {int qty = 1}) {
    _cartItems.add({
      'category': category,
      'item': item,
      'amount': amount,
      'qty': qty,
    });
    notifyListeners();
  }

  void checkoutCart(String studentId, String paymentMethod) {
    final student = getStudent(studentId);
    if (student != null) {
      double total = cartTotal;
      recordPayment(
        studentId,
        total,
        paymentMethod,
        description:
            "Cart Checkout: ${_cartItems.map((e) => e['item']).join(', ')}",
      );
      _cartItems.clear();
      notifyListeners();
    }
  }

  Map<String, dynamic>? getStudent(String id) {
    try {
      return _students.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getAllStudents() => _students;

  void recordPayment(
    String id,
    double amount,
    String method, {
    String? description,
  }) {
    final student = getStudent(id);
    if (student != null) {
      student['balance'] -= amount;
      if (student['balance'] <= 0) {
        student['balance'] = 0.0;
        student['cleared'] = true;
        student['status'] = 'Cleared';
      }
      (student['ledger'] as List).add({
        'date': DateTime.now().toString().split(' ')[0],
        'desc': description ?? "Payment via $method",
        'debit': 0.0,
        'credit': amount,
      });
      notifyListeners();
    }
  }

  bool applyScholarship(String studentId, String scholarshipName) {
    final student = getStudent(studentId);
    final scholarship = _availableScholarships.firstWhere(
      (s) => s['name'] == scholarshipName,
      orElse: () => <String, dynamic>{},
    );

    if (student != null && scholarship.isNotEmpty) {
      student['scholarship'] = scholarshipName;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeScholarship(String studentId) {
    final student = getStudent(studentId);
    if (student != null) {
      student['scholarship'] = 'None';
      notifyListeners();
    }
  }
}
