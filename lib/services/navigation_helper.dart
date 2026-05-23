import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Services
import 'supabase_service.dart';

// Import views safely
import '../views/login_view.dart';
import '../views/student_dashboard_view.dart';
import '../components/teacher_dashboard_view.dart';
import '../views/admin_dashboard_view.dart';
import '../views/accounting_dashboard_view.dart';
import '../views/registrar_dashboard_view.dart';
import '../views/hr_dashboard_view.dart';
import '../views/admission_dashboard_view.dart';

// Component/Panel Views
import '../components/program_chair_dashboard_view.dart'; // Verified Path for Program Chair

/// Global navigator key that allows safe, contextless navigation (perfect for logouts)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handles redirection based on user role and runtime platform (Web vs Windows)
void handleLoginRedirect(BuildContext context, Map<String, dynamic> userData) {
  final role = (userData['role'] ?? '').toString().toLowerCase().trim();

  // Standardized callback to safely record logout in Supabase and return to Login Screen
  void logout() async {
    try {
      final userId = userData['id'];
      if (userId != null) {
        // Record Logout Attendance inside Supabase
        await SupabaseService().recordAttendanceLogout(userId);
      }
    } catch (e) {
      debugPrint('Attendance Checkout Logging Failed: $e');
    }

    // Safely clear the entire stack and return to a fresh Login Screen using the global key
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UEMSLoginPage()),
      (route) => false,
    );
  }

  // Define our user categories
  final bool isAcademicUser = (role == 'student' ||
      role == 'teacher' ||
      role == 'professor' ||
      role == 'pchair' ||
      role == 'program_chair');

  if (isAcademicUser) {
    // --- ACADEMIC ROUTING: Accessible on BOTH Web and Windows Desktop ---
    Widget target;
    if (role == 'student') {
      target = StudentDashboardView(userData: userData, onLogout: logout);
    } else if (role == 'teacher' || role == 'professor') {
      target = TeacherDashboardView(userData: userData, onLogout: logout);
    } else {
      // program_chair or pchair
      target = ProgramChairDashboardView(userData: userData, onLogout: logout);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  } else {
    // --- ADMINISTRATIVE ROUTING: Restricted to Native Windows Desktop ---
    if (kIsWeb) {
      // If administrative staff attempts to access via a web browser:
      _showAccessDeniedDialog(
        context,
        'Access Restricted',
        'Your administrative role (${role.toUpperCase()}) requires the Windows Desktop Application to access UEMS management systems.',
      );
    } else {
      // Running on Windows Desktop, allow access:
      Widget target;
      if (role == 'admin') {
        target = AdminDashboardView(userData: userData, onLogout: logout);
      } else if (role == 'accounting') {
        target = AccountingDashboardView(userData: userData, onLogout: logout);
      } else if (role == 'registrar' || role == 'hr' || role == 'admission') {
        if (role == 'registrar') {
          target = RegistrarDashboardView(userData: userData, onLogout: logout);
        } else if (role == 'hr') {
          target = HRDashboardView(userData: userData, onLogout: logout);
        } else {
          target = AdmissionDashboardView(userData: userData, onLogout: logout);
        }
      } else {
        _showAccessDeniedDialog(
          context,
          'Unrecognized Role',
          'Your account role (${role.toUpperCase()}) is not provisioned on this platform.',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target),
      );
    }
  }
}

void _showAccessDeniedDialog(
    BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.amber, size: 28),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
