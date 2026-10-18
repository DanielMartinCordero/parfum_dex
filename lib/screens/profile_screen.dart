import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:parfum_dex/routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/users_service.dart';
import '../models/user_profile.dart';
import '../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersService _usersService = UsersService();
  late Future<UserProfile?> _profileFuture;
  
  // Controlador para poder editar el nombre
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _usersService.getCurrentUserProfile().then((profile) {
      if (profile != null) {
        _nameController.text = profile.displayName;
      }
      return profile;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para guardar el nuevo nombre
  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Si no ha cambiado el texto, cerramos la edición sin hacer llamada a red
    if (_nameController.text.trim() == AuthService().currentUser?.displayName) {
      setState(() { _isEditing = false; });
      return;
    }

    setState(() { _isSaving = true; });

    try {
      // Validamos que no exista ya el nombre (misma validación que el registro)
      final bool isAvailable = await _usersService.isUsernameAvailable(_nameController.text.trim());
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este nombre de usuario ya está en uso.'), backgroundColor: Colors.red),
        );
        return;
      }

      await _usersService.updateDisplayName(_nameController.text.trim());
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado correctamente'), backgroundColor: Colors.green),
      );
      
      // Salimos del modo edición y recargamos
      setState(() {
        _isEditing = false;
        _loadProfile();
      });
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ParfumDex"),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          final profile = snapshot.data!;
          // Formateamos la fecha de forma bonita: "DD/MM/YYYY"
          final dateString = "${profile.createdAt.day.toString().padLeft(2,'0')}/${profile.createdAt.month.toString().padLeft(2,'0')}/${profile.createdAt.year}";

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Symbols.person_outline, size: 100, color: Colors.deepPurple),
                  const SizedBox(height: 32),
                  
                  // Formulario de edición
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          // Si no está editando, el campo es de solo lectura (gris)
                          readOnly: !_isEditing,
                          decoration: InputDecoration(
                            labelText: "Nombre de Usuario",
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            // Botón de lápiz / guardar
                            suffixIcon: _isSaving
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                                    color: _isEditing ? Colors.green : Colors.grey,
                                    onPressed: () {
                                      if (_isEditing) {
                                        _saveName();
                                      } else {
                                        setState(() { _isEditing = true; });
                                      }
                                    },
                                  ),
                          ),
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: profile.email,
                          readOnly: true, // El email nunca se edita aquí
                          decoration: const InputDecoration(
                            labelText: "Correo Electrónico",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: dateString,
                          readOnly: true, // La fecha nunca se edita
                          decoration: const InputDecoration(
                            labelText: "Miembro desde",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesión cerrada')),
                      );
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
