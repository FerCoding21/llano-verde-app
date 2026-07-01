import 'dart:typed_data';

import '../supabase/supabase_client.dart';

class InventarioStorageRepository {
  static const _bucket = 'equipos-imagenes';

  final _storage = SupabaseClientConfig.client.storage.from(_bucket);

  Future<String> subirImagen({
    required int numeroActivo,
    required Uint8List bytes,
    required String extension,
  }) async {
    final ruta =
        '$numeroActivo/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _storage.uploadBinary(ruta, bytes);
    return _storage.getPublicUrl(ruta);
  }

  Future<void> eliminarImagen(String urlImagen) async {
    final ruta = urlImagen.split('$_bucket/').last;
    await _storage.remove([ruta]);
  }
}
