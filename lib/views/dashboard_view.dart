import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // The "Enroll Now" button from the top right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {}, // Enrollment function
              icon: const Icon(Icons.touch_app, size: 18),
              label: const Text("Enroll Now"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            ),
          )
        ],
      ),
      drawer: _buildSidebar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Home > Dashboard", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            _buildEnrollmentTrack(),
            const SizedBox(height: 30),
            _buildAnnouncements(),
          ],
        ),
      ),
    );
  }

  // 1. Sidebar Navigation (Replacing the Baste left panel)
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.white),
            child: Center(child: Text("PORTAL LOGO", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          _sidebarItem(Icons.dashboard, "Dashboard", isSelected: true),
          _sidebarItem(Icons.list_alt, "Subject Load"),
          _sidebarItem(Icons.assessment, "Assessment"),
          _sidebarItem(Icons.book, "Grade Book"),
          _sidebarItem(Icons.verified_user, "Clearance"),
          const Divider(),
          _sidebarItem(Icons.person, "KURT ANDREI"),
          _sidebarItem(Icons.health_and_safety, "Health Declaration"),
          _sidebarItem(Icons.logout, "Logout", color: Colors.red),
        ],
      ),
    );
  }

  // 2. The Enrollment Track (The Green Progress Bar)
  Widget _buildEnrollmentTrack() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enrollment Tracks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("School Year: 2025-2026 | Semester: 2nd Semester", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 25),
            
            // Progress Bar Container
            Stack(
              children: [
                Container(
                  height: 25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.85, // Current progress percentage
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(colors: [Colors.green[900]!, Colors.green[700]!]),
                    ),
                    child: const Center(
                      child: Text("You are Now Enrolled", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusLabel("Application Submitted"),
                _StatusLabel("Paid", isCheck: true),
                _StatusLabel("Advising"),
                _StatusLabel("Assessment", color: Colors.green, isBold: true),
              ],
            ),
            const SizedBox(height: 30),
            
            // Upload Button Section
            const Text("For BANK PAYMENT, upload a picture of your payment/deposit slip here."),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {}, // File picker logic
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
              child: const Text("Upload & Send"),
            ),
            const Text("NOTED: You should be in the payment step to be able to upload.", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 3. Announcements Section
  Widget _buildAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Announcements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.campaign, color: Colors.white)),
            title: const Text("Academic Affairs Office"),
            subtitle: const Text("Grades for the 2nd Semester are now available for viewing. Check your Grade Book."),
            trailing: const Text("03/26/2026", style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(IconData icon, String title, {bool isSelected = false, Color color = Colors.black54}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : color),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.blue : color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {},
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final bool isCheck;
  final Color color;
  final bool isBold;
  const _StatusLabel(this.label, {this.isCheck = false, this.color = Colors.black, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCheck) const Icon(Icons.check_circle, size: 12, color: Colors.green),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}