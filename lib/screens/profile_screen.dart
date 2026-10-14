import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.person, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 24),
          const Text(
            'Perfil de Usuario',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await AuthService().signOut();
              // Nota: Como estamos probando rutas aisladas, no he metido el context.go('/login')
              // para no romper tus pruebas actuales si no has importado go_router.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesión cerrada')),
              );
            },
            child: const Text('Cerrar sesión'),
          )
        ],
      ),
    );
  }
}
