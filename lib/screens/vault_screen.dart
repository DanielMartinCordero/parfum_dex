import 'dart:async'; // <-- Necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/vault_item.dart';
import '../services/photo_services/image_compression/image_compression.dart';
import '../services/photo_services/photo_service.dart';
import '../services/vault_service.dart';
import '../widgets/vault_card/flip_card.dart';
import '../widgets/vault_card/vault_card_edit_overlay.dart';
import '../widgets/vault_card/vault_card_front.dart';
import '../widgets/vault_card/vault_card_back.dart';
import '../widgets/vault_card/vault_edit_sheet.dart';


class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final VaultService _vaultService = VaultService();

  // 1. Guardamos la suscripción al Stream
  StreamSubscription<List<VaultItem>>? _vaultSubscription;

  List<VaultItem> _vaultItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  // Activado desde el botón "Editar armario"
  bool _isEditing = false;
  // Filtro "Últimos 30 días": cambia la consulta que escuchamos
  bool _onlyRecent = false;

  @override
  void initState() {
    super.initState();
    _subscribeToVault();
    // Sin await: initState no puede esperar. Se lanza y sigue por su cuenta
    _reviewForLostPhoto();
  }

  // Si Android cerró la app mientras la cámara estaba abierta, la foto se
  // quedó sin guardar. Aquí se termina lo que no pudo hacer el panel:
  // comprimirla y guardarla. El stream trae luego la tarjeta con la foto
  Future<void> _reviewForLostPhoto() async {
    try {
      final lost = await PhotoService().recoverLostPhoto();
      if (lost == null) return; // lo normal: no había nada pendiente

      final bytes = await compressPhoto(lost.file);
      // Si el frasco se borró mientras tanto, update() falla y va al catch
      await _vaultService.saveImage(lost.itemId, bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hemos recuperado la foto de tu frasco'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('No se pudo recuperar la foto perdida: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo recuperar la última foto que hiciste'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _subscribeToVault() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Cancelamos cualquier suscripción previa por seguridad
    _vaultSubscription?.cancel();

    // 2. Nos suscribimos en tiempo real a la colección vault del usuario
    _vaultSubscription =
        _vaultService.streamUserVault(onlyRecent: _onlyRecent).listen(
          (items) {
        if (!mounted) return;
        setState(() {
          _vaultItems = items;
          _isLoading = false;
          // Sin perfumes no hay nada que editar
          if (items.isEmpty) _isEditing = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  // Al activar o quitar el filtro, cancelamos la escucha anterior y nos
  // suscribimos a la nueva consulta (_subscribeToVault ya cancela la vieja)
  void _toggleRecentFilter(bool selected) {
    setState(() => _onlyRecent = selected);
    _subscribeToVault();
  }

  @override
  void dispose() {
    //Cancelamos la suscripción activa al destruir la pantalla
    _vaultSubscription?.cancel();
    super.dispose();
  }

  Future<void> _confirmDelete(VaultItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar perfume'),
        content: Text('¿Quieres quitar ${item.name} de tu armario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _vaultService.removeFromVault(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} eliminado de tu armario'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bóveda personal")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // FASE 1: CARGANDO
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // FASE ERROR: Control de errores de red o base de datos con botón Reintentar
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error al cargar tu bóveda: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _subscribeToVault,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Con el filtro puesto solo vemos una parte del armario, así que no
    // sabemos si está lleno. El detalle vuelve a comprobar el límite al añadir
    final bool isFull =
        !_onlyRecent && _vaultItems.length >= VaultService.freeLimit;

    // FASE 2: VACÍO (de verdad, no porque el filtro lo deje vacío)
    if (_vaultItems.isEmpty && !_onlyRecent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.inventory_2, size: 100, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              const Text(
                'Tu bóveda está vacía',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Empieza a registrar tus botellas y decants para tener tu colección controlada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.explore),
                icon: const Icon(Icons.search),
                label: const Text('Añadir mis perfumes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // FASE 3: CON DATOS
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _onlyRecent
                    ? 'Mi Armario (${_vaultItems.length} recientes)'
                    : 'Mi Armario (${_vaultItems.length}/${VaultService.freeLimit})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FilterChip(
                label: const Text('Últimos ${VaultService.recentDays} días'),
                selected: _onlyRecent,
                onSelected: _toggleRecentFilter,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isFull ? null : () => context.go(AppRoutes.explore),
                      icon: Icon(
                        isFull ? Icons.block : Icons.add,
                        color: isFull ? Colors.white : null,
                      ),
                      // FittedBox encoge el texto si el botón no le deja sitio
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isFull ? 'Límite alcanzado' : 'Añadir perfume',
                          style: TextStyle(color: isFull ? Colors.white : null),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: isFull ? Colors.red.shade400 : null,
                        disabledBackgroundColor: isFull ? Colors.red.shade400 : null,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      icon: Icon(_isEditing ? Icons.check : Icons.edit),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_isEditing ? 'Hecho' : 'Editar armario'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: Colors.deepPurple.shade50,
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _vaultItems.isEmpty
              // Solo llega aquí con el filtro puesto (sin él se ve la FASE 2)
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No has añadido perfumes en los últimos '
                      '${VaultService.recentDays} días.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _vaultItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = _vaultItems[index];
              return FlipCard(
                  key: ValueKey(item.id),
                  width: 500,
                  height: 260,
                  borderRadius: 24,
                  edgeColor: Colors.amber.shade200,
                  front: VaultCardFront(item:item),
                  back: VaultCardBack(item:item),
                  overlay: _isEditing
                      ? VaultCardEditOverlay(
                          borderRadius: 24,
                          onEdit: () => VaultEditSheet.show(context, item),
                          onDelete: () => _confirmDelete(item),
                        )
                      : null,
              );
            },
          ),
        ),
      ],
    );
  }
}