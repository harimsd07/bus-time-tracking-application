import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:bus_time_track/main.dart';
import 'package:flutter/foundation.dart';

class DriverService {
  // Logic: Notice the '?' to allow the subscription to be null when a trip is stopped
  static final Map<int, StreamSubscription<Position>?> _streams = {};
  static final Map<int, int> _updateCounts = {};
  static final Set<int> _activeBuses = {};

  // Logic: Map for controllers ensures each bus has its own isolated data stream
  static final Map<int, StreamController<int>> _controllers = {};

  static Stream<int> getUpdateStream(int busId) {
    if (!_controllers.containsKey(busId)) {
      _controllers[busId] = StreamController<int>.broadcast();
    }
    return _controllers[busId]!.stream;
  }

  static bool isBusDriving(int busId) => _activeBuses.contains(busId);
  static int getUpdateCount(int busId) => _updateCounts[busId] ?? 0;

  static Future<void> toggleDriverMode(int busId, bool start) async {
    if (start) {
      _activeBuses.add(busId);
      _updateCounts[busId] = 0;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      // Logic: Start a unique GPS stream for this specific bus ID
      _streams[busId] = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        _updateCounts[busId] = (_updateCounts[busId] ?? 0) + 1;

        // Logic: Notify only the listeners specifically for this busId
        if (_controllers.containsKey(busId)) {
          _controllers[busId]!.add(_updateCounts[busId]!);
        }

        _sendUpdate(busId, position);
      });
    } else {
      // Logic: Clean up only the specific bus that was stopped
      _activeBuses.remove(busId);

      // Logic: Safely cancel and set to null (Now works with the updated Map type)
      _streams[busId]?.cancel();
      _streams[busId] = null;

      _updateCounts[busId] = 0;
      if (_controllers.containsKey(busId)) {
        _controllers[busId]!.add(0);
      }
    }
  }

  static Future<void> _sendUpdate(int busId, Position pos) async {
    try {
      final response = await http
          .post(
            Uri.parse("${AppConfig.baseUrl}/bus/update-location"),
            body: {
              'id': busId.toString(),
              'latitude': pos.latitude.toString(),
              'longitude': pos.longitude.toString(),
            },
          )
          .timeout(const Duration(seconds: 5));

      debugPrint("DRIVER: Bus $busId updated | Status: ${response.statusCode}");
    } catch (e) {
      debugPrint("DRIVER ERROR for Bus $busId: $e");
    }
  }
}
