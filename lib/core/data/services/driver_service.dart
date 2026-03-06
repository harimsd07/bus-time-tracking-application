import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart'; // Logic: Using our new authenticated client [cite: 2026-02-24]

class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal();

  StreamSubscription<Position>? _positionStream;
  final _updateController = StreamController<int>.broadcast();
  int _updateCount = 0;
  bool _isServiceRunning = false;

  Stream<int> get updateStream => _updateController.stream;
  bool get isRunning => _isServiceRunning;

  int get updateCount => _updateCount;

  /*
  |--------------------------------------------------------------------------
  | Trip Management Logic [cite: 2026-02-24]
  |--------------------------------------------------------------------------
  */
  Future<void> startTrip(int busId) async {
    if (_isServiceRunning) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _isServiceRunning = true;
      _updateCount = 0;

      // Logic: distanceFilter saves Railway credits by ignoring idle time [cite: 2026-02-24]
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, 
        ),
      ).listen((Position position) => _broadcastLocation(busId, position));
    }
  }

  Future<void> _broadcastLocation(int busId, Position pos) async {
    try {
      // Logic: Using ApiClient ensures the auth_token is sent [cite: 2026-02-24]
      final response = await ApiClient().post('/bus/update-location', {
        'id': busId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });

      if (response.statusCode == 200) {
        _updateCount++;
        _updateController.add(_updateCount);
      }
    } catch (e) {
      debugPrint("Broadcast error: $e");
    }
  }

  void stopTrip() {
    _positionStream?.cancel();
    _isServiceRunning = false;
    _updateCount = 0;
    _updateController.add(0);
  }
}