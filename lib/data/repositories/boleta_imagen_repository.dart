import '../../domain/models/boleta_imagen.dart';
import '../supabase/supabase_client.dart';

class BoletaImagenRepository {
  final _imagenes = SupabaseClientConfig.client.from('boleta_imagen');

  Future<List<BoletaImagen>> getByBoletaId(int boletaId) async {
    final data = await _imagenes
        .select()
        .eq('boleta_id', boletaId)
        .order('fecha_subida');
    return data.map(BoletaImagen.fromMap).toList();
  }

  Future<BoletaImagen> create(BoletaImagen imagen) async {
    final data = await _imagenes.insert(imagen.toMap()).select().single();
    return BoletaImagen.fromMap(data);
  }

  Future<void> delete(int imagenId) async {
    await _imagenes.delete().eq('imagen_id', imagenId);
  }
}
