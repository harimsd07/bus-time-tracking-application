import 'package:bus_time_track/presentation/screens/driver/driver_panel_screen.dart';
import 'package:flutter/material.dart';
import '../core/utils/role_enums.dart';
import 'screens/student/student_dashboard.dart';

class HomeRouter extends StatelessWidget {
  final UserRole userRole;
  final String userName;

  const HomeRouter({super.key, required this.userRole, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Logic: Precise routing based on the Enum we created [cite: 2026-02-24]
    switch (userRole) {
      case UserRole.student:
        return StudentDashboard(userName: userName);
      case UserRole.driver:
        // Logic: Pass a dummy or last-saved bus map if needed, 
        // but for now, we point to the primary broadcast center [cite: 2026-02-24]
        return DriverPanelScreen(busData: {'id': 1, 'busNameOrbusNo': 'Trial Bus', 'vehicle_no': 'TN-01-2026'});
      default:
        return const Scaffold(body: Center(child: Text("Unauthorized Access")));
    }
  }
}