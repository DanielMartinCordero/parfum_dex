
import 'package:flutter/material.dart';
import '../utils/validators.dart';

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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _displayName.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text("Registro"), centerTitle: true),
        body:
            SingleChildScrollView( //Necesario para que el usuario pueda scrollear
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column (
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 24),
                    TextFormField(controller: _emailController, decoration: const InputDecoration(
                        labelText: "Correo electrónico",  prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                        validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _displayName, decoration: const InputDecoration(
                        labelText: "Nombre público (el nombre que se verá en la aplicación)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                        validator: Validators.validateName,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _passwordController, decoration: const InputDecoration(
                        labelText: "Contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true,
                        validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(
                        labelText: "Confirmar contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true,
                      validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Pendiente: Implementar firebase
                          Navigator.of(context).pushNamed('/splash_screen');
                        }
                      },
                      child: Text("Registrarse")
                    ),

                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/login');
                    },
                      child: Text("Ya tengo una cuenta")
                    ),
                  ],
                  ),
              ),
          ),
            ),
      );
  }
}