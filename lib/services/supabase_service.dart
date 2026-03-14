import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  /// Initializes the Supabase client
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ipmkemontxkxzfymidej.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwbWtlbW9udHhreHpmeW1pZGVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjMxNzcsImV4cCI6MjA4ODYzOTE3N30.oJxVpgxwmXUxyTWi-jC8mKuTkUP4RYgaqmin-Kxn5ms',
    );
  }

  // --- IDENTITY & CONTEXT QUERIES ---

  /// Fetches the profile for login using the numeric User ID Number (e.g. 6001, 2031)
  Future<Map<String, dynamic>?> getProfile(
      String idNumber, String password) async {
    return await _client
        .from('profiles')
        .select('*, student_details(*), employee_details(*)')
        .ilike('user_id_number', idNumber)
        .eq('password_hash', password)
        .maybeSingle();
  }

  /// PROGRAM CHAIR: Resolves the managed department based on the 4-digit ID
  Future<Map<String, dynamic>?> getChairContext(String userIdNumber) async {
    return await _client
        .from('employee_details')
        .select(
            'department_id, departments(name), profiles!inner(user_id_number)')
        .eq('profiles.user_id_number', userIdNumber)
        .maybeSingle();
  }

  // --- ACADEMIC & FACULTY MANAGEMENT ---

  /// UNIVERSAL ACCESS: Fetches specialists in a specific Dept OR global Gen Ed faculty
  Future<List<Map<String, dynamic>>> getFacultyForChair(String deptId) async {
    return await client
        .from('profiles')
        .select(
            'id, fn, ln, employee_details!inner(department_id, faculty_type)')
        // FIX: Wrapped "Gen Ed" in double quotes to handle the space in the PostgREST parser
        .or('faculty_type.eq."Gen Ed", department_id.eq.$deptId',
            referencedTable: 'employee_details');
  }

  /// ENROLLMENT QUEUE: Finds students in the Dept who are Enrolled but have NO LOAD
  Future<List<Map<String, dynamic>>> getStudentQueue(String chairDeptId) async {
    final response = await _client
        .from('profiles')
        .select('''
          *, 
          student_details!inner(*, courses!inner(*), year_levels!inner(*)), 
          study_loads!study_loads_student_id_fkey(id)
        ''') // FIX: Explicitly defined relationship key to avoid PGRST201 ambiguity
        .eq('role', 'student')
        .eq('student_details.enrollment_status', 'Enrolled')
        .eq('student_details.courses.department_id', chairDeptId);

    // Filter students where study_loads list is empty
    return List<Map<String, dynamic>>.from(response).where((s) {
      return (s['study_loads'] as List).isEmpty;
    }).toList();
  }

  /// BATCH ACTION: Syncs multiple study loads to the cloud ledger
  Future<void> batchAssignSubjects(List<Map<String, dynamic>> inserts) async {
    await _client.from('study_loads').insert(inserts);
  }

  /// CATALOG CRUD: Adds a new subject to the institutional catalog
  Future<void> addSubjectToCatalog(Map<String, dynamic> subjectData) async {
    await _client.from('subjects').insert(subjectData);
  }

  // --- REAL-TIME STREAMS ---

  /// Watches a student's profile for live updates (GWA/Balance)
  Stream<List<Map<String, dynamic>>> streamPersonalProfile(String profileId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id']).eq('id', profileId);
  }

  /// Watches student study loads for schedule changes
  Stream<List<Map<String, dynamic>>> streamStudyLoads(String profileId) {
    return _client
        .from('study_loads')
        .stream(primaryKey: ['id']).eq('student_id', profileId);
  }

  // --- REGISTRAR & MESSAGING ---

  Future<Map<String, dynamic>?> getRegistrarContact() async {
    return await _client
        .from('profiles')
        .select('id, fn, ln')
        .eq('role', 'registrar')
        .limit(1)
        .maybeSingle();
  }

  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    await _client.from('messages').insert(messageData);
  }

  Future<void> createRequest(Map<String, dynamic> requestData) async {
    await _client.from('office_requests').insert(requestData);
  }

  // --- ACCOUNTING & FINANCE ---

  Future<void> updateAccountBalance(String profileId, double newBalance) async {
    await _client
        .from('student_details')
        .update({'account_balance': newBalance}).eq('profile_id', profileId);
  }

  Stream<List<Map<String, dynamic>>> streamPendingPayments() {
    return _client
        .from('payments')
        .stream(primaryKey: ['id']).eq('status', 'Pending');
  }
}
