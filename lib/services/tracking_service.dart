import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrackingService {
  // Logic updated: Changed from Timer? to StreamSubscription?
  // This allows us to "listen" to the GPS instead of "asking" it on a timer.
  StreamSubscription<Position>? _positionStream;

  Future<void> startLiveTracking(int busId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Logic added: Setting up a 5-meter movement filter to save battery
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, 
    );

    // Logic updated: Replaced Timer.periodic with getPositionStream
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _sendToLaravel(busId, position.latitude, position.longitude);
    });
  }

  Future<void> _sendToLaravel(int id, double lat, double lng) async {
    final url = Uri.parse('http://192.168.1.38:8000/api/bus/update-location');
    try {
      await http.post(url, 
        body: jsonEncode({
          'id': id,
          'latitude': lat,
          'longitude': lng,
        }), 
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print("Update failed: $e");
    }
  }

  // Logic updated: Cancel the stream instead of the timer
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}