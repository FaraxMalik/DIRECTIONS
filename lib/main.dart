import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'src/theme/app_theme.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/services/profile_service.dart';
import 'src/services/results_service.dart';
import 'src/services/journal_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp();
    Logger.info('Firebase initialized successfully');
  } catch (e) {
    Logger.warning('Firebase initialization failed', e);
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
        title: 'Directions — Career Guidance',
        theme: AppTheme.light(),
        home: const SplashScreen(),
        routes: {
          '/auth': (_) => const AuthGate(),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
        },
      ),
    );
  }
}

/// Listens to FirebaseAuth state and routes user to either the
/// authenticated home experience or the login screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.beige,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
