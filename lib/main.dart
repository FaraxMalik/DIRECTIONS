import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/services/profile_service.dart';
import 'src/services/results_service.dart';
import 'src/services/journal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("⚠️ Firebase initialization failed: $e");
    // Continue without Firebase for offline functionality
  }
  
  runApp(const CareerApp());
}

class CareerApp extends StatelessWidget {
  const CareerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => ResultsService()),
        ChangeNotifierProvider(create: (_) => JournalService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DIRECTIONS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB20000),
            primary: const Color(0xFFB20000), // Deep red
            secondary: const Color(0xFFFFFEF0), // Warm beige
            surface: const Color(0xFFFFFEF0), // Light beige
            brightness: Brightness.light,
          ),
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: const Color(0xFFFFFEF0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB20000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFB20000),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 24, 
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: const Color(0xFFB20000).withOpacity(0.1), width: 1),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFFB20000).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFFB20000).withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFB20000), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFFFEF0).withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}