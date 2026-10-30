import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'theme/context_ext.dart';

/// Roda em isolate separado via compute() pra não travar a UI. Mantém a
/// mesma compressão de sempre (máx. 300px, JPEG q75 ≈ 15–40 KB) — precisa
/// ficar bem menor que o limite de 1MB por documento do Firestore.
List<int>? comprimirFotoPerfil(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final resized = img.copyResize(
    decoded,
    width: decoded.width > decoded.height ? 300 : -1,
    height: decoded.width > decoded.height ? -1 : 300,
  );
  return img.encodeJpg(resized, quality: 75);
}

/// Fluxo completo de foto de perfil: escolhe câmera ou galeria, deixa
/// recortar/reenquadrar (import pro reconhecimento facial, que usa essa
/// mesma foto como referência) e já devolve os bytes comprimidos, prontos
/// pra virar `fotoBase64`. Retorna `null` se cancelar em qualquer etapa.
Future<Uint8List?> escolherFotoPerfil(BuildContext context) async {
  final origem = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: sheetContext.c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text(sheetContext.l10n.apPhotoSourceCamera),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(sheetContext.l10n.apPhotoSourceGallery),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (origem == null || !context.mounted) return null;

  final picked = await ImagePicker().pickImage(
    source: origem,
    imageQuality: 95,
    preferredCameraDevice: CameraDevice.front,
  );
  if (picked == null || !context.mounted) return null;

  final corTexto = Theme.of(context).colorScheme.onSurface;
  final corFundo = Theme.of(context).colorScheme.surface;
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: context.l10n.apAdjustPhoto,
        toolbarColor: corFundo,
        toolbarWidgetColor: corTexto,
        lockAspectRatio: true,
        cropStyle: CropStyle.circle,
      ),
      IOSUiSettings(
        title: context.l10n.apAdjustPhoto,
        aspectRatioLockEnabled: true,
        cropStyle: CropStyle.circle,
      ),
    ],
  );
  if (cropped == null) return null;

  final bytes = await File(cropped.path).readAsBytes();
  final compressed = await compute(comprimirFotoPerfil, bytes);
  return compressed == null ? null : Uint8List.fromList(compressed);
}
