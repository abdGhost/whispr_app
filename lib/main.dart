import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whispr_app/api/api_services.dart';
import 'package:whispr_app/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WhisprApp());
}

class WhisprApp extends StatefulWidget {
  const WhisprApp({super.key});

  @override
  State<WhisprApp> createState() => _WhisprAppState();
}

class _WhisprAppState extends State<WhisprApp> {
  final ApiServices _apiServices = ApiServices();

  @override
  void initState() {
    super.initState();
    _registerAPI();
  }

  /// Registers the user if not already registered
  Future<void> _registerAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isRegistered = prefs.getBool('isRegistered') ?? false;

    if (isRegistered) {
      print('User already registered previously');
      return;
    }

    var userData = await _apiServices.registerOnAppStart();

    if (userData != null) {
      await prefs.setString('userId', userData['userId']);
      await prefs.setString('username', userData['username']);
      await prefs.setBool('isRegistered', true);
      print('User Registered and data saved to cache: $userData');
    } else {
      print('Registration failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whispr',
      theme: ThemeData(
        primaryColor: const Color(0xFF6C5CE7),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
