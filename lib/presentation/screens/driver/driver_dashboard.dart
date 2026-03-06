import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../shared/widgets/menu_card.dart';
import '../../shared/get_bus_time.dart'; // Logic: Reuse for driver to select their bus

class DriverDashboard extends StatelessWidget {
  final String userName;
  const DriverDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Panel")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: $userName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            MenuCard(
              title: "Active Broadcast",
              subtitle: "Share live location with students",
              icon: Icons.radar_rounded,
              color: Colors.orange.shade700,
              // Logic: Redirects to bus selection to start broadcasting
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const GetBusTime(isDriverMode: true))
              ),
            ),
          ],
        ),
      ),
    );
  }
}