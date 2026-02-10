import 'package:flutter/foundation.dart';

class OfficeRequest {
  OfficeRequest({
    required this.id,
    required this.office,
    required this.requestType,
    required this.details,
    required this.createdAt,
    this.status = 'pending',
    this.department,
    this.priority,
    this.targetAudience,
    this.proposedAnnouncement,
    this.isAnnouncement = false,
  });

  final int id;
  final String office;
  String requestType;
  String details;
  final DateTime createdAt;
  String status; // 'pending','approved','rejected'
  
  // Announcement-specific fields
  final String? department;
  final String? priority;
  final String? targetAudience;
  final String? proposedAnnouncement;
  final bool isAnnouncement;
}

class OfficeRequestService {
  OfficeRequestService._internal();
  static final OfficeRequestService _instance = OfficeRequestService._internal();
  factory OfficeRequestService() {
    // ensure demo data seeded on first access
    _instance._seedDemoData();
    return _instance;
  }

  final ValueNotifier<List<OfficeRequest>> notifier = ValueNotifier([]);
  int _nextId = 1;

  // Seed some demo data once for testing/development.
  // This helper is invoked from the singleton constructor area when first loaded.
  // It only adds entries if the notifier is empty to avoid duplicates.
  void _seedDemoData() {
    if (notifier.value.isNotEmpty) return;
    notifier.value = [
      OfficeRequest(
        id: _nextId++,
        office: 'admissions',
        requestType: 'Application Status',
        details: 'Inquiry about application #A12345 status.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'pending',
      ),
      OfficeRequest(
        id: _nextId++,
        office: 'registrar',
        requestType: 'Transcript Request',
        details: 'Requesting transcript for Jane Doe.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        status: 'approved',
      ),
      OfficeRequest(
        id: _nextId++,
        office: 'accounting',
        requestType: 'Refund Request',
        details: 'Refund for overpayment invoice #INV-789.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        status: 'pending',
      ),
      OfficeRequest(
        id: _nextId++,
        office: 'admissions',
        requestType: 'Schedule Campus Tour',
        details: 'Family tour request for next week.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'archived',
      ),
      // Announcements
      OfficeRequest(
        id: _nextId++,
        office: 'admissions',
        requestType: 'Application Status Update',
        details: 'Congratulations to all Fall 2026 applicants! Your preliminary application review is now complete. Please log into your Student Portal by Friday, February 20th, to check for any missing \'Action Items.\'\n\nCommon missing documents include:\n• Final High School Transcripts\n• Letters of Recommendation\n• Proof of Residency\n\nFailure to submit these by the deadline may result in a delay in your admission decision.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pending',
        department: 'Undergraduate Admissions',
        priority: 'High',
        targetAudience: 'Prospective Students / Applicants',
        proposedAnnouncement: 'Congratulations to all Fall 2026 applicants! Your preliminary application review is now complete. Please log into your Student Portal by Friday, February 20th, to check for any missing \'Action Items.\'\n\nCommon missing documents include:\n• Final High School Transcripts\n• Letters of Recommendation\n• Proof of Residency\n\nFailure to submit these by the deadline may result in a delay in your admission decision.',
        isAnnouncement: true,
      ),
      OfficeRequest(
        id: _nextId++,
        office: 'registrar',
        requestType: 'Spring Semester Registration',
        details: 'Spring 2026 registration is now open for all continuing students.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'pending',
        department: 'Records and Registration',
        priority: 'High',
        targetAudience: 'Continuing Students',
        proposedAnnouncement: 'Spring 2026 course registration begins on Monday, February 16th, 2026. All continuing students are required to register by Friday, March 5th. Please visit the Student Portal to select your courses. Course codes and schedules are available in the Course Catalog.',
        isAnnouncement: true,
      ),
      OfficeRequest(
        id: _nextId++,
        office: 'accounting',
        requestType: 'Payment Deadline Notice',
        details: 'Final payment deadline for Spring 2026 semester.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'pending',
        department: 'Accounting and Finance',
        priority: 'Critical',
        targetAudience: 'All Students',
        proposedAnnouncement: 'IMPORTANT: The final payment deadline for Spring 2026 tuition and fees is Thursday, March 1st, 2026. Students who do not pay by this date will have a hold placed on their account, which may prevent registration for future semesters. Payment can be made online through the Student Portal or at the cashier\'s office. Contact Accounting if you need a payment plan.',
        isAnnouncement: true,
      ),
    ];
  }
  void addRequest({required String office, required String requestType, required String details}) {
    final req = OfficeRequest(
      id: _nextId++,
      office: office,
      requestType: requestType,
      details: details,
      createdAt: DateTime.now(),
    );
    notifier.value = [req, ...notifier.value];
  }

  List<OfficeRequest> getAll() => notifier.value;

  void approve(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'approved';
      return r;
    }).toList();
    notifier.value = list;
  }

  void reject(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'rejected';
      return r;
    }).toList();
    notifier.value = list;
  }

  void updateRequest(int id, {String? requestType, String? details}) {
    final list = notifier.value.map((r) {
      if (r.id == id) {
        if (requestType != null) r.requestType = requestType;
        if (details != null) r.details = details;
      }
      return r;
    }).toList();
    notifier.value = list;
  }

  void archive(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'archived';
      return r;
    }).toList();
    notifier.value = list;
  }

  void restore(int id) {
    final list = notifier.value.map((r) {
      if (r.id == id) r.status = 'pending';
      return r;
    }).toList();
    notifier.value = list;
  }
}
