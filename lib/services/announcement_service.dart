import 'package:flutter/foundation.dart';

class Announcement {
  Announcement({
    required this.id,
    required this.office,
    required this.title,
    required this.content,
    required this.createdAt,
    this.status = 'pending',
    this.attachments,
    this.department,
    this.priority,
    this.targetAudience,
  });

  final int id;
  final String office;
  String title;
  String content;
  final DateTime createdAt;
  String status; // 'pending','approved','rejected','archived'
  List<String>? attachments;
  String? department;
  String? priority;
  String? targetAudience;
}

class AnnouncementService {
  AnnouncementService._internal();
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() {
    _instance._seedDemoData();
    return _instance;
  }

  final ValueNotifier<List<Announcement>> notifier = ValueNotifier([]);
  int _nextId = 1;

  void _seedDemoData() {
    if (notifier.value.isNotEmpty) return;
    notifier.value = [
      Announcement(
        id: _nextId++,
        office: 'admissions',
        title: 'Application Status Update',
        department: 'Undergraduate Admissions',
        priority: 'High',
        targetAudience: 'Prospective Students / Applicants',
        content:
            "Congratulations to all Fall 2026 applicants! Your preliminary application review is now complete. Please log into your Student Portal by Friday, February 20th, to check for any missing 'Action Items.'\n\nCommon missing documents include:\n\nFinal High School Transcripts\n\nLetters of Recommendation\n\nProof of Residency\n\nFailure to submit these by the deadline may result in a delay in your admission decision.",
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        status: 'pending',
      ),
      Announcement(
        id: _nextId++,
        office: 'registrar',
        title: 'Final Exam & Graduation Filing',
        department: 'Office of the Registrar',
        priority: 'Medium',
        targetAudience: 'Graduating Seniors',
        content:
            "The Final Examination Schedule for the current semester is now live. You can view your specific exam dates, times, and room assignments under the 'Academic Records' section.\n\nGraduation Notice:\nIf you intend to graduate in June 2026, you must submit your 'Intent to Graduate' form no later than March 15th. This process is mandatory for degree auditing and diploma ordering. Please contact your academic advisor if you have questions regarding credit requirements.",
        createdAt: DateTime.now().subtract(const Duration(hours: 24)),
        status: 'pending',
      ),
      Announcement(
        id: _nextId++,
        office: 'accounting',
        title: 'Tuition & Refund Schedule',
        department: 'Student Accounts / Bursar',
        priority: 'Critical',
        targetAudience: 'All Enrolled Students',
        content:
            "Important Update regarding Spring 2026 Tuition: Please be advised that the deadline for the second installment of the payment plan is February 28th.\n\nAction Required:\n\nPayments can be made via the 'Finance' tab in the Student Hub.\n\nStudents expecting financial aid refunds must ensure their Direct Deposit information is updated.\n\nA late fee of \$50 will be applied to accounts with outstanding balances after the deadline.",
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: 'pending',
      ),
    ];
  }

  void addAnnouncement({
    required String office,
    required String title,
    required String content,
    List<String>? attachments,
    String? department,
    String? priority,
    String? targetAudience,
  }) {
    final a = Announcement(
      id: _nextId++,
      office: office,
      title: title,
      content: content,
      attachments: attachments,
      department: department,
      priority: priority,
      targetAudience: targetAudience,
      createdAt: DateTime.now(),
    );
    notifier.value = [a, ...notifier.value];
  }

  List<Announcement> getAll() => notifier.value;

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
