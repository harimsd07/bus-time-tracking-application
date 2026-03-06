import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

// Logic: New imports for centralized core logic [cite: 2026-02-24]
import 'core/config/app_config.dart';
import 'core/utils/http_overrides.dart';
import 'core/utils/role_enums.dart';
import 'presentation/screens/auth/landing_screen.dart';
import 'presentation/home_router.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logic Moved: SSL bypass now isolated in core/utils/ [cite: 2026-02-24]
  HttpOverrides.global = MyHttpOverrides();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Logic: Initialize storage early to prevent dashboard "jank" [cite: 2026-02-24]
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
    _initDeepLinks();
  }

  /*
  |--------------------------------------------------------------------------
  | Deep Link Logic [Updated for Enum-based routing]
  |--------------------------------------------------------------------------
  */
  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'bustrack' && uri.host == 'login-callback') {
        final prefs = await SharedPreferences.getInstance();

        final String? token = uri.queryParameters['token'];
        final String? name = uri.queryParameters['name'];
        final String? roleStr = uri.queryParameters['role'];

        if (token != null) {
          // Logic: Persistent session storage
          await prefs.setString('auth_token', token);
          await prefs.setString('userName', name ?? "User");
          await prefs.setString('role', roleStr ?? "student");

          // Logic: Converting string to Enum prevents "Lazy Role" bugs [cite: 2026-02-24]
          final UserRole role = UserRoleExtension.fromString(roleStr);

          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeRouter(
                userRole: role,
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
      navigatorKey: navigatorKey,
      title: 'Bus Time Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Logic: Using centralized AppConfig for branding [cite: 2026-02-24]
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
        fontFamily: 'Roboto',
      ),
      home: widget.initialRole == null
          ? const LandingPage()
          : HomeRouter(
              userRole: UserRoleExtension.fromString(widget.initialRole),
              userName: widget.initialName ?? "User",
            ),
    );
  }
}