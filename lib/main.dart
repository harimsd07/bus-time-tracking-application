import 'package:bus_time_track/presentation/screens/auth/landing_screen.dart';
import 'package:bus_time_track/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart'; // Logic Added: Required for catching deep links

class AppConfig {
  static const String baseUrl =
      "https://web-production-0391f.up.railway.app/api";
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color accentColor = Color(0xFF03DAC6);
}

// Logic: Create a Global Navigator Key to handle navigation from inside a stream
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final String? savedRole = prefs.getString('role');
  final String? savedName = prefs.getString('userName');

  runApp(BusTrackApp(initialRole: savedRole, initialName: savedName));
}

class BusTrackApp extends StatefulWidget {
  final String? initialRole;
  final String? initialName;
  const BusTrackApp({super.key, this.initialRole, this.initialName});

  @override
  State<BusTrackApp> createState() => _BusTrackAppState();
}

class _BusTrackAppState extends State<BusTrackApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks(); // Logic Added: Initialize listener for OAuth redirects
  }

  /*
  |--------------------------------------------------------------------------
  | Deep Link Logic [Added to handle the bustrack://login-callback URL]
  |--------------------------------------------------------------------------
  | This logic listens for the URI sent from your Laravel AuthController. 
  | It extracts the token, name, and role, saves them to storage, and 
  | navigates the user to the HomePage automatically.
  */
  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) async {
      // Logic: Matches the scheme and host we defined in AndroidManifest.xml
      if (uri.scheme == 'bustrack' && uri.host == 'login-callback') {
        final prefs = await SharedPreferences.getInstance();

        final String? token = uri.queryParameters['token'];
        final String? name = uri.queryParameters['name'];
        final String? role = uri.queryParameters['role'];

        if (token != null) {
          // Logic: Persistent session storage
          await prefs.setString('auth_token', token);
          await prefs.setString('userName', name ?? "User");
          await prefs.setString('role', role ?? "student");

          // Logic: Automatic navigation after social login
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => HomePage(
                    userRole: role ?? 'student',
                    userName: name ?? 'User',
                  ),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:
          navigatorKey, // Logic: Link the GlobalKey for deep link navigation
      title: 'Bus Time Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
        fontFamily: 'Roboto',
      ),
      home:
          widget.initialRole == null
              ? const LandingPage()
              : HomePage(
                userRole: widget.initialRole!,
                userName: widget.initialName ?? "User",
              ),
    );
  }
}
