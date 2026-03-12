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

  // --- IDENTITY QUERIES ---

  /// Fetches the specific profile for the login screen
  Future<Map<String, dynamic>?> getProfile(
      String idNumber, String password) async {
    final response = await _client
        .from('profiles')
        .select('*, student_details(*), employee_details(*)')
        .eq('user_id_number', idNumber)
        .eq('password_hash', password)
        .maybeSingle();
    return response;
  }

  /// Fetches a specific profile by ID
  Future<Map<String, dynamic>?> getProfileById(String id) async {
    return await _client.from('profiles').select().eq('id', id).maybeSingle();
  }

  /// NEW: Identifies the first available Registrar to initialize a student thread
  Future<Map<String, dynamic>?> getRegistrarContact() async {
    return await _client
        .from('profiles')
        .select('id, fn, ln, role')
        .eq('role', 'registrar')
        .limit(1)
        .maybeSingle();
  }

  // --- REAL-TIME STREAMS ---

  /// Watches a specific student's profile for changes (GWA, Balance, etc.)
  Stream<List<Map<String, dynamic>>> streamPersonalProfile(String profileId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id']).eq('id', profileId);
  }

  /// Watches a student's specific payments
  Stream<List<Map<String, dynamic>>> streamPayments(String profileId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id']).eq('student_id', profileId);
  }

  /// Creates a new service request
  Future<void> createRequest(Map<String, dynamic> requestData) async {
    await _client.from('office_requests').insert(requestData);
  }

  /// Sends a message
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    await _client.from('messages').insert(messageData);
  }

  // --- ACCOUNTING & FINANCE ---

  /// Fetches all students with their details for lookup
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _client
        .from('profiles')
        .select('*, student_details(*)')
        .eq('role', 'student');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Updates a student's account balance
  Future<void> updateAccountBalance(String profileId, double newBalance) async {
    await _client
        .from('student_details')
        .update({'account_balance': newBalance}).eq('profile_id', profileId);
  }

  /// Fetches all pending payments
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    final response = await _client
        .from('payments')
        .select('*, profiles(*)')
        .eq('status', 'Pending');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Real-time stream of pending payments
  Stream<List<Map<String, dynamic>>> streamPendingPayments() {
    return _client
        .from('payments')
        .stream(primaryKey: ['id']).eq('status', 'Pending');
  }

  /// Real-time stream of student details (for balance updates)
  Stream<List<Map<String, dynamic>>> streamStudentDetails() {
    return _client.from('student_details').stream(primaryKey: ['profile_id']);
  }
}
