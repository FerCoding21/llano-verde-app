import 'package:intl/intl.dart';

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

  // Boletas activas ordenadas por fecha_retiro (más urgentes primero)
  Future<List<Boleta>> getActivas() async {
    final data = await _boletas
        .select()
        .eq('estado', 'activa')
        .order('fecha_retiro', ascending: true);
    return data.map(Boleta.fromMap).toList();
  }

  Future<void> extenderFechaRetiro(int boletaId, DateTime nuevaFecha) async {
    await _boletas
        .update({'fecha_retiro': DateFormat('yyyy-MM-dd').format(nuevaFecha)})
        .eq('boleta_id', boletaId);
  }

  Future<void> finalizar(int boletaId) async {
    await _boletas
        .update({'estado': 'finalizada'})
        .eq('boleta_id', boletaId);
  }

  Future<void> delete(int boletaId) async {
    await _equipos.delete().eq('boleta_id', boletaId);
    await _imagenes.delete().eq('boleta_id', boletaId);
    await _boletas.delete().eq('boleta_id', boletaId);
  }

  // ── Equipos ────────────────────────────────────────────────────────────────

  Future<List<BoletaEquipo>> getEquipos(int boletaId) async {
    final data = await _equipos
        .select('*, inventario(nombre_equipo, foto_portada)')
        .eq('boleta_id', boletaId);
    return data.map(BoletaEquipo.fromMap).toList();
  }

  // Solo los numero_activo — sin JOIN, para liberar equipos al finalizar
  Future<List<int>> getNumeroActivos(int boletaId) async {
    final data = await _equipos
        .select('numero_activo')
        .eq('boleta_id', boletaId);
    return data
        .map((e) => e['numero_activo'] as int?)
        .whereType<int>()
        .toList();
  }

  Future<BoletaEquipo> addEquipo(BoletaEquipo equipo) async {
    final data = await _equipos.insert(equipo.toMap()).select().single();
    return BoletaEquipo.fromMap(data);
  }

  Future<void> deleteEquipo(int boletaEquipoId) async {
    await _equipos.delete().eq('boleta_equipo_id', boletaEquipoId);
  }
}
