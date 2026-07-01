import '../../domain/models/inventario_imagen.dart';
import '../supabase/supabase_client.dart';

class InventarioImagenRepository {
  final _table = SupabaseClientConfig.client.from('inventario_imagenes');

  Future<List<InventarioImagen>> getByNumeroActivo(int numeroActivo) async {
    final data = await _table
        .select()
        .eq('numero_activo', numeroActivo)
        .order('fecha_subida');
    return data.map(InventarioImagen.fromMap).toList();
  }

  Future<InventarioImagen> create(InventarioImagen imagen) async {
    final data = await _table.insert(imagen.toMap()).select().single();
    return InventarioImagen.fromMap(data);
  }

  Future<void> delete(int imagenId) async {
    await _table.delete().eq('imagen_id', imagenId);
  }
}
