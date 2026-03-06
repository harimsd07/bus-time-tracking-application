import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../shared/widgets/menu_card.dart'; // Logic: Reusing the shared widget [cite: 2026-02-24]
import '../../shared/get_bus_time.dart';

class StudentDashboard extends StatefulWidget {
  final String userName;
  const StudentDashboard({super.key, required this.userName});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  List<Map<String, String>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  // Logic: Ported from original home_screen.dart
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString('search_history');
    if (historyData != null) {
      setState(() {
        searchHistory = List<Map<String, String>>.from(
          json.decode(historyData).map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  // Logic: Ported with unique entry limit
  Future<void> _saveSearch(String from, String to) async {
    if (from.isEmpty || to.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final newSearch = {
      'from': from,
      'to': to,
      'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    };
    setState(() {
      searchHistory.removeWhere((item) => item['from'] == from && item['to'] == to);
      searchHistory.insert(0, newSearch);
      if (searchHistory.length > 5) searchHistory.removeLast();
    });
    await prefs.setString('search_history', json.encode(searchHistory));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text("Welcome, ${widget.userName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSearchBlock(), // Ported UI logic
            const SizedBox(height: 30),
            MenuCard(
              title: "Bus Schedules",
              subtitle: "Browse all available routes",
              icon: Icons.calendar_month_rounded,
              color: AppConfig.accentColor,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GetBusTime())),
            ),
          ],
        ),
      ),
    );
  }


// Logic: Restored from home_screen.dart to define the search UI
  Widget _buildSearchBlock() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchField("From", Icons.location_on_outlined, fromController),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildSearchField("To", Icons.map_outlined, toController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                _saveSearch(fromController.text, toController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GetBusTime(
                      searchFrom: fromController.text,
                      searchTo: toController.text,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Find Buses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String label, IconData icon, TextEditingController controller) {
    return Row(
      children: [
        Icon(icon, color: AppConfig.primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
  // Helper UI methods (SearchBlock, SearchField, HistoryItem) would go here, 
  // exactly as they were in your home_screen.dart
}