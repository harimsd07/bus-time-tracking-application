import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:bus_time_track/main.dart';

class TrackingService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static final _updateController = StreamController<int>.broadcast();
  static int _totalUpdates = 0;

  // Logic: Check if a specific bus is currently broadcasting
  static bool isBusTracking(int busId) => _positionStreamSubscription != null;

  // Logic: Get the stream of update counts for the UI
  static Stream<int> getUpdateStream(int busId) => _updateController.stream;

  static Future<void> toggleTracking(int busId, bool start) async {
    if (start) {
      await _startBroadcasting(busId);
    } else {
      await _stopBroadcasting();
    }
  }

  static Future<void> _startBroadcasting(int busId) async {
    // Logic: Ensure permissions are granted on the Nothing Phone 2a
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Logic: Using a 10-meter filter to balance accuracy and battery
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, 
      ),
    ).listen((Position position) async {
      try {
        // Logic: Push to your Laravel update-location endpoint
        final response = await http.post(
          Uri.parse("${AppConfig.baseUrl}/bus/update-location"),
          body: {
            'id': busId.toString(),
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
          },
        );

        if (response.statusCode == 200) {
          _totalUpdates++;
          _updateController.add(_totalUpdates);
        }
      } catch (e) {
        print("Broadcasting Error: $e");
      }
    });
  }

  static Future<void> _stopBroadcasting() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _totalUpdates = 0;
    _updateController.add(0);
  }
}