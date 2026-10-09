import 'package:flutter/material.dart';
import 'package:parfum_dex/services/database_seeder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Aquí añadiremos más tarde los TextControllers para email y contraseña
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 40),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Pendiente: conectar con Firebase Auth en el próximo paso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Firebase Auth pendiente de implementar')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Ingresar', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                // Pendiente: Navegar a pantalla de Registro
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
            ElevatedButton(
              onPressed: () {
                // Pendiente: conectar con Firebase Auth en el próximo paso
                DatabaseSeeder.insertLayton();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Prueba insert', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}