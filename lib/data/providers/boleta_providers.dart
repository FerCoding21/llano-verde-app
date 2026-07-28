import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';
import '../../domain/models/boleta_imagen.dart';
import '../repositories/boleta_imagen_repository.dart';
import '../repositories/boleta_repository.dart';
import '../repositories/boleta_storage_repository.dart';

final boletaRepositoryProvider =
    Provider<BoletaRepository>((_) => BoletaRepository());

final boletaImagenRepositoryProvider =
    Provider<BoletaImagenRepository>((_) => BoletaImagenRepository());

final boletaStorageRepositoryProvider =
    Provider<BoletaStorageRepository>((_) => BoletaStorageRepository());

final boletaListProvider = FutureProvider<List<Boleta>>((ref) {
  return ref.watch(boletaRepositoryProvider).getAll();
});

// Solo boletas activas, ordenadas por fecha_retiro ASC (más urgentes primero)
final boletasActivasProvider = FutureProvider<List<Boleta>>((ref) {
  return ref.watch(boletaRepositoryProvider).getActivas();
});

final boletaEquiposProvider =
    FutureProvider.family<List<BoletaEquipo>, int>((ref, boletaId) {
  return ref.watch(boletaRepositoryProvider).getEquipos(boletaId);
});

final imagenesBoletaProvider =
    FutureProvider.family<List<BoletaImagen>, int>((ref, boletaId) {
  return ref.watch(boletaImagenRepositoryProvider).getByBoletaId(boletaId);
});

// Orquesta subida y eliminación de fotos invalidando el provider al terminar
class BoletaImagenesController {
  BoletaImagenesController(this.ref);
  final WidgetRef ref;

  Future<void> agregar(int boletaId, XFile archivo) async {
    final bytes = await archivo.readAsBytes();
    final ext = archivo.name.split('.').last;
    final url = await ref
        .read(boletaStorageRepositoryProvider)
        .subirImagen(bytes, ext);
    await ref
        .read(boletaImagenRepositoryProvider)
        .create(BoletaImagen(boletaId: boletaId, urlImagen: url));
    ref.invalidate(imagenesBoletaProvider(boletaId));
  }

  Future<void> eliminar(int boletaId, BoletaImagen imagen) async {
    await ref
        .read(boletaStorageRepositoryProvider)
        .eliminarImagen(imagen.urlImagen);
    await ref
        .read(boletaImagenRepositoryProvider)
        .delete(imagen.imagenId!);
    ref.invalidate(imagenesBoletaProvider(boletaId));
  }
}
