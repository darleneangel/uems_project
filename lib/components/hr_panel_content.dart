import 'package:flutter/material.dart';
import 'hr_panels/hr_overview_panel.dart';
import 'hr_panels/employee_management_panel.dart';
import 'shared/messaging_panel.dart';
import 'shared/staff_profile_portal.dart';
import 'hr_panels/hr_attendance_panel.dart';
import 'hr_panels/hr_leave_requests_panel.dart';
import 'hr_panels/hr_payroll_bridge_panel.dart';
import 'hr_panels/hr_employee_list_panel.dart';

class HRPanelContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const HRPanelContent({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    // This router separates the HR modules to keep the Dashboard file lean.
    switch (selectedIndex) {
      case 0:
        // High-level analytics and staff distribution
        return HROverviewPanel(isDarkMode: isDarkMode, userData: userData);
      case 1:
        // Detailed CRUD + Archiving + Salary Management
        return EmployeeManagementPanel(
            isDarkMode: isDarkMode, userData: userData);
      case 2:
        // Communication portal for employees
        return MessagingPanel(isDarkMode: isDarkMode, userData: userData);
      case 3:
        // Sub-module for Attendance & Leave or Contracts & Salary
        return HRAttendancePanel(isDarkMode: isDarkMode, userData: userData);
      case 4:
        // Staff Profile Portal
        return StaffProfilePortal(isDarkMode: isDarkMode, userData: userData);
      case 5:
        return HRLeaveRequestPanel(isDarkMode: isDarkMode, userData: userData);
      case 6:
        return HRPayrollBridgePanel(isDarkMode: isDarkMode, userData: userData);
      case 7:
        return HrEmployeeListPanel(isDarkMode: isDarkMode, userData: userData);

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined,
                  size: 64,
                  color: isDarkMode ? Colors.white24 : Colors.black12),
              const SizedBox(height: 16),
              const Text("Select an HR Module",
                  style: TextStyle(color: Colors.blueGrey)),
            ],
          ),
        );
    }
  }
}
