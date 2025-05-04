import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GetBusTime extends StatefulWidget {
  const GetBusTime({super.key});

  @override
  State<GetBusTime> createState() => _GetBusTimeState();
}

class _GetBusTimeState extends State<GetBusTime> {
  TextEditingController searchController = TextEditingController();
  List busTime = [];
  List originalBusTime = [];
  @override
  void initState() {
    super.initState();
    fetchBusTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Get Bus Time'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Column(
            children: [
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(25),
                child: TextField(
                  onChanged: filterBusTime,
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search_outlined),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  shrinkWrap:
                      true, // Important for using ListView inside a Column/Card
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling of the ListView if the parent is scrollable
                  itemCount: busTime.length,
                  itemBuilder: (context, index) {
                    final finalData = busTime[index] as Map;
                    final state = finalData['state'];
                    final district = finalData['district'];
                    final privateOrGovt = finalData['privateOrGovt'];
                    final busNameAndBusNo = finalData['busName_and_busNo'];
                    final pickupStop = finalData['pick_up_stop'];
                    final destination = finalData['destination'];
                    final pickupTime = finalData['pickup_time'];
                    final reachDestinationTime =
                        finalData['reach_destination_time'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              busNameAndBusNo ?? 'Bus Name Not Available',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'From: ${pickupStop ?? 'N/A'} (${pickupTime ?? 'N/A'})',
                                ),
                                Text(
                                  'To: ${destination ?? 'N/A'} (${reachDestinationTime ?? 'N/A'})',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type: ${privateOrGovt?.toUpperCase() ?? 'N/A'}',
                            ),
                            Text(
                              'District: ${district ?? 'N/A'}, State: ${state ?? 'N/A'}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void filterBusTime(String query) {
    setState(() {
      if (query.isEmpty) {
        busTime = originalBusTime;
      } else {
        busTime =
            originalBusTime.where((busRoute) {
              final busName =
                  busRoute['busName_and_busNo']?.toString().toLowerCase() ?? '';
              return busName.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> fetchBusTime() async {
    final url = 'https://bustimetracker.irahalan.in/api/viewBusDetail';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    // print(response.statusCode);
    // print(response.body);

    if (response.statusCode == 200) {
      final jsonFormData = jsonDecode(response.body) as Map;
      final busTimeData = jsonFormData['data'] as List;

      setState(() {
        busTime = busTimeData;
        originalBusTime = List.from(busTime);
      });
    }
  }
}
