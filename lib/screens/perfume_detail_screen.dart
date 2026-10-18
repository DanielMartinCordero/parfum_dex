
import 'package:flutter/material.dart';
import '../models/perfume.dart';
import '../services/perfumes_service.dart';
import '../services/vault_service.dart';

class PerfumeDetailScreen extends StatefulWidget {
  final String perfumeId;
  final Perfume? initialPerfume;

  const PerfumeDetailScreen({
    super.key, 
    required this.perfumeId, 
    this.initialPerfume
  });

  @override
  State<PerfumeDetailScreen> createState() => _PerfumeDetailScreenState();
}

class _PerfumeDetailScreenState extends State<PerfumeDetailScreen> {
  late Future<Perfume?> _perfumeFuture;
  final VaultService _vaultService = VaultService();
  bool _isAdding = false; // Bloqueo para evitar la condición de carrera

  @override
  void initState() {
    super.initState();
    // Si la ruta nos pasó el objeto Perfume (porque venimos del Catálogo),
    // creamos un Future que se resuelve instantáneamente.
    if (widget.initialPerfume != null) {
      _perfumeFuture = Future.value(widget.initialPerfume);
    }
    // Si el objeto es nulo (porque el usuario recargó la web con F5),
    // vamos a Firebase a descargarlo usando el ID de la URL.
    else {
      _perfumeFuture = PerfumesService().getPerfumeById(widget.perfumeId);
    }
  }

  // Función extraída para manejar la lógica de añadir al armario
  Future<void> _handleAddPerfumeToVault(Perfume perfume) async {
    setState(() {
      _isAdding = true;
    });

    try {
      final bool alreadyExists = await _vaultService.isPerfumeInVault(perfume.id);
      
      if (!mounted) return;

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Ya tienes ${perfume.name} en tu armario!'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return; 
      }

      final count = await _vaultService.getVaultItemsCount();

      if (!mounted) return;

      if (count >= VaultService.freeLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Límite de 5 perfumes alcanzado. No puedes añadir más en la versión gratuita.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _vaultService.addPerfumeToVault(perfume);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${perfume.name} añadido a tu Bóveda!'),
            backgroundColor: Colors.green,
          )
      );
    } catch(e) {
      print('Error al añadir el perfume: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la operación. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Perfume?>(
        future: _perfumeFuture,
        builder: (context, snapshot) {
          // 1. Estado de Carga (Solo se verá si hacemos F5, si venimos del catálogo será instantáneo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Estado de Error o Perfume Borrado
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('No se pudo cargar el perfume o ya no existe.'),
              ),
            );
          }

          // 3. Estado de Éxito (Pintamos el perfume)
          final perfume = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              title: Text(perfume.name),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabecera con la imagen (Hero Animation para transición suave)
                  Container(
                    height: 300,
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Hero(
                      tag: 'perfume-${perfume.id}', // Usamos el ID único
                      child: Image.network(
                        perfume.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  // 2. Información Principal (Marca, Nombre, Concentración)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfume.brand.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          perfume.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                perfume.concentration,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.deepPurple.shade50,
                              side: BorderSide.none,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('${perfume.nominalMl} ml'),
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // 3. Notas Olfativas (Solo pintamos las que existan)
                  if (perfume.notes.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 8.0),
                      child: Text(
                        "Pirámide Olfativa",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildNotesSection("Salida", perfume.notes['top']),
                    _buildNotesSection("Corazón", perfume.notes['heart']),
                    _buildNotesSection("Fondo", perfume.notes['base']),
                    const Divider(height: 32),
                  ],

                  // 4. Temporadas (Seasons)
                  if (perfume.season.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ideal para",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: perfume.season
                                .map((s) => Chip(
                                      label: Text(
                                        s.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: Colors.deepPurple,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  // 5. Ofertas (Precios)
                  if (perfume.prices.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Mejores Ofertas",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...perfume.prices.map((offer) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24.0),
                        leading: const Icon(
                            Icons.storefront, color: Colors.deepPurple),
                        title: Text(offer.storeName, style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                        trailing: Text(
                          '${offer.price.toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepPurple),
                        ),
                        subtitle: offer.inStock
                            ? const Text(
                            "En stock", style: TextStyle(color: Colors.green))
                            : const Text(
                            "Agotado", style: TextStyle(color: Colors.red)),
                        onTap: () {
                          //Pendiente de implementar urls reales
                        },
                      );
                    }),
                    const SizedBox(height: 40),
                  ] else
                    ...[
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                            "No hay ofertas disponibles para este perfume.",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  const Divider(height: 32),
                  
                  // Botón centrado, sin ocupar todo el ancho, con márgenes de seguridad por abajo
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                      child: Center(
                        child: SizedBox(
                          width: 260, // Ancho fijo para que no se estire al 100%
                          height: 50, // Un poco más alto para que sea fácil de tocar
                          child: ElevatedButton.icon(
                            // Desactiva el botón si _isAdding es true
                            onPressed: _isAdding ? null : () => _handleAddPerfumeToVault(perfume),
                            // Cambia el icono por un progreso si está cargando
                            icon: _isAdding
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Icon(Icons.add_box),
                            label: Text(
                              _isAdding ? 'Comprobando...' : 'Añadir a mi armario',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ); // Fin del Scaffold
        }
    ); // Fin del builder del FutureBuilder
  }

  // Pequeño widget auxiliar para pintar las listas de notas
  Widget _buildNotesSection(String title, List<String>? notes) {
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: TextStyle(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: -8,
              children: notes.map((note) => Chip(
                label: Text(
                  note, 
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  )
                ),
                backgroundColor: Colors.deepPurple,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}