import 'package:bus_time_track/core/data/services/driver_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/config/app_config.dart';


class DriverPanelScreen extends StatefulWidget {
  final Map busData;
  const DriverPanelScreen({super.key, required this.busData});

  @override
  State<DriverPanelScreen> createState() => _DriverPanelScreenState();
}

class _DriverPanelScreenState extends State<DriverPanelScreen> {
  // Logic: Use the singleton instance for state persistence [cite: 2026-02-24]
  final DriverService _driverService = DriverService();
  
  late bool isDriving;
  late int updateCount;
  late int busId;
  StreamSubscription? _updateSubscription;

  @override
  void initState() {
    super.initState();
    busId = int.parse(widget.busData['id'].toString());

    // Logic Fix: Syncing with public getters in DriverService [cite: 2026-02-24]
    isDriving = _driverService.isRunning;
    updateCount = _driverService.updateCount;

    _updateSubscription = _driverService.updateStream.listen((count) {
      if (mounted) setState(() => updateCount = count);
    });
  }

  void _toggleTrip() async {
    try {
      if (isDriving) {
         _driverService.stopTrip();
      } else {
        await _driverService.startTrip(busId);
      }
      if (mounted) setState(() => isDriving = _driverService.isRunning);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Broadcast Error: $e"), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Driver Dashboard", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 30),
            _buildBusInfoCard(),
            const SizedBox(height: 50),
            _buildActionButton(),
            const SizedBox(height: 40),
            if (isDriving) _buildLiveStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDriving ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDriving ? Icons.sensors_rounded : Icons.sensors_off_rounded, color: isDriving ? Colors.green : Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(isDriving ? "LIVE BROADCASTING" : "OFFLINE", style: TextStyle(color: isDriving ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
      child: Column(
        children: [
          const Icon(Icons.directions_bus_rounded, color: Colors.black87, size: 40),
          const SizedBox(height: 12),
          Text(widget.busData['busNameOrbusNo'] ?? 'Unknown Bus', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Vehicle: ${widget.busData['vehicle_no'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _toggleTrip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 200, width: 200,
        decoration: BoxDecoration(
          color: isDriving ? Colors.redAccent : AppConfig.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (isDriving ? Colors.redAccent : AppConfig.primaryColor).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDriving ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 80),
            Text(isDriving ? "STOP TRIP" : "START TRIP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Signal", "Strong"),
          Container(height: 30, width: 1, color: Colors.white24),
          _buildStatItem("Updates", updateCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))]);
  }
}