import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- IMPORTANTE
import 'firebase_options.dart'; // <--- IMPORTANTE (Asegúrate de que este archivo existe)
import 'package:parfum_dex/screens/register_screen.dart';
import 'package:parfum_dex/screens/splash_screen.dart';
import 'package:parfum_dex/services/preferences_service.dart';
import 'package:parfum_dex/screens/onboarding_screen.dart';
import 'package:parfum_dex/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase con la configuración específica de la plataforma (Web/Android/iOS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PreferencesService.init();
  runApp(const ParfumDexApp());
}

class ParfumDexApp extends StatelessWidget {
  const ParfumDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParfumDex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // La Splash Screen es nuestra ruta inicial
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
