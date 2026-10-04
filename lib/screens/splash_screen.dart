import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Lo usaremos en el futuro

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
    // 1. Esperamos 2 segundos para que el usuario vea el logo
    await Future.delayed(const Duration(seconds: 2));

    // 2. Verificamos que el widget siga en pantalla antes de cambiar de ruta
    if (!mounted) return;

    // 3. Leemos de las preferencias (nuestro servicio) si el usuario es nuevo
    final isFirstTime = PreferencesService.isFirstTime;
    
    // final user = FirebaseAuth.instance.currentUser; // Lo usaremos en el futuro

    // 4. Lógica de enrutamiento
    if (isFirstTime) {
      // Si es la primera vez, vamos al Onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      // Como aún no tenemos Firebase Auth conectado, por ahora 
      // enviaremos a Login si no es la primera vez.
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
            // Requerimiento Bloque 2: Manejo de imagen de red con fallback local
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
