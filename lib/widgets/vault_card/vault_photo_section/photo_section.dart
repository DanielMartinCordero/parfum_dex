import 'package:flutter/foundation.dart'; // defaultTargetPlatform y Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../models/vault_item.dart';
import '../../../services/photo_services/image_compression/image_compression.dart';
import '../../../services/photo_services/photo_service.dart';
import '../../../services/vault_service.dart';
import 'photo_selector.dart';

// Sección de la foto del frasco dentro del panel de edición: vista previa,
// botones de añadir/cambiar/quitar y el mensaje de error. Va por su cuenta:
// la foto se guarda al momento, sin esperar a "Guardar cambios"
class PhotoSection extends StatefulWidget {
  // Solo necesita el frasco: su id para guardar, su foto y la del catálogo
  final VaultItem item;
  //Para avisar a vault_edit_sheet de que ha habido cambios, y mostrar el snackbar de cambios guardados
  final VoidCallback? onPhotoChanged;

  const PhotoSection({
    super.key,
    required this.item,
    this.onPhotoChanged,
  });

  @override
  State<PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<PhotoSection> {
  final VaultService _vaultService = VaultService();
  final PhotoService _photoService = PhotoService();

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

  // La foto que se ve ahora, o null si no hay
  Uint8List? get _currentPhoto =>
      _photoRemoved ? null : _previewPhoto ?? widget.item.userBottlePhoto;

  @override
  Widget build(BuildContext context) {
    // Copias locales: así Dart sabe que tras comprobarlas no son null
    final Uint8List? photo = _currentPhoto;
    final String? error = _photoError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildThumbnail(photo),
            const SizedBox(width: 16),
            Expanded(
              child: _isPhotoLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _handlePickPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            photo == null ? 'Añadir foto' : 'Cambiar foto',
                          ),
                        ),
                        if (photo != null)
                          TextButton.icon(
                            onPressed: _handleRemovePhoto,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar foto'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          if (_showSettingsButton)
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Abrir ajustes'),
            ),
        ],
      ],
    );
  }

  // Cuadro pequeño con la foto del usuario o, si no hay, la del catálogo
  Widget _buildThumbnail(Uint8List? photo) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias, // recorta la foto con las esquinas
      child: photo != null
          ? Image.memory(
              photo,
              fit: BoxFit.cover,
              gaplessPlayback: true, // al cambiarla no parpadea en blanco
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                color: Colors.grey.shade400,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                widget.item.imageUrl,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
    );
  }

  // Elegir foto -> comprimir -> vista previa -> guardar en Firestore
  Future<void> _handlePickPhoto() async {
    final bool? isCamera = _showCamera
        ? await PhotoSelector.show(context)
        : false; // web en PC: directamente la galería
    if (isCamera == null) return; // cerró la ventana sin elegir

    // Por si falla la subida: así se vuelve a lo que había
    final Uint8List? previousPhoto = _previewPhoto;
    final bool previousRemoved = _photoRemoved;

    try {
      final XFile? file = await _photoService.pickImage(isCamera, widget.item.id);
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
      widget.onPhotoChanged?.call();
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
      widget.onPhotoChanged?.call();
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
}
