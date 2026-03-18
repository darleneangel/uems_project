import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'office_request_view.dart';

class OfficesListView extends StatelessWidget {
  const OfficesListView({super.key});

  static const List<Map<String, dynamic>> offices = [
    {'key': 'registrar', 'title': 'Registrar / Records', 'icon': LucideIcons.clipboard},
    {'key': 'cashier', 'title': 'Cashier / Payments', 'icon': LucideIcons.creditCard},
    {'key': 'financial_aid', 'title': 'Financial Aid & Scholarships', 'icon': LucideIcons.award},
    {'key': 'library', 'title': 'Library Services', 'icon': LucideIcons.bookOpen},
    {'key': 'student_affairs', 'title': 'Student Affairs', 'icon': LucideIcons.users},
    {'key': 'health', 'title': 'Health Services', 'icon': LucideIcons.heart},
    {'key': 'it', 'title': 'IT Helpdesk / Accounts', 'icon': LucideIcons.hardDrive},
    {'key': 'career', 'title': 'Career Services', 'icon': LucideIcons.briefcase},
    {'key': 'alumni', 'title': 'Alumni & Degree Verification', 'icon': LucideIcons.award},
    {'key': 'exams', 'title': 'Examinations / Academic Affairs', 'icon': LucideIcons.fileText},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offices & Requests'),
        backgroundColor: const Color(0xFF2E1065),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 2,
          children: offices.map((o) {
            return InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OfficeRequestView(officeKey: o['key'], officeTitle: o['title'])));
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(o['icon'], color: Colors.white, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      o['title'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Text('Requests & Documents', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
