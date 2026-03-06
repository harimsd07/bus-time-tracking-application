import 'package:bus_time_track/core/config/app_config.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  ReverbClient? _client;
  bool _isConnected = false;

  // Logic: Getter to check connection status globally [cite: 2026-02-24]
  bool get isConnected => _isConnected;

  /*
  |--------------------------------------------------------------------------
  | Singleton Connection Logic [cite: 2026-02-24]
  |--------------------------------------------------------------------------
  */
void init() {
  if (_client != null) return;

  _client = ReverbClient.instance(
    host: AppConfig.reverbHost,
    port: AppConfig.reverbPort,
    appKey: AppConfig.reverbKey,
    useTLS: true,
  );

  // Logic: Replaces the undefined .onConnect() call
  _client?.onConnectionStateChange.listen((state) {
  // Logic: This will print every available property to your console
  debugPrint("Full State Object: $state"); 
  
  // If 'state' is a string, use this:
  if (state.toString() == 'connected') {
    _isConnected = true;
  }
});

  _client?.connect(); 
}

  // Logic: Centralized channel subscription to match Laravel channels.php
 dynamic subscribeToBus(int busId) {
  if (_client == null) init();
  
  // Logic: Use .client.subscribe as required by pusher_reverb_flutter
  return _client!.subscribeToChannel('bus-tracking.$busId');
}

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _isConnected = false;
  }
}