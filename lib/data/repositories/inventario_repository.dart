import '../../domain/models/inventario.dart';
import '../supabase/supabase_client.dart';

class InventarioRepository {
  final _table = SupabaseClientConfig.client.from('inventario');

  Future<List<Inventario>> getAll({
    EstadoInventario? estado,
    String? busqueda,
  }) async {
    var query = _table.select();

    if (estado != null) {
      query = query.eq('estado', estado.name);
    }
    if (busqueda != null && busqueda.isNotEmpty) {
      query = query.ilike('nombre_equipo', '%$busqueda%');
    }

    final data = await query.order('numero_activo');
    return data.map(Inventario.fromMap).toList();
  }

  Future<Inventario?> getById(int numeroActivo) async {
    final data = await _table
        .select()
        .eq('numero_activo', numeroActivo)
        .maybeSingle();
    return data == null ? null : Inventario.fromMap(data);
  }

  Future<Inventario> create(Inventario inventario) async {
    final data = await _table.insert(inventario.toMap()).select().single();
    return Inventario.fromMap(data);
  }

  Future<Inventario> update(Inventario inventario) async {
    final data = await _table
        .update(inventario.toMap())
        .eq('numero_activo', inventario.numeroActivo!)
        .select()
        .single();
    return Inventario.fromMap(data);
  }

  Future<void> delete(int numeroActivo) async {
    await _table.delete().eq('numero_activo', numeroActivo);
  }
}
