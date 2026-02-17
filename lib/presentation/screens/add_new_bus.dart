import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddNewBus extends StatefulWidget {
  const AddNewBus({super.key});

  @override
  State<AddNewBus> createState() => _AddNewBusState();
}

class _AddNewBusState extends State<AddNewBus> {
  bool isLoading = false;

  // Controllers for the form fields
  final TextEditingController busNameController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController pickupStopController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController pickupTimeController = TextEditingController();
  final TextEditingController reachTimeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Bus', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Route Details",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Enter the details of the bus to enable live tracking."),
            const SizedBox(height: 24),

            // Form Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildModernField(
                    controller: busNameController,
                    label: 'Bus Name / Number',
                    hint: 'e.g., Amman - 106',
                    icon: Icons.directions_bus_filled_rounded,
                  ),
                  _buildModernField(
                    controller: vehicleNumberController,
                    label: 'Vehicle Registration No.',
                    hint: 'e.g., TN 45 W 7654',
                    icon: Icons.numbers_rounded,
                  ),
                  _buildModernField(
                    controller: pickupStopController,
                    label: 'Starting Point',
                    hint: 'Enter pickup stop',
                    icon: Icons.location_on_rounded,
                  ),
                  _buildModernField(
                    controller: destinationController,
                    label: 'Destination',
                    hint: 'Enter final destination',
                    icon: Icons.flag_rounded,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          controller: pickupTimeController,
                          label: 'Dep. Time',
                          hint: '09:00 AM',
                          icon: Icons.schedule,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(
                          controller: reachTimeController,
                          label: 'Arr. Time',
                          hint: '10:30 AM',
                          icon: Icons.timer_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveBusToBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Add Bus to System",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern TextField Builder
  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> saveBusToBackend() async {
    // Basic Validation logic added
    if (busNameController.text.isEmpty || vehicleNumberController.text.isEmpty) {
      _showSnackbar("Please fill in the bus name and vehicle number", isError: true);
      return;
    }

    setState(() => isLoading = true);

    // Logic added: Keys mapping to Laravel BusDetail migration
    final body = {
      "busNameOrbusNo": busNameController.text,
      "vehicle_no": vehicleNumberController.text,
      "pick_up_stop": pickupStopController.text,
      "destination": destinationController.text,
      "pickup_time": pickupTimeController.text,
      "reach_destination_time": reachTimeController.text,
      "latitude": 0.0,
      "longitude": 0.0,
    };

    try {
      // Logic added: Local development URL for Android Emulator
      const url = 'http://192.168.1.38/api/addingBusDetail';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        _showSnackbar("Bus details saved successfully!");
      } else {
        _showSnackbar("Failed to save. Check server response.", isError: true);
      }
    } catch (e) {
      _showSnackbar("Connection error. Is your Laravel server running?", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    busNameController.clear();
    vehicleNumberController.clear();
    pickupStopController.clear();
    destinationController.clear();
    pickupTimeController.clear();
    reachTimeController.clear();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}