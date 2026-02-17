import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bus_time_track/main.dart'; 
import 'live_map_screen.dart';

class GetBusTime extends StatefulWidget {
  const GetBusTime({super.key});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Bus Schedules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
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
                decoration: InputDecoration(
                  hintText: 'Search by bus name or number...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveMapScreen(busData: data),
                                    ),
                                  );
                                },
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

  Widget _buildModernBusCard(Map data) {
    final theme = Theme.of(context);

    final busName = data['busNameOrbusNo'] ?? 'Unknown Bus';
    final vehicleNo = data['vehicle_no'] ?? 'N/A';
    final pickup = data['pick_up_stop'] ?? 'N/A';
    final destination = data['destination'] ?? 'N/A';
    final pTime = data['pickup_time'] ?? '--:--';
    final rTime = data['reach_destination_time'] ?? '--:--';
    
    final isLive = data['latitude'] != null && 
                   data['latitude'] != 0.0 && 
                   data['latitude'] != "0.0";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
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
              color: theme.colorScheme.primary.withOpacity(0.03),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_filled_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          vehicleNo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sensors, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            "LIVE",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStopInfo(pickup, pTime, CrossAxisAlignment.start),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey.shade300,
                    size: 20,
                  ),
                  _buildStopInfo(destination, rTime, CrossAxisAlignment.end),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopInfo(String stop, String time, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
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
          const Text(
            "No bus schedules found",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void filterBusTime(String query) {
    setState(() {
      if (query.isEmpty) {
        busTime = List.from(originalBusTime);
      } else {
        busTime = originalBusTime.where((bus) {
          final name = bus['busNameOrbusNo']?.toString().toLowerCase() ?? '';
          final vehicle = bus['vehicle_no']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || vehicle.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // --- Logic Section ---

  Future<void> fetchBusTime() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    // Logic: Normalize the URL to ensure no double slashes or hidden characters
    // This is vital when using physical devices and localhost-alternatives
    final String rawUrl = "${AppConfig.baseUrl}/buses";
    final Uri cleanUri = Uri.parse(rawUrl.replaceAll(RegExp(r'(?<!:)/+'), '/'));
    
    print("DEBUG: Requesting -> ${cleanUri.toString()}");

    try {
      final response = await http.get(
        cleanUri,
        headers: {
          // Logic: Force Laravel to return JSON. Without these, Laravel may 
          // return a 404 HTML page if it doesn't recognize the mobile client.
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'Keep-Alive',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        setState(() {
          // Logic: Mapping both direct lists and Laravel-wrapped 'data' objects
          if (jsonResponse is Map && jsonResponse.containsKey('data')) {
            busTime = jsonResponse['data'] as List;
          } else if (jsonResponse is List) {
            busTime = jsonResponse;
          }
          originalBusTime = List.from(busTime);
          isLoading = false;
        });
      } else {
        // Logic: Print the HTML body in debug mode to see Apache/Laravel errors
        print("SERVER ERROR BODY: ${response.body}");
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}