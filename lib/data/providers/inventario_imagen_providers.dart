import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventario_imagen.dart';
import '../repositories/inventario_imagen_repository.dart';
import '../repositories/inventario_storage_repository.dart';

final inventarioImagenRepositoryProvider = Provider<InventarioImagenRepository>((ref) {
  return InventarioImagenRepository();
});

final inventarioStorageRepositoryProvider = Provider<InventarioStorageRepository>((ref) {
  return InventarioStorageRepository();
});

final imagenesEquipoProvider =
    FutureProvider.family<List<InventarioImagen>, int>((ref, numeroActivo) {
  return ref
      .watch(inventarioImagenRepositoryProvider)
      .getByNumeroActivo(numeroActivo);
});

class ImagenesEquipoController {
  ImagenesEquipoController(this._ref);

  final Ref _ref;

  Future<void> agregarImagen({
    required int numeroActivo,
    required Uint8List bytes,
    required String extension,
  }) async {
    final url = await _ref.read(inventarioStorageRepositoryProvider).subirImagen(
          numeroActivo: numeroActivo,
          bytes: bytes,
          extension: extension,
        );

    await _ref.read(inventarioImagenRepositoryProvider).create(
          InventarioImagen(numeroActivo: numeroActivo, urlImagen: url),
        );

    _ref.invalidate(imagenesEquipoProvider(numeroActivo));
  }

  Future<void> eliminarImagen(InventarioImagen imagen) async {
    await _ref
        .read(inventarioStorageRepositoryProvider)
        .eliminarImagen(imagen.urlImagen);
    await _ref
        .read(inventarioImagenRepositoryProvider)
        .delete(imagen.imagenId!);

    if (imagen.numeroActivo != null) {
      _ref.invalidate(imagenesEquipoProvider(imagen.numeroActivo!));
    }
  }
}

final imagenesEquipoControllerProvider = Provider<ImagenesEquipoController>((ref) {
  return ImagenesEquipoController(ref);
});
