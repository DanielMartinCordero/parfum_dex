import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/vault_item.dart';
import '../services/vault_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final VaultService _vaultService = VaultService();
  late Stream<List<VaultItem>> _vaultStream;

  @override
  void initState() {
    super.initState();
    // Suscribimos la pantalla a la subcolección del usuario
    _vaultStream = _vaultService.streamUserVault();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bóveda personal")),
      body: StreamBuilder<List<VaultItem>>(
        stream: _vaultStream,
        builder: (context, snapshot) {
          // FASE 1: CARGANDO
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Control de errores de red o base de datos
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar tu bóveda: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final vaultItems = snapshot.data ?? [];
          final bool isFull = vaultItems.length >= VaultService.freeLimit;

          // FASE 2: VACÍO
          if (vaultItems.isEmpty) {
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
                      onPressed: () {
                        // Enviamos al usuario a la pestaña de explorar
                        context.go('/explore');
                      },
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
              // Cabecera con contador y botón de añadir
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mi Armario (${vaultItems.length}/${VaultService.freeLimit})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: isFull
                          ? null // Deshabilita el botón internamente si está lleno
                          : () => context.go('/explore'),
                      icon: Icon(
                        isFull ? Icons.block : Icons.add,
                        color: isFull ? Colors.white : null,
                      ),
                      label: Text(
                        isFull ? 'Límite alcanzado' : 'Añadir perfume',
                        style: TextStyle(color: isFull ? Colors.white : null),
                      ),
                      style: ElevatedButton.styleFrom(
                        // Si está lleno, forzamos color rojo. Si no, usa el color por defecto (morado)
                        backgroundColor: isFull ? Colors.red.shade400 : null,
                        disabledBackgroundColor: isFull ? Colors.red.shade400 : null,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de perfumes (Ocupa el resto de la pantalla)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vaultItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = vaultItems[index];
                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${item.remainingMl} ml / ${item.capacityMl} ml'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Abrir detalles de este VaultItem
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
