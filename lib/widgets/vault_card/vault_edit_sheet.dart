import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/vault_item.dart';
import '../../services/vault_service.dart';
import '../../utils/validators.dart';
import 'vault_photo_section/photo_section.dart';

const double _starWidth = 40;

class VaultEditSheet extends StatefulWidget {
  final VaultItem item;

  const VaultEditSheet({
    super.key,
    required this.item,
  });

  // Abre el panel desde abajo, por encima de la barra de navegación
  static Future<void> show(BuildContext context, VaultItem item) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, //Le permite subir, para el teclado en móviles
      useSafeArea: true,
      showDragHandle: true,
      // Permite que el panel suba cuando aparece el teclado
      isScrollControlled: true,
      builder: (context) => VaultEditSheet(item: item),
    );
  }

  @override
  State<VaultEditSheet> createState() => _VaultEditSheetState();
}

class _VaultEditSheetState extends State<VaultEditSheet> {
  final VaultService _vaultService = VaultService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _capacityController;
  late final TextEditingController _remainingController;
  late final TextEditingController _priceController;

  double? _rating;
  bool _isSaving = false;
  bool _photoChanged = false;

  @override
  void initState() {
    super.initState();
    // Rellenamos el formulario con lo que ya tiene la tarjeta
    final VaultItem item = widget.item;
    _capacityController = TextEditingController();
    final double? remaining = item.remainingMl ?? item.capacityMl?.toDouble();
    _remainingController = TextEditingController(
      text: remaining != null ? _formatNumber(remaining) : '',
    );
    _priceController = TextEditingController(
      text: item.purchasePrice != null
          ? _formatNumber(item.purchasePrice!)
          : '',
    );
    _rating = item.rating;
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _remainingController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 45.0 se muestra como "45" y 45.5 como "45.5"
  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  // Convierte el texto en número, aceptando coma o punto como decimal
  double? _parseNumber(String? text) {
    return double.tryParse((text ?? '').trim().replaceAll(',', '.'));
  }

  // Capacidad del bote: la que ya tenía o la que está escribiendo el usuario.
  // Devuelve null mientras no haya una capacidad válida.
  int? get _capacity {
    final int? saved = widget.item.capacityMl;
    if (saved != null) return saved;
    final int? typed = int.tryParse(_capacityController.text.trim());
    return Validators.validateCapacityMl(typed) == null ? typed : null;
  }

  String? _validateCapacity(String? value) {
    // La capacidad es opcional: vacío significa "sigo sin saberla"
    if (value == null || value.trim().isEmpty) return null;

    final int? capacity = int.tryParse(value.trim());
    if (capacity == null) {
      return 'Introduce un número entero';
    }
    return Validators.validateCapacityMl(capacity);
  }

  String? _validateRemaining(String? value) {
    final int? capacity = _capacity;
    if (capacity == null) return null;
    // Vacío significa que el bote está lleno
    if (value == null || value.trim().isEmpty) return null;

    final double? remaining = _parseNumber(value);
    if (remaining == null) {
      return 'Introduce un número válido';
    }
    return Validators.validateRemainingMl(remaining, capacity);
  }

  String? _validatePrice(String? value) {
    // El precio es opcional: vacío significa "sin precio"
    if (value == null || value.trim().isEmpty) return null;

    final double? price = _parseNumber(value);
    if (price == null) {
      return 'Introduce un número válido';
    }
    return Validators.validatePurchasePrice(price);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Los guardamos antes del await: el panel puede cerrarse mientras se guarda
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    setState(() {
      _isSaving = true;
    });

    // Sin capacidad no se guardan ml restantes; con capacidad, vacío es "lleno"
    final int? capacity = _capacity;
    final double? remaining = capacity == null
        ? null
        : _parseNumber(_remainingController.text) ?? capacity.toDouble();

    SnackBar snackBar;
    try {
      final bool hasChanged = await _vaultService.updateVaultItem(
        widget.item,
        capacityMl: capacity,
        remainingMl: remaining,
        purchasePrice: _parseNumber(_priceController.text),
        rating: _rating,
      );
      snackBar = (hasChanged || _photoChanged)
          ? const SnackBar(
              content: Text('Cambios guardados'),
              backgroundColor: Colors.green,
            )
          : SnackBar(
              content: const Text('No has cambiado ningún dato'),
              backgroundColor: Colors.orange.shade800,
            );
    } catch (e) {
      snackBar = const SnackBar(
        content: Text('Ha ocurrido un error'),
        backgroundColor: Colors.red,
      );
    }

    // Cerramos primero: el panel taparía cualquier SnackBar
    if (mounted) navigator.pop();
    messenger.showSnackBar(snackBar);
  }

  // Volver a tocar el valor que ya está marcado quita la valoración
  void _handleStarTap(double value) {
    setState(() {
      _rating = _rating == value ? null : value;
    });
  }


  IconData _starIcon(int star) {
    final double rating = _rating ?? 0;
    if (rating >= star) return Icons.star;
    if (rating >= star - 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    final VaultItem item = widget.item;
    final int? capacity = _capacity;

    return Padding(
      // Deja hueco al teclado para que no tape los campos
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.brand.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // 0. Foto del frasco
              PhotoSection(item: item, onPhotoChanged: () => _photoChanged = true),
              const SizedBox(height: 24),

              // 1. Capacidad: solo se pide si el perfume no la traía del catálogo
              if (item.capacityMl == null) ...[
                TextFormField(
                  controller: _capacityController,
                  validator: _validateCapacity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // Redibujamos para mostrar el campo de ml restantes al escribirla
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Capacidad del bote (opcional)',
                    helperText: 'Añádela para controlar cuánto te queda',
                    suffixText: 'ml',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_drink_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Mililitros restantes: solo si conocemos la capacidad
              if (capacity != null) ...[
                TextFormField(
                  controller: _remainingController,
                  validator: _validateRemaining,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mililitros restantes',
                    helperText: 'Capacidad del bote: $capacity ml. Vacío si está lleno',
                    suffixText: 'ml',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Precio de compra
              TextFormField(
                controller: _priceController,
                validator: _validatePrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Precio de compra (opcional)',
                  suffixText: '€',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Valoración
              const Text(
                'Valoración',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int star = 1; star <= Validators.maxRating; star++)
                    // Necesario para poder pulsar la mitad o la estrella entera
                    GestureDetector(
                      // Sin esto, los huecos alrededor del dibujo no reciben el toque
                      behavior: HitTestBehavior.opaque,
                      // onTapUp espera a soltar: hacer scroll no cambia la valoración
                      onTapUp: (details) {
                        final bool isLeftHalf =
                            details.localPosition.dx < _starWidth / 2;
                        _handleStarTap(isLeftHalf ? star - 0.5 : star.toDouble());
                      },
                      child: SizedBox(
                        width: _starWidth,
                        height: 48,
                        child: Icon(
                          _starIcon(star),
                          size: 32,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Guardar cambios',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
