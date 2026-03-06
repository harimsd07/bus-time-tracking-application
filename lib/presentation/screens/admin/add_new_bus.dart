import 'package:bus_time_track/core/data/services/api_client.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class AddNewBus extends StatefulWidget {
  const AddNewBus({super.key});

  @override
  State<AddNewBus> createState() => _AddNewBusState();
}

class _AddNewBusState extends State<AddNewBus> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    // Logic: Using ApiClient ensures the admin's auth_token is included [cite: 2026-02-24]
    final response = await ApiClient().post('/admin/add-bus', {
      'busNameOrbusNo': _nameController.text.trim(),
      'vehicle_no': _vehicleNoController.text.trim(),
      // Logic: Setting initial coordinates to 0 to prevent "Ghost LIVE" badges [cite: 2026-02-24]
      'latitude': 0.0,
      'longitude': 0.0,
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (response.statusCode == 201) {
        Navigator.pop(context); // Return to dashboard on success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register New Bus")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Bus Name/No"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _vehicleNoController,
                decoration: const InputDecoration(labelText: "Vehicle Plate No"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 40),
              _isSubmitting 
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _submitBus, child: const Text("SAVE VEHICLE")),
            ],
          ),
        ),
      ),
    );
  }
}