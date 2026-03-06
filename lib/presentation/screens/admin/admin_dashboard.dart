import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../shared/widgets/menu_card.dart';
import 'add_new_bus.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Control")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            MenuCard(
              title: "Register New Bus",
              subtitle: "Add vehicle data to system",
              icon: Icons.add_circle_outline_rounded,
              color: AppConfig.primaryColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddNewBus()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
