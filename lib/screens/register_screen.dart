
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
const RegisterScreen ({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _bornDate = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text("Registro"), centerTitle: true),
        body:
            Column (
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(controller: _emailController, decoration: const InputDecoration(
                    labelText: "Correo electrónico",  prefixIcon: Icon(Icons.email)),
                    ),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(
                    labelText: "Contraseña", prefixIcon: Icon(Icons.lock)), obscureText: true,
                ),
                TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(
                    labelText: "Confirmar contraseña", prefixIcon: Icon(Icons.lock)), obscureText: true,
                ),
                TextButton(
                  onPressed: () {
                    // Pendiente: Implementar firebase
                    Navigator.of(context).pushNamed('/splash_screen');
                  },
                  child: Text("Registrarse")
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                },
                  child: Text("<---Volver a login")
                ),
              ],
            ),

      );
  }
}