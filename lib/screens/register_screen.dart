
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

  // 1. Instanciamos el servicio de autenticación
  final AuthService _authService = AuthService();
  
  // 2. Variable para controlar el estado de carga (el circulito dando vueltas)
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _displayName.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. Creamos nuestra función asíncrona para manejar el botón de registro
  Future<void> _handleRegister() async {
    // A) Primero, validamos con nuestros Validadores (Capa Cliente)
    if (_formKey.currentState!.validate()) {
      
      // B) Ponemos el estado de carga en true para mostrar el spinner
      setState(() {
        _isLoading = true;
      });

      // C) Extraemos los textos de los controladores
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _displayName.text.trim();

      // D) Llamamos al servicio (Capa Servidor/Infraestructura)
      // Como devuelve un Future, usamos 'await' para esperar la respuesta.
      final errorMessage = await _authService.registerWithEmail(email, password, name);

      // E) Como la función era asíncrona (await), comprobamos que la pantalla siga existiendo
      if (!mounted) return;

      // F) Quitamos el estado de carga
      setState(() {
        _isLoading = false;
      });

      // G) Verificamos qué nos devolvió el servicio
      if (errorMessage != null) {
        // Hubo un error de Firebase (ej: el email ya existe), se lo enseñamos al usuario.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red, // Ponemos el fondo rojo para indicar error
          ),
        );
      } else {
        // No hubo error, devolvió null. ¡Registro exitoso!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Registro exitoso!"),
            backgroundColor: Colors.green,
          ),
        );
        // Redirigimos a la pantalla inicial
        Navigator.of(context).pushReplacementNamed('/'); //Pendiente de implementar Home
      }
    }
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
                        labelText: "Correo electrónico",  prefixIcon: Icon(Icons.email), border: OutlineInputBorder(), errorMaxLines: 3),
                        validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(controller: _displayName, decoration: const InputDecoration(
                        labelText: "Nombre de usuario (el nombre que se verá en la aplicación)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
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

                    // 4. Mostramos el botón de registro O el indicador de carga
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            // 5. Conectamos el botón con nuestra función
                            onPressed: _handleRegister,
                            child: const Text("Registrarse")
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