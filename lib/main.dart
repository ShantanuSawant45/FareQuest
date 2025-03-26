import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:se_project/providers/auth_provider.dart';
import 'package:se_project/providers/location_provider.dart';
import 'package:se_project/providers/ride_provider.dart';
import 'package:se_project/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';



// AIzaSyAdpipaTyU946lJeZjrF-oTIyAtlvDkjoY

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: MaterialApp(
        title: 'Neo Rides',
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: Colors.purple.shade400,
            secondary: Colors.cyan.shade400,
            background: const Color(0xFF1A1A2E),
          ),
          textTheme: GoogleFonts.chakraPetchTextTheme(
            ThemeData.dark().textTheme,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
