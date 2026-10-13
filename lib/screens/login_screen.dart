
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loadingIcon = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async{
    if(_formKey.currentState!.validate()){
      setState(() {
        _loadingIcon = true;
      });
      var email = _emailController.text.trim();
      var password = _passwordController.text.trim();

      var errorMessage = await AuthService().loginWithEmail(email, password);

      if (!mounted) return;

      // Quitamos el estado de carga
      setState(() {
        _loadingIcon = false;
      });

      if(errorMessage != null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red, // Ponemos el fondo rojo para indicar error
          ),
        );
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sesión iniciada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // Envolvemos la columna en un Form y le pasamos nuestra key
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 40),
            TextFormField(
              validator: Validators.validateEmail,
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              validator: Validators.validatePassword,
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            _loadingIcon ?
              const Center(child: CircularProgressIndicator()) 
                :
                ElevatedButton(
                  // Pasamos la referencia de la función directamente
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ingresar', style: TextStyle(fontSize: 16)),
                ),
            const SizedBox(height: 12.0),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}