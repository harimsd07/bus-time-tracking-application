import 'package:bus_time_track/core/data/services/driver_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// New Architecture Imports [cite: 2026-02-24]
import '../../../core/config/app_config.dart';

class DriverBroadcastScreen extends StatefulWidget {
  final Map
  busData; // Logic: Expects bus details from the selection list [cite: 2026-02-24]

  const DriverBroadcastScreen({super.key, required this.busData});

  @override
  State<DriverBroadcastScreen> createState() => _DriverBroadcastScreenState();
}

class _DriverBroadcastScreenState extends State<DriverBroadcastScreen> {
  // Logic: Access the singleton to prevent duplicate GPS timers [cite: 2026-02-24]
  final DriverService _driverService = DriverService();
  int _updatesSent = 0;
  StreamSubscription? _updateSubscription;

  @override
  void initState() {
    super.initState();
    // Logic: Sync with existing service state if a trip is already running [cite: 2026-02-24]
    _updatesSent = _driverService.updateCount;

    // Logic: Listen to the central service for real-time broadcast counts [cite: 2026-02-24]
    _updateSubscription = _driverService.updateStream.listen((count) {
      if (mounted) {
        setState(() {
          _updatesSent = count;
        });
      }
    });
  }

  Future<void> _toggleBroadcast() async {
    try {
      if (_driverService.isRunning) {
        // Logic: Gracefully stop the background GPS service [cite: 2026-02-24]
        _driverService.stopTrip();
      } else {
        // Logic: Start trip using the specific ID passed from the list [cite: 2026-02-24]
        final int busId = int.parse(widget.busData['id'].toString());
        await _driverService.startTrip(busId);
      }

      // Logic: Refresh UI to show the new button state [cite: 2026-02-24]
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Broadcast Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Logic: Cancel UI listener, but DriverService keeps running [cite: 2026-02-24]
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = _driverService.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Location Broadcast",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logic: Animated feedback indicating active transmission [cite: 2026-02-24]
            Stack(
              alignment: Alignment.center,
              children: [
                if (isLive) _buildRadarAnimation(),
                Icon(
                  Icons.radar_rounded,
                  size: 120,
                  color: isLive ? Colors.orange : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              isLive ? "Broadcasting Live..." : "Ready to start",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Updates Sent: $_updatesSent",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _toggleBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLive ? Colors.redAccent : AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isLive ? "STOP BROADCAST" : "START BROADCAST",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, double value, child) {
        return Container(
          width: 120 + (value * 100),
          height: 120 + (value * 100),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(1 - value),
          ),
        );
      },
      onEnd:
          () => setState(
            () {},
          ), // Logic: Re-trigger the pulse effect [cite: 2026-02-24]
    );
  }
}
