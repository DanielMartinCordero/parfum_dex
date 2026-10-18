import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../services/preferences_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRouting();
  }

  Future<void> _checkInitialRouting() async {
    // 1. Esperamos 1 segundos para que el usuario vea el logo (fake delay)
    await Future.delayed(const Duration(seconds: 1));

    // 2. Verificamos que el widget siga en pantalla antes de cambiar de ruta
    if (!mounted) return;

    // 3. Leemos de las preferencias si la app se abre por primera vez
    final isFirstTime = PreferencesService.isFirstTime;

    // 4. Verificamos si hay una sesión activa de Firebase
    final user = FirebaseAuth.instance.currentUser;

    // 5. Lógica de enrutamiento
    if (isFirstTime) {
      // Caso 1: Nunca ha usado la app -> Onboarding
      context.go(AppRoutes.onboarding);
    } else if (user != null) {
      // Caso 2: Ya usó la app y ya está logueado -> Pantalla Principal (Vault)
      context.go(AppRoutes.explore);
    } else {
      // Caso 3: Ya usó la app, pero no ha iniciado sesión (o cerró sesión) -> Login
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Manejo de imagen de red con fallback local
          Image.network(
          'https://picsum.photos/200',
          width: 150,
          height: 150,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 150,
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.local_florist,
              size: 150,
              color: Colors.grey,
            );
          },
            ),
            const SizedBox(height: 24),
            const Text(
              'ParfumDex',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Indicador de carga explícito
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
