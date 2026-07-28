import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';
import '../supabase/supabase_client.dart';

class ProformaRepository {
  final _proformas = SupabaseClientConfig.client.from('proforma');
  final _equipos = SupabaseClientConfig.client.from('proforma_equipo');

  // ── Proformas ──────────────────────────────────────────────────────────────

  Future<List<Proforma>> getAll() async {
    final data = await _proformas.select().order('fecha_creacion', ascending: false);
    return data.map(Proforma.fromMap).toList();
  }

  Future<Proforma?> getById(int proformaId) async {
    final data = await _proformas
        .select()
        .eq('proforma_id', proformaId)
        .maybeSingle();
    return data == null ? null : Proforma.fromMap(data);
  }

  Future<Proforma> create(Proforma proforma) async {
    final data = await _proformas.insert(proforma.toMap()).select().single();
    return Proforma.fromMap(data);
  }

  Future<Proforma> update(Proforma proforma) async {
    final data = await _proformas
        .update(proforma.toMap())
        .eq('proforma_id', proforma.proformaId!)
        .select()
        .single();
    return Proforma.fromMap(data);
  }

  Future<void> delete(int proformaId) async {
    // Primero elimina los equipos asociados (no hay CASCADE en el esquema)
    await _equipos.delete().eq('proforma_id', proformaId);
    await _proformas.delete().eq('proforma_id', proformaId);
  }

  // ── Equipos de proforma ────────────────────────────────────────────────────

  Future<List<ProformaEquipo>> getEquipos(int proformaId) async {
    // El join 'inventario(nombre_equipo)' trae el nombre del equipo
    // usando el FK numero_activo → inventario sin hacer un query extra por ítem
    final data = await _equipos
        .select('*, inventario(nombre_equipo, foto_portada)')
        .eq('proforma_id', proformaId);
    return data.map(ProformaEquipo.fromMap).toList();
  }

  Future<ProformaEquipo> addEquipo(ProformaEquipo equipo) async {
    final data = await _equipos.insert(equipo.toMap()).select().single();
    return ProformaEquipo.fromMap(data);
  }

  Future<ProformaEquipo> updateEquipo(ProformaEquipo equipo) async {
    final data = await _equipos
        .update(equipo.toMap())
        .eq('proforma_equipo_id', equipo.proformaEquipoId!)
        .select()
        .single();
    return ProformaEquipo.fromMap(data);
  }

  Future<void> deleteEquipo(int proformaEquipoId) async {
    await _equipos.delete().eq('proforma_equipo_id', proformaEquipoId);
  }
}
