import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vault_item.dart';
import '../../services/photo_services/image_compression/image_compression.dart';
import '../../services/photo_services/photo_service.dart';
import '../../services/vault_service.dart';
import '../../utils/validators.dart';
import 'vault_photo_section/photo_selector.dart';
import 'vault_photo_section/photo_preview.dart';

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
  final PhotoService _photoService = PhotoService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _capacityController;
  late final TextEditingController _remainingController;
  late final TextEditingController _priceController;

  double? _rating;
  bool _isSaving = false;

  // ---------- Foto del frasco ----------
  // La cámara solo tiene sentido en móvil (app o navegador del móvil).
  // En web en un PC se va directo a la galería
  final bool _showCamera = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // widget.item no cambia mientras el panel está abierto, así que la foto
  // nueva se guarda aquí para enseñarla al momento
  Uint8List? _previewPhoto;
  // true si el usuario quitó la foto: así no vuelve a salir la de widget.item
  bool _photoRemoved = false;
  // Comprimiendo o subiendo: muestra el spinner y bloquea los botones
  bool _isPhotoLoading = false;
  // Mensaje de error dentro del panel (un SnackBar quedaría tapado por él)
  String? _photoError;
  // Permiso denegado para siempre: se ofrece abrir los ajustes
  bool _showSettingsButton = false;

  // La foto que se ve ahora en el panel, o null si no hay
  Uint8List? get _currentPhoto =>
      _photoRemoved ? null : _previewPhoto ?? widget.item.userBottlePhoto;

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
      snackBar = hasChanged
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

  // Elegir foto -> comprimir -> vista previa -> guardar en Firestore.
  // Se guarda al momento, sin esperar a "Guardar cambios"
  Future<void> _handlePickPhoto() async {
    final bool? isCamera = _showCamera
        ? await PhotoSelector.show(context)
        : false; // web en PC: directamente la galería
    if (isCamera == null) return; // cerró la ventana sin elegir

    // Por si falla la subida: así se vuelve a lo que había
    final Uint8List? previousPhoto = _previewPhoto;
    final bool previousRemoved = _photoRemoved;

    try {
      final XFile? file = await _photoService.pickImage(isCamera);
      // Canceló en la cámara o la galería, o el panel se cerró mientras
      if (file == null || !mounted) return;
      setState(() {
        _isPhotoLoading = true;
        _photoError = null;
        _showSettingsButton = false;
      });

      final Uint8List photo = await compressPhoto(file);
      if (!mounted) return;
      // Vista previa antes de subirla: el usuario la ve ya
      setState(() {
        _previewPhoto = photo;
        _photoRemoved = false;
      });

      await _vaultService.saveImage(widget.item.id, photo);
    } on PhotoException catch (e) {
      if (!mounted) return;
      setState(() {
        _photoError = _photoErrorMessage(e.failure);
        _showSettingsButton = e.failure == PhotoFailure.permanentlyDenied;
      });
    } catch (e) {
      debugPrint('Error al guardar la foto: $e');
      if (!mounted) return;
      setState(() {
        _previewPhoto = previousPhoto;
        _photoRemoved = previousRemoved;
        _photoError = 'No se pudo guardar la foto. Inténtalo de nuevo';
      });
    } finally {
      // finally se ejecuta siempre: haya ido bien, mal o con return
      if (mounted) setState(() => _isPhotoLoading = false);
    }
  }

  // Borra la foto en Firestore. El reverso vuelve a la imagen del catálogo
  Future<void> _handleRemovePhoto() async {
    final Uint8List? previousPhoto = _previewPhoto;

    setState(() {
      _isPhotoLoading = true;
      _photoError = null;
      _showSettingsButton = false;
      _previewPhoto = null;
      _photoRemoved = true;
    });

    try {
      await _vaultService.deleteImage(widget.item.id);
    } catch (e) {
      debugPrint('Error al quitar la foto: $e');
      if (!mounted) return;
      setState(() {
        _previewPhoto = previousPhoto;
        _photoRemoved = false;
        _photoError = 'No se pudo quitar la foto. Inténtalo de nuevo';
      });
    } finally {
      if (mounted) setState(() => _isPhotoLoading = false);
    }
  }

  // Texto para cada motivo de fallo de PhotoService o de la compresión
  String _photoErrorMessage(PhotoFailure failure) {
    switch (failure) {
      case PhotoFailure.denied:
        return 'Necesitas dar permiso a la cámara para hacer la foto';
      case PhotoFailure.permanentlyDenied:
        return 'El permiso de la cámara está bloqueado. Actívalo en los ajustes';
      case PhotoFailure.unsupportedFormat:
        return 'Formato de imagen no compatible. Prueba con una foto JPG o PNG';
      case PhotoFailure.tooLarge:
        return 'La foto es demasiado grande. Prueba con otra';
    }
  }
  // Vista previa a la izquierda y botones a la derecha; debajo, el error


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
              PhotoPreview(
                photo: _currentPhoto,
                imageUrl: item.imageUrl,
                isLoading: _isPhotoLoading,
                error: _photoError,
                showSettingsButton: _showSettingsButton,
                onPick: _handlePickPhoto,
                onRemove: _handleRemovePhoto
              ),
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
