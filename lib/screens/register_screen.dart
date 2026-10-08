
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
                        validator: (value){
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }

                          // 2. Patrón de validación de formato RFC simplificado
                          final emailRegExp = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );

                          // 3. Comprobar si cumple la estructura
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Introduce un correo electrónico válido (ej. usuario@dominio.com)';
                          }

                          return null; // Formato correcto
                        },),

                    const SizedBox(height: 16),

                    TextFormField(controller: _displayName, decoration: const InputDecoration(
                        labelText: "Nombre público (el nombre que se verá en la aplicación)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                        validator: (value){ //En un futuro comprobaremos que no exista en la base de datos ese nombre
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        }
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _passwordController, decoration: const InputDecoration(
                        labelText: "Contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true,
                        validator: (value) {
                          if(value == null || value.isEmpty){
                            return 'La contraseña es obligatoria';
                          }
                          else if(value.length < 6){
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          else if(value.contains(' ')){
                            return 'La contraseña no puede contener espacios';
                          }
                          return null;
                        }
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(
                        labelText: "Confirmar contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        // Comprobamos directamente contra el texto del primer controlador
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
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
                      child: Text("<---Volver a login")
                    ),
                  ],
                  ),
              ),
          ),
            ),
      );
  }
}