import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'dart:math' as math;

// Logic: Keep the bearing calculation outside the class for performance
double calculateBearing(LatLng start, LatLng end) {
  double lat1 = start.latitude * math.pi / 180;
  double lon1 = start.longitude * math.pi / 180;
  double lat2 = end.latitude * math.pi / 180;
  double lon2 = end.longitude * math.pi / 180;

  double dLon = lon2 - lon1;

  double y = math.sin(dLon) * math.cos(lat2);
  double x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  double radians = math.atan2(y, x);
  return (radians * 180 / math.pi + 360) % 360;
}

class LiveMapScreen extends StatefulWidget {
  final Map busData;
  const LiveMapScreen({super.key, required this.busData});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  late LatLng _currentLocation;
  late LatLng _oldLocation;
  double _currentBearing = 0.0;
  late ReverbClient client;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Logic: Parsing coordinates safely in case they come as strings from Laravel
    _currentLocation = LatLng(
      double.parse(widget.busData['latitude'].toString()),
      double.parse(widget.busData['longitude'].toString()),
    );
    _oldLocation = _currentLocation;
    initWebsocket();
  }

  void initWebsocket() async {
    print("SOCKET: Attempting to connect...");

    client = ReverbClient.instance(
      host: '192.168.1.38',
      port: 8080,
      appKey: 'gj0s0ltmuziy13ua87yf',
      // Logic Fixed: Changed useSsl to encrypted
      useTLS: false,
    );

    try {
      await client.connect();
      print("SOCKET: Connected Successfully!");

      final channel = client.subscribeToChannel('bus-tracking');

    // Logic Updated: Using jsonDecode to handle String-to-Map conversion
channel.on('BusLocationUpdated').listen((event) {
  print("RAW DATA TYPE: ${event.data.runtimeType}"); // This will likely show 'String'
  
  try {
    // Logic: Convert the string event data into a Map
    final Map<String, dynamic> decodedData = jsonDecode(event.data.toString());
    final busData = decodedData['bus'];

    if (busData['id'].toString() == widget.busData['id'].toString()) {
      setState(() {
        _oldLocation = _currentLocation;
        
        // Logic: Extract coordinates and parse to double
        _currentLocation = LatLng(
          double.parse(busData['latitude'].toString()),
          double.parse(busData['longitude'].toString()),
        );
        
        // Logic: Calculate rotation for the bus icon
        _currentBearing = calculateBearing(_oldLocation, _currentLocation);
      });

      _mapController.move(_currentLocation, 15.0);
      print("SUCCESS: Bus moved to $_currentLocation");
    }
  } catch (e) {
    print("PARSING ERROR: $e");
  }
});
    } catch (e) {
      print("SOCKET ERROR: $e");
    }
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.busData['busNameOrbusNo']),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _currentLocation, initialZoom: 15.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.bus_time_track',
          ),
          MarkerLayer(
            markers: [
              // Logic: The Animated Marker
              Marker(
                point: _currentLocation,
                width: 100,
                height: 100,
                // Logic updated: Use the Tween to animate the LatLng change
                child: TweenAnimationBuilder<LatLng>(
                  tween: LatLngTween(
                    begin: _oldLocation,
                    end: _currentLocation,
                  ),
                  duration: const Duration(
                    milliseconds: 1500,
                  ), // Slightly slower for smoothness
                  builder: (context, LatLng animatedPos, child) {
                    return Column(
                      children: [
                        // Logic: Label for the bus
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.busData['busNameOrbusNo'],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Logic Updated: Apply rotation to the icon
                        Transform.rotate(
                          angle: _currentBearing * (math.pi / 180),
                          child: Icon(
                            Icons.directions_bus_filled_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 45,
                          ),
                        ),
                      ],
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
}

// Logic: Custom Tween to handle LatLng interpolation
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
