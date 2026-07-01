import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';
import '../supabase/supabase_client.dart';

class BoletaRepository {
  final _boletas = SupabaseClientConfig.client.from('boleta');
  final _equipos = SupabaseClientConfig.client.from('boleta_equipo');
  final _imagenes = SupabaseClientConfig.client.from('boleta_imagen');

  Future<List<Boleta>> getAll() async {
    final data = await _boletas
        .select()
        .order('fecha_creacion', ascending: false);
    return data.map(Boleta.fromMap).toList();
  }

  Future<Boleta?> getById(int boletaId) async {
    final data = await _boletas
        .select()
        .eq('boleta_id', boletaId)
        .maybeSingle();
    return data == null ? null : Boleta.fromMap(data);
  }

  Future<Boleta> create(Boleta boleta) async {
    final data = await _boletas.insert(boleta.toMap()).select().single();
    return Boleta.fromMap(data);
  }

  Future<Boleta> update(Boleta boleta) async {
    final data = await _boletas
        .update(boleta.toMap())
        .eq('boleta_id', boleta.boletaId!)
        .select()
        .single();
    return Boleta.fromMap(data);
  }

  Future<void> delete(int boletaId) async {
    await _equipos.delete().eq('boleta_id', boletaId);
    await _imagenes.delete().eq('boleta_id', boletaId);
    await _boletas.delete().eq('boleta_id', boletaId);
  }

  // ── Equipos ────────────────────────────────────────────────────────────────

  Future<List<BoletaEquipo>> getEquipos(int boletaId) async {
    final data = await _equipos
        .select('*, inventario(nombre_equipo)')
        .eq('boleta_id', boletaId);
    return data.map(BoletaEquipo.fromMap).toList();
  }

  Future<BoletaEquipo> addEquipo(BoletaEquipo equipo) async {
    final data = await _equipos.insert(equipo.toMap()).select().single();
    return BoletaEquipo.fromMap(data);
  }

  Future<void> deleteEquipo(int boletaEquipoId) async {
    await _equipos.delete().eq('boleta_equipo_id', boletaEquipoId);
  }
}
