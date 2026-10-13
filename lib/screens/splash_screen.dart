import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Lo usaremos en el futuro

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
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (user != null) {
      // Caso 2: Ya usó la app y ya está logueado -> Pantalla Principal (Vault)
      // Nota: Cambia '/home' por la ruta real de tu BottomNavigationBar cuando la crees
      Navigator.of(context).pushReplacementNamed('/home'); 
    } else {
      // Caso 3: Ya usó la app, pero no ha iniciado sesión (o cerró sesión) -> Login
      Navigator.of(context).pushReplacementNamed('/login');
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
              'https://picsum.photos/200', // Imagen placeholder (temporal)
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Si el móvil no tiene internet, muestra este icono
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
