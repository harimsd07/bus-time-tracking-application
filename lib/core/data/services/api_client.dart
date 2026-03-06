import 'dart:convert';
import 'package:bus_time_track/core/config/app_config.dart';
import 'package:bus_time_track/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /*
  |--------------------------------------------------------------------------
  | Global Header Logic [cite: 2026-02-24]
  |--------------------------------------------------------------------------
  | This automatically injects the auth_token from SharedPreferences
  | into every request, solving the "Unauthorized" connection failures.
  */
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(
      Uri.parse("${AppConfig.baseUrl}$endpoint"),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse("${AppConfig.baseUrl}$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
  }
}