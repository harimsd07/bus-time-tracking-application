import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:bus_time_track/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverBroadcastScreen extends StatefulWidget {
  const DriverBroadcastScreen({super.key});

  @override
  State<DriverBroadcastScreen> createState() => _DriverBroadcastScreenState();
}

class _DriverBroadcastScreenState extends State<DriverBroadcastScreen> {
  bool isBroadcasting = false;
  Timer? _timer;
  String _status = "Ready to start";

  // Logic: Handles the start/stop toggle for location sharing
  Future<void> _toggleBroadcast() async {
    if (isBroadcasting) {
      _timer?.cancel();
      setState(() {
        isBroadcasting = false;
        _status = "Broadcast Stopped";
      });
    } else {
      await _startLocationService();
    }
  }

  Future<void> _startLocationService() async {
    // Logic: Standard permission check for Nothing Phone 2a
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() {
        isBroadcasting = true;
        _status = "Broadcasting Live...";
      });

      // Logic: Update backend every 10 seconds
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _sendLocationToBackend(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _sendLocationToBackend(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      // Logic: Matches your new backend endpoint and validation rules
      await http.post(
        Uri.parse("${AppConfig.baseUrl}/bus/update-location"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'id': '1', // Logic: This should ideally be the bus assigned to the driver
          'latitude': lat.toString(),
          'longitude': lng.toString(),
        },
      );
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Logic: Always cancel timers to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Broadcast")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logic: Visual feedback for the driver
            Icon(
              Icons.radar_rounded,
              size: 120,
              color: isBroadcasting ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _toggleBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: isBroadcasting ? Colors.redAccent : AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                isBroadcasting ? "STOP BROADCAST" : "START BROADCAST",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}