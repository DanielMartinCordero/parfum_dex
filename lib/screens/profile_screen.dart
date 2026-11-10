import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:perfume_dex/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/map_services/nearby_stores_service.dart';
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
  bool _isDeleting = false;

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
        const SnackBar(
          content: Text('No se pudo guardar el nombre. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      //Pase lo que pase, cambiamos el estado de _isSaving a false
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // Borra la zona de la última búsqueda de perfumerías: la del perfil en
  // Firestore y la que guarda en memoria la caché de la sesión.
  Future<void> _deleteSavedZone() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      await _usersService.deleteLastSearchLocation();
      NearbyStoresService.instance.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación guardada eliminada')),
      );
      // Recargamos el perfil: ya sin zona, el botón desaparece.
      setState(() {
        _loadProfile();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la ubicación. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // finally se ejecuta SIEMPRE, haya ido bien o mal: así el spinner no se
      // queda girando si falla el borrado.
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  // "Cerca de Madrid · 08/11/2026" o, si no se conoce la ciudad,
  // "Guardada el 08/11/2026".
  String _savedZoneText(String? area, DateTime? at) {
    String? date;
    if (at != null) {
      date = '${at.day.toString().padLeft(2, '0')}/'
          '${at.month.toString().padLeft(2, '0')}/${at.year}';
    }

    if (area != null && date != null) return 'Cerca de $area · $date';
    if (area != null) return 'Cerca de $area';
    if (date != null) return 'Guardada el $date';
    return 'Zona de tu última búsqueda';
  }

  // Abre Google Maps (app o web) centrado en la zona guardada, para que el
  // usuario vea en un mapa de verdad qué zona es.
  void _openSavedZone(GeoPoint zone) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${zone.latitude},${zone.longitude}',
    });
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PerfumeDex"),
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
          // Copia local para que Dart la promocione a no-null tras el if.
          final savedZone = profile.lastSearchLocation;
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

                  // Solo si hay una zona guardada de la última búsqueda.
                  if (savedZone != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      // onPressed: null desactiva el botón (se ve gris y no
                      // responde): así no se puede pulsar varias veces.
                      onPressed: _isDeleting ? null : _deleteSavedZone,
                      // Solo cambia el icono: el botón no salta de tamaño.
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_off_outlined),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eliminar ubicación guardada'),
                          Text(
                            _savedZoneText(profile.lastSearchArea, profile.lastSearchAt),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    // Subbotón: enseña la zona en Google Maps.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openSavedZone(savedZone),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Ver última ubicación'),
                      ),
                    ),
                  ],

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
