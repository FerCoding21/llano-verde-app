import 'package:intl/intl.dart';

class ProformaEquipo {
  final int? proformaEquipoId;
  final int? proformaId;
  final int? numeroActivo;
  final int cantidad;
  final int dias;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final double costo;
  final String? observacion;
  final String? nombreEquipo;

  const ProformaEquipo({
    this.proformaEquipoId,
    this.proformaId,
    this.numeroActivo,
    this.cantidad = 1,
    this.dias = 1,
    this.fechaDesde,
    this.fechaHasta,
    required this.costo,
    this.observacion,
    this.nombreEquipo,
  });

  double get total => costo * cantidad;

  factory ProformaEquipo.fromMap(Map<String, dynamic> map) {
    final inventario = map['inventario'] as Map<String, dynamic>?;
    return ProformaEquipo(
      proformaEquipoId: map['proforma_equipo_id'] as int?,
      proformaId: map['proforma_id'] as int?,
      numeroActivo: map['numero_activo'] as int?,
      cantidad: (map['cantidad'] as int?) ?? 1,
      dias: (map['dias'] as int?) ?? 1,
      fechaDesde: map['fecha_desde'] == null
          ? null
          : DateTime.parse(map['fecha_desde'] as String),
      fechaHasta: map['fecha_hasta'] == null
          ? null
          : DateTime.parse(map['fecha_hasta'] as String),
      costo: (map['costo'] as num).toDouble(),
      observacion: map['observacion'] as String?,
      nombreEquipo: inventario?['nombre_equipo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final dateFmt = DateFormat('yyyy-MM-dd');
    return {
      'proforma_id': proformaId,
      'numero_activo': numeroActivo,
      'cantidad': cantidad,
      'dias': dias,
      'fecha_desde': fechaDesde != null ? dateFmt.format(fechaDesde!) : null,
      'fecha_hasta': fechaHasta != null ? dateFmt.format(fechaHasta!) : null,
      'costo': costo,
      'observacion': observacion,
    };
  }
}
