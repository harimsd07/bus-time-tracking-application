import 'dart:convert'; // Logic Added: Required for encoding/decoding history list [cite: 2026-02-11]
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_time_track/main.dart';
import 'package:bus_time_track/presentation/screens/auth/login_screen.dart';
import 'package:bus_time_track/presentation/screens/add_new_bus.dart';
import 'package:bus_time_track/presentation/screens/student/get_bus_time.dart';

class HomePage extends StatefulWidget {
  final String userRole;
  final String userName;
  const HomePage({super.key, required this.userRole, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Logic Added: List to store and display dynamic search history [cite: 2026-02-11]
  List<Map<String, String>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory(); // Logic Added: Load saved history on startup [cite: 2026-02-11]
  }

  // Logic Added: Retrieves saved history from SharedPreferences [cite: 2026-02-11]
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString('search_history');
    if (historyData != null) {
      setState(() {
        searchHistory = List<Map<String, String>>.from(
          json
              .decode(historyData)
              .map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  // Logic Added: Saves a new search and maintains a limit of 5 unique entries [cite: 2026-02-11]
  Future<void> _saveSearch(String from, String to) async {
    if (from.isEmpty || to.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final newSearch = {
      'from': from,
      'to': to,
      'time':
          "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    };

    setState(() {
      // Remove duplicate if it exists to bring the newest to the top
      searchHistory.removeWhere(
        (item) => item['from'] == from && item['to'] == to,
      );
      searchHistory.insert(0, newSearch);
      if (searchHistory.length > 5) searchHistory.removeLast();
    });

    await prefs.setString('search_history', json.encode(searchHistory));
  }

  // Logic Added: Allows user to clear their history manually [cite: 2026-02-11]
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() => searchHistory.clear());
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _swapLocations() {
    setState(() {
      String temp = fromController.text;
      fromController.text = toController.text;
      toController.text = temp;
    });
  }

  String _getDashboardTitle() {
    switch (widget.userRole) {
      case 'admin':
        return "Admin Control";
      case 'driver':
        return "Driver Dashboard";
      default:
        return "Student View";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bus Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.primaryColor.withOpacity(0.15), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "${_getGreeting()},",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.userRole == 'admin' ? "irah" : widget.userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDashboardTitle().toUpperCase(),
                    style: const TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                if (widget.userRole == 'student') ...[
                  const SizedBox(height: 25),
                  _buildSearchBlock(),

                  if (searchHistory.isNotEmpty) ...[
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "RECENT SEARCHES",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black38,
                            letterSpacing: 1.1,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearHistory,
                          child: const Text(
                            "CLEAR",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ...searchHistory
                        .map(
                          (item) => _buildHistoryItem(
                            item['from']!,
                            item['to']!,
                            item['time']!,
                          ),
                        )
                        .toList(),
                  ],
                ],

                const SizedBox(height: 35),
                const Text(
                  "QUICK ACTIONS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 15),
                _buildMenuCard(
                  title: "Bus Schedules",
                  subtitle: "Browse all available routes",
                  icon: Icons.calendar_month_rounded,
                  color: AppConfig.accentColor,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GetBusTime(),
                        ),
                      ),
                ),

                if (widget.userRole == 'admin') ...[
                  const SizedBox(height: 20),
                  _buildMenuCard(
                    title: "Register New Bus",
                    subtitle: "Add vehicle data to system",
                    icon: Icons.add_circle_outline_rounded,
                    color: AppConfig.primaryColor,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddNewBus(),
                          ),
                        ),
                  ),
                ],

                if (widget.userRole == 'driver') ...[
                  const SizedBox(height: 20),
                  _buildMenuCard(
                    title: "Active Broadcast",
                    subtitle: "Share live location with students",
                    icon: Icons.radar_rounded,
                    color: Colors.orange.shade700,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const GetBusTime(isDriverMode: true),
                          ),
                        ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  _buildSearchField(
                    fromController,
                    "From Station",
                    Icons.circle_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildSearchField(
                    toController,
                    "To Station",
                    Icons.location_on_outlined,
                  ),
                ],
              ),
              Positioned(
                right: 5,
                child: GestureDetector(
                  onTap: _swapLocations,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppConfig.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _saveSearch(
                  fromController.text.trim(),
                  toController.text.trim(),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GetBusTime(
                          searchFrom: fromController.text.trim(),
                          searchTo: toController.text.trim(),
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "FIND BUSES",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppConfig.primaryColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildHistoryItem(String from, String to, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            fromController.text = from;
            toController.text = to;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.history,
            color: AppConfig.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          "$from → $to",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "Searched at $time",
          style: const TextStyle(color: Colors.black45, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: color.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
