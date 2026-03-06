import 'package:flutter/material.dart';

class AppConfig {
  // Logic: Centralized URL to prevent "Connection Failed" errors due to mismatches [cite: 2026-02-24]
  static const String baseUrl =
      "https://web-production-0391f.up.railway.app/api";

  // Logic: Consistent branding across all user roles [cite: 2026-02-24]
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color accentColor = Color(0xFF03DAC6);

  // Logic Added: Reverb configurations moved from live_map_screen.dart
  static const String reverbHost = "web-production-0391f.up.railway.app";
  static const int reverbPort = 443;
  static const String reverbKey = "gj0s0ltmuziy13ua87yf";
}
