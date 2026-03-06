import 'dart:convert';
import 'package:bus_time_track/core/utils/role_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart'; 
import 'dart:math' as math;

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
  final UserRole userRole; // Logic: Added role to differentiate UI

  const LiveMapScreen({super.key, required this.busData, required this.userRole});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  late LatLng _currentLocation;
  late LatLng _oldLocation;
  double _currentBearing = 0.0;
  late ReverbClient client;
  final MapController _mapController = MapController();

  String _distanceText = "Calculating...";
  LatLng? _studentLocation;
  double _gpsAccuracy = 0.0;
  bool _hasNotified = false;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    _currentLocation = LatLng(
      double.parse(widget.busData['latitude'].toString()),
      double.parse(widget.busData['longitude'].toString()),
    );
    _oldLocation = _currentLocation;

    // Logic: Only track student location if role is student
    if (widget.userRole == 'student') {
      _startLocationTracking();
    }
    initWebsocket();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _studentLocation = LatLng(position.latitude, position.longitude);
            _gpsAccuracy = position.accuracy;
          });
          _calculateDistance(_currentLocation);
        }
      });
    }
  }

  void _calculateDistance(LatLng busPos) {
    if (_studentLocation == null) return;

    double meters = Geolocator.distanceBetween(
      _studentLocation!.latitude,
      _studentLocation!.longitude,
      busPos.latitude,
      busPos.longitude,
    );

    if (meters <= 500 && !_hasNotified) {
      _triggerSafetyAlert();
    } else if (meters > 600) {
      _hasNotified = false;
    }

    if (mounted) {
      setState(() {
        if (meters < 1000) {
          _distanceText = "${meters.toStringAsFixed(0)}m away";
        } else {
          _distanceText = "${(meters / 1000).toStringAsFixed(1)}km away";
        }
      });
    }
  }

  void _triggerSafetyAlert() async {
    _hasNotified = true;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.busData['busNameOrbusNo']} is approaching!"),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void initWebsocket() async {
    client = ReverbClient.instance(
      host: 'web-production-0391f.up.railway.app',
      port: 443,
      appKey: 'gj0s0ltmuziy13ua87yf',
      useTLS: true,
    );

    try {
      await client.connect();
      final channel = client.subscribeToChannel('bus-tracking');

      channel.on('BusLocationUpdated').listen((event) {
        try {
          final Map<String, dynamic> decodedData = jsonDecode(event.data.toString());
          final busData = decodedData['bus'];

          if (busData['id'].toString() == widget.busData['id'].toString()) {
            if (mounted) {
              setState(() {
                _oldLocation = _currentLocation;
                _currentLocation = LatLng(
                  double.parse(busData['latitude'].toString()),
                  double.parse(busData['longitude'].toString()),
                );
                _currentBearing = calculateBearing(_oldLocation, _currentLocation);
              });

              if (widget.userRole == 'student') {
                _calculateDistance(_currentLocation);
              }
              _animatedMapMove(_currentLocation, 15.0);
            }
          }
        } catch (e) {
          debugPrint("PARSING ERROR: $e");
        }
      });
    } catch (e) {
      debugPrint("SOCKET ERROR: $e");
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus_time_track',
              ),
              // Logic: Only show blue dot for students
              if (widget.userRole == 'student' && _studentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _studentLocation!,
                      radius: _gpsAccuracy,
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 100,
                    height: 100,
                    child: TweenAnimationBuilder<LatLng>(
                      tween: LatLngTween(begin: _oldLocation, end: _currentLocation),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, LatLng animatedPos, child) {
                        return Column(
                          children: [
                            _buildMapLabel(widget.busData['busNameOrbusNo']),
                            const SizedBox(height: 4),
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
                  // Logic: Only show student marker if they aren't the driver
                  if (widget.userRole == 'student' && _studentLocation != null)
                    Marker(
                      point: _studentLocation!,
                      width: 22, height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            right: 15,
            bottom: 120,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.directions_bus_filled_rounded,
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _animatedMapMove(_currentLocation, 15.0),
                ),
                // Logic: Floating GPS focus button only for students
                if (widget.userRole == 'student') ...[
                  const SizedBox(height: 10),
                  _buildFloatingButton(
                    icon: Icons.my_location_rounded,
                    color: Colors.blue,
                    onPressed: () {
                      if (_studentLocation != null) {
                        _animatedMapMove(_studentLocation!, 17.0);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Logic: Hide the distance card for drivers to solve "Calculating..." issue
          if (widget.userRole == 'student') _buildDistanceCard(),
        ],
      ),
    );
  }

  Widget _buildMapLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
    );
  }

  Widget _buildDistanceCard() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.my_location, color: Colors.blue),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Your distance to bus", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(_distanceText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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