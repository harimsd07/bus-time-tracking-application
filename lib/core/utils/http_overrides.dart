import 'dart:io';

/*
|--------------------------------------------------------------------------
| SSL Global Override Logic
|--------------------------------------------------------------------------
| This class tells the Flutter internal HTTP client to trust the 
| certificate from your Railway server.
| Added as a separate utility to maintain a clean main.dart.
*/
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
