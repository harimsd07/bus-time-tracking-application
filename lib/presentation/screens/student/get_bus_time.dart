import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:bus_time_track/main.dart';
// Logic Added: Import driver_broadcast to ensure drivers go to the right screen
import 'package:bus_time_track/presentation/screens/driver/driver_broadcast.dart';
import '../live_map_screen.dart';
import '../auth/login_screen.dart'; 

class GetBusTime extends StatefulWidget {
  final bool isDriverMode;
  final String? searchFrom;
  final String? searchTo;

  const GetBusTime({
    super.key,
    this.isDriverMode = false,
    this.searchFrom,
    this.searchTo,
  });

  @override
  State<GetBusTime> createState() => _GetBusTimeState();
}

class _GetBusTimeState extends State<GetBusTime> {
  TextEditingController searchController = TextEditingController();
  List busTime = [];
  List originalBusTime = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBusTime();
  }

  /*
  |--------------------------------------------------------------------------
  | Navigation Logic
  |--------------------------------------------------------------------------
  | Updated to handle the new DriverBroadcastScreen we created in the 
  | driver/ folder.
  */
  Future<void> _handleBusTap(Map data) async {
    if (widget.isDriverMode) {
      // Logic Added: Navigates to the broadcast screen for the selected bus
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DriverBroadcastScreen(), 
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (token != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveMapScreen(
            busData: data,
            userRole: 'student',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to access real-time tracking"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConfig.primaryColor,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> fetchBusTime() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Logic: Dynamically switches between global search and filtered search
      String url = "${AppConfig.baseUrl}/buses";
      if (widget.searchFrom != null && widget.searchTo != null) {
        url = "${AppConfig.baseUrl}/search?from=${widget.searchFrom}&to=${widget.searchTo}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          // Logic: Adapted to handle your specific Laravel JSON response structure
          if (jsonResponse is Map && jsonResponse.containsKey('data')) {
            busTime = jsonResponse['data'] as List;
          } else {
            busTime = jsonResponse as List;
          }
          originalBusTime = List.from(busTime);
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void filterBusTime(String query) {
    setState(() {
      if (query.isEmpty) {
        busTime = List.from(originalBusTime);
      } else {
        busTime = originalBusTime.where((bus) {
          final name = bus['busNameOrbusNo']?.toString().toLowerCase() ?? '';
          final vehicle = bus['vehicle_no']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              vehicle.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.isDriverMode ? 'Select Your Bus' : 'Bus Schedules',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchBusTime,
                    child: busTime.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: busTime.length,
                            itemBuilder: (context, index) {
                              final data = busTime[index] as Map;
                              return InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _handleBusTap(data),
                                child: _buildModernBusCard(data),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: filterBusTime,
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search by bus name or number...',
            prefixIcon: Icon(Icons.search, color: AppConfig.primaryColor),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBusCard(Map data) {
    final busName = data['busNameOrbusNo'] ?? 'Unknown Bus';
    final vehicleNo = data['vehicle_no'] ?? 'N/A';
    final pickup = data['pick_up_stop'] ?? 'N/A';
    final destination = data['destination'] ?? 'N/A';
    final pTime = data['pickup_time'] ?? '--:--';
    final rTime = data['reach_destination_time'] ?? '--:--';

    // Logic Added: Live detection based on latitude data from Reverb
    final isLive = data['latitude'] != null && 
                  data['latitude'] != 0 && 
                  data['latitude'].toString() != "0.0";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppConfig.primaryColor.withOpacity(0.03),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_filled_rounded, color: AppConfig.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(busName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(vehicleNo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isLive) _buildLiveBadge(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStopInfo(pickup, pTime, CrossAxisAlignment.start),
                  Icon(Icons.arrow_forward, color: Colors.grey.shade300, size: 20),
                  _buildStopInfo(destination, rTime, CrossAxisAlignment.end),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.sensors, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text("LIVE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStopInfo(String stop, String time, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(time, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
        Text(stop, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bus_alert_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No bus schedules found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}