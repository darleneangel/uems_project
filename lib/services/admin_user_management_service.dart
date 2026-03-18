import 'dart:async';

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

class AdminManagedAccount {
  AdminManagedAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.idNumber,
    required this.department,
    required this.phone,
    required this.role,
    required this.status,
    required this.category,
    this.specialization,
    required this.createdAt,
    this.createdBy = 'super_admin',
  });

  final String id;
  String fullName;
  String email;
  String idNumber;
  String department;
  String phone;
  String role;
  String status;
  String category; // administrative | academic
  String? specialization;
  DateTime createdAt;
  String createdBy;
}

class AdminAnalyticsSnapshot {
  const AdminAnalyticsSnapshot({
    required this.totalAccounts,
    required this.students,
    required this.teachers,
    required this.programChairs,
    required this.adminStaff,
    required this.hr,
    required this.active,
    required this.suspended,
    required this.byRole,
  });

  final int totalAccounts;
  final int students;
  final int teachers;
  final int programChairs;
  final int adminStaff;
  final int hr;
  final int active;
  final int suspended;
  final Map<String, int> byRole;
}

class AdminUserManagementService {
  AdminUserManagementService._internal() {
    _seedDemoData();
  }

  static final AdminUserManagementService _instance =
      AdminUserManagementService._internal();

  factory AdminUserManagementService() => _instance;

  final ValueNotifier<List<AdminManagedAccount>> notifier = ValueNotifier([]);
  int _nextSeed = 1;

  void _seedDemoData() {
    if (notifier.value.isNotEmpty) return;

    notifier.value = [
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Sarah Johnson',
        email: 'sarah.johnson@uems.edu',
        idNumber: 'EMP001',
        department: 'HR',
        phone: '+1-555-0101',
        role: 'Administrator',
        status: 'Active',
        category: 'administrative',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Michael Chen',
        email: 'michael.chen@uems.edu',
        idNumber: 'EMP002',
        department: 'Accounting',
        phone: '+1-555-0102',
        role: 'Staff',
        status: 'Active',
        category: 'administrative',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Emily Rodriguez',
        email: 'emily.rodriguez@uems.edu',
        idNumber: 'EMP003',
        department: 'Registrar',
        phone: '+1-555-0103',
        role: 'Staff',
        status: 'Active',
        category: 'administrative',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'David Kim',
        email: 'david.kim@uems.edu',
        idNumber: 'EMP004',
        department: 'Admission',
        phone: '+1-555-0104',
        role: 'Staff',
        status: 'Inactive',
        category: 'administrative',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Dr. Robert Anderson',
        email: 'robert.anderson@uems.edu',
        idNumber: 'STF001',
        department: 'Computer Science',
        phone: '+1-555-0201',
        role: 'Program Chair',
        specialization: 'Artificial Intelligence',
        status: 'Active',
        category: 'academic',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Prof. Maria Rodriguez',
        email: 'maria.rodriguez@uems.edu',
        idNumber: 'STF002',
        department: 'Mathematics',
        phone: '+1-555-0202',
        role: 'Teacher',
        specialization: 'Calculus',
        status: 'Active',
        category: 'academic',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'James Wilson',
        email: 'james.wilson@uems.edu',
        idNumber: 'STD001',
        department: 'Business Administration',
        phone: '+1-555-0203',
        role: 'Student',
        specialization: 'Finance',
        status: 'Active',
        category: 'academic',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      AdminManagedAccount(
        id: _nextId(),
        fullName: 'Lisa Thompson',
        email: 'lisa.thompson@uems.edu',
        idNumber: 'STD002',
        department: 'Engineering',
        phone: '+1-555-0204',
        role: 'Student',
        specialization: 'Mechanical Engineering',
        status: 'Active',
        category: 'academic',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  String _nextId() {
    final id = _nextSeed.toString().padLeft(4, '0');
    _nextSeed++;
    return 'admin_managed_$id';
  }

  List<AdminManagedAccount> getAccounts({String? category}) {
    final accounts = notifier.value;
    if (category == null) return accounts;
    return accounts.where((a) => a.category == category).toList();
  }

  AdminManagedAccount createAccount({
    required String fullName,
    required String email,
    required String idNumber,
    required String department,
    required String phone,
    required String role,
    required String category,
    String status = 'Active',
    String? specialization,
  }) {
    final account = AdminManagedAccount(
      id: _nextId(),
      fullName: fullName,
      email: email,
      idNumber: idNumber,
      department: department,
      phone: phone,
      role: role,
      status: status,
      category: category,
      specialization: specialization,
      createdAt: DateTime.now(),
    );

    notifier.value = [account, ...notifier.value];
    unawaited(_persistCreate(account));
    return account;
  }

  void updateAccount({
    required String id,
    required String fullName,
    required String email,
    required String idNumber,
    required String department,
    required String phone,
    required String role,
    required String category,
    String? specialization,
  }) {
    notifier.value = notifier.value.map((a) {
      if (a.id != id) return a;
      a.fullName = fullName;
      a.email = email;
      a.idNumber = idNumber;
      a.department = department;
      a.phone = phone;
      a.role = role;
      a.category = category;
      a.specialization = specialization;
      unawaited(_persistUpdate(a));
      return a;
    }).toList();
  }

  void deleteAccount(String id) {
    final existing = notifier.value.where((a) => a.id == id).toList();
    notifier.value = notifier.value.where((a) => a.id != id).toList();
    if (existing.isNotEmpty) {
      unawaited(_persistDelete(existing.first));
    }
  }

  void suspendAccount(String id) {
    _updateStatus(id, 'Suspended');
  }

  void activateAccount(String id) {
    _updateStatus(id, 'Active');
  }

  void setStatus(String id, String status) {
    _updateStatus(id, status);
  }

  void _updateStatus(String id, String status) {
    notifier.value = notifier.value.map((a) {
      if (a.id == id) {
        a.status = status;
        unawaited(_persistStatus(a));
      }
      return a;
    }).toList();
  }

  Future<void> _persistCreate(AdminManagedAccount account) async {
    try {
      final client = SupabaseService().client;
      final names = _splitName(account.fullName);
      await client.from('profiles').insert({
        'fn': names.$1,
        'ln': names.$2,
        'role': _mapRoleToProfileRole(account.role, account.department),
        'user_id_number': account.idNumber,
        'email': account.email,
        'status': account.status,
      });
    } catch (_) {
      // Keep local operation successful even if DB schema differs.
    }
  }

  Future<void> _persistUpdate(AdminManagedAccount account) async {
    try {
      final client = SupabaseService().client;
      final names = _splitName(account.fullName);
      await client.from('profiles').update({
        'fn': names.$1,
        'ln': names.$2,
        'role': _mapRoleToProfileRole(account.role, account.department),
        'email': account.email,
        'status': account.status,
      }).eq('user_id_number', account.idNumber);
    } catch (_) {
      // Keep local operation successful even if DB schema differs.
    }
  }

  Future<void> _persistDelete(AdminManagedAccount account) async {
    try {
      final client = SupabaseService().client;
      await client
          .from('profiles')
          .delete()
          .eq('user_id_number', account.idNumber);
    } catch (_) {
      // Keep local operation successful even if DB schema differs.
    }
  }

  Future<void> _persistStatus(AdminManagedAccount account) async {
    try {
      final client = SupabaseService().client;
      await client.from('profiles').update({
        'status': account.status,
        'is_active': account.status == 'Active',
      }).eq('user_id_number', account.idNumber);
    } catch (_) {
      // Keep local operation successful even if DB schema differs.
    }
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return ('Unknown', 'User');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  String _mapRoleToProfileRole(String role, String department) {
    final lowerRole = role.toLowerCase();
    final lowerDept = department.toLowerCase();

    if (lowerRole == 'student') return 'student';
    if (lowerRole == 'teacher') return 'professor';
    if (lowerRole == 'program chair') return 'pchair';
    if (lowerDept == 'hr') return 'hr';
    if (lowerDept == 'accounting') return 'accounting';
    if (lowerDept == 'registrar') return 'registrar';
    if (lowerDept == 'admission') return 'admission';
    return 'admin';
  }

  AdminAnalyticsSnapshot getLocalAnalytics() {
    final all = notifier.value;
    final byRole = <String, int>{};
    for (final a in all) {
      byRole[a.role] = (byRole[a.role] ?? 0) + 1;
    }

    int countRole(String role) => all.where((a) => a.role == role).length;

    final adminStaffDepartments = {'Accounting', 'Registrar', 'Admission'};
    final adminStaff = all.where((a) {
      return adminStaffDepartments.contains(a.department);
    }).length;

    return AdminAnalyticsSnapshot(
      totalAccounts: all.length,
      students: countRole('Student'),
      teachers: countRole('Teacher'),
      programChairs: countRole('Program Chair'),
      adminStaff: adminStaff,
      hr: all.where((a) => a.department == 'HR').length,
      active: all.where((a) => a.status == 'Active').length,
      suspended: all.where((a) => a.status == 'Suspended').length,
      byRole: byRole,
    );
  }

  Future<AdminAnalyticsSnapshot> fetchDatabaseAnalytics() async {
    final client = SupabaseService().client;
    final local = getLocalAnalytics();

    try {
      final rows = await client.from('profiles').select('role');
      final roleRows = List<Map<String, dynamic>>.from(rows);
      if (roleRows.isEmpty) return local;

      final byRole = <String, int>{};
      for (final row in roleRows) {
        final role = (row['role'] as String?)?.toLowerCase().trim();
        if (role == null || role.isEmpty) continue;
        byRole[role] = (byRole[role] ?? 0) + 1;
      }

      int countRoleLower(String role) => byRole[role] ?? 0;

      int active = local.active;
      int suspended = local.suspended;
      try {
        final statusRows =
            await client.from('profiles').select('status, is_active');
        final casted = List<Map<String, dynamic>>.from(statusRows);
        active = 0;
        suspended = 0;
        for (final row in casted) {
          final status = (row['status'] as String?)?.toLowerCase();
          final isActive = row['is_active'];
          if (status == 'suspended') {
            suspended++;
          } else if (status == 'active' || isActive == true) {
            active++;
          }
        }
      } catch (_) {
        // Fallback to local status if DB schema doesn't expose these fields.
      }

      return AdminAnalyticsSnapshot(
        totalAccounts: roleRows.length,
        students: countRoleLower('student'),
        teachers: countRoleLower('teacher') + countRoleLower('professor'),
        programChairs:
            countRoleLower('pchair') + countRoleLower('program chair'),
        adminStaff: countRoleLower('accounting') +
            countRoleLower('registrar') +
            countRoleLower('admission'),
        hr: countRoleLower('hr'),
        active: active,
        suspended: suspended,
        byRole: byRole,
      );
    } catch (_) {
      return local;
    }
  }

  String generatePopulationReport(AdminAnalyticsSnapshot snapshot) {
    final lines = <String>[
      'UEMS ACCOUNT POPULATION REPORT',
      'Generated: ${DateTime.now()}',
      '--------------------------------',
      'Total Accounts: ${snapshot.totalAccounts}',
      'Students: ${snapshot.students}',
      'Teachers: ${snapshot.teachers}',
      'Program Chairs: ${snapshot.programChairs}',
      'Administrative Staff: ${snapshot.adminStaff}',
      'HR: ${snapshot.hr}',
      'Active: ${snapshot.active}',
      'Suspended: ${snapshot.suspended}',
      '--------------------------------',
      'Role Breakdown:',
    ];

    final entries = snapshot.byRole.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final e in entries) {
      lines.add('- ${e.key}: ${e.value}');
    }

    return lines.join('\n');
  }
}
