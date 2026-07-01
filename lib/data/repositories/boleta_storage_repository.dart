import 'dart:typed_data';

import '../supabase/supabase_client.dart';

class BoletaStorageRepository {
  static const _bucket = 'boleta-imagenes';
  final _storage = SupabaseClientConfig.client.storage;

  Future<String> subirImagen(Uint8List bytes, String extension) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _storage.from(_bucket).uploadBinary(path, bytes);
    return _storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> eliminarImagen(String publicUrl) async {
    final path = publicUrl.split('$_bucket/').last;
    await _storage.from(_bucket).remove([path]);
  }
}
