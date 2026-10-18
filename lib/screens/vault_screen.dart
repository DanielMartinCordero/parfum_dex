import 'dart:async'; // <-- Necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/vault_item.dart';
import '../services/vault_service.dart';
import '../widgets/vault_item_card.dart';

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

  @override
  void initState() {
    super.initState();
    _subscribeToVault();
  }

  void _subscribeToVault() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Cancelamos cualquier suscripción previa por seguridad
    _vaultSubscription?.cancel();

    // 2. Nos suscribimos en tiempo real a la colección vault del usuario
    _vaultSubscription = _vaultService.streamUserVault().listen(
          (items) {
        if (!mounted) return;
        setState(() {
          _vaultItems = items;
          _isLoading = false;
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

  @override
  void dispose() {
    //Cancelamos la suscripción activa al destruir la pantalla
    _vaultSubscription?.cancel();
    super.dispose();
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

    final bool isFull = _vaultItems.length >= VaultService.freeLimit;

    // FASE 2: VACÍO
    if (_vaultItems.isEmpty) {
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
                onPressed: () => context.go('/explore'),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi Armario (${_vaultItems.length}/${VaultService.freeLimit})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: isFull ? null : () => context.go('/explore'),
                icon: Icon(
                  isFull ? Icons.block : Icons.add,
                  color: isFull ? Colors.white : null,
                ),
                label: Text(
                  isFull ? 'Límite alcanzado' : 'Añadir perfume',
                  style: TextStyle(color: isFull ? Colors.white : null),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFull ? Colors.red.shade400 : null,
                  disabledBackgroundColor: isFull ? Colors.red.shade400 : null,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _vaultItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _vaultItems[index];
              return VaultItemCard(
                item: item,
                onTap: () {
                  debugPrint("Tocado: ${item.name}");
                },
              );
            },
          ),
        ),
      ],
    );
  }
}