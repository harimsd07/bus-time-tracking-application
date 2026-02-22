import 'package:bus_time_track/services/driver_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DriverPanelScreen extends StatefulWidget {
  final Map busData;
  const DriverPanelScreen({super.key, required this.busData});

  @override
  State<DriverPanelScreen> createState() => _DriverPanelScreenState();
}

class _DriverPanelScreenState extends State<DriverPanelScreen> {
  // Logic: Variables now reflect the state of THIS specific bus
  late bool isDriving;
  late int updateCount;
  late int busId;
  StreamSubscription? _updateSubscription;

  @override
  void initState() {
    super.initState();
    // Logic: Parse the bus ID once to avoid repeated parsing
    busId = int.parse(widget.busData['id'].toString());

    // Logic: Sync with the service using the specific busId
    isDriving = DriverService.isBusDriving(busId);
    updateCount = DriverService.getUpdateCount(busId);

    // Logic: Listen ONLY to the stream for this specific bus
    _updateSubscription = DriverService.getUpdateStream(busId).listen((count) {
      if (mounted) setState(() => updateCount = count);
    });
  }

  void _toggleTrip() async {
    try {
      bool nextState = !isDriving;
      setState(() => isDriving = nextState);
      
      // Logic: Pass the busId to the service so it starts the correct stream
      await DriverService.toggleDriverMode(busId, nextState);
    } catch (e) {
      setState(() => isDriving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("GPS Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    // Logic: We only stop the UI listener; the DriverService keeps broadcasting
    _updateSubscription?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Driver Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 30),
            _buildBusInfoCard(),
            const SizedBox(height: 50),
            _buildActionButton(theme),
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
          Icon(isDriving ? Icons.sensors_rounded : Icons.sensors_off_rounded,
               color: isDriving ? Colors.green : Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(isDriving ? "LIVE BROADCASTING" : "OFFLINE",
              style: TextStyle(color: isDriving ? Colors.green : Colors.orange, 
              fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_bus_rounded, color: Colors.black87, size: 40),
          const SizedBox(height: 12),
          Text(widget.busData['busNameOrbusNo'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Vehicle: ${widget.busData['vehicle_no']}", style: TextStyle(color: Colors.grey.shade600, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return GestureDetector(
      onTap: _toggleTrip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 200, width: 200,
        decoration: BoxDecoration(
          color: isDriving ? Colors.redAccent : theme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (isDriving ? Colors.redAccent : theme.primaryColor).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
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
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }
}