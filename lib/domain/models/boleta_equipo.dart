class BoletaEquipo {
  final int? boletaEquipoId;
  final int? boletaId;
  final int? numeroActivo;
  final double precioFinal;
  final String? observacionEquipo;
  final int cantidad;
  final int dias;
  final String? nombreEquipo;

  const BoletaEquipo({
    this.boletaEquipoId,
    this.boletaId,
    this.numeroActivo,
    required this.precioFinal,
    this.observacionEquipo,
    this.cantidad = 1,
    this.dias = 1,
    this.nombreEquipo,
  });

  double get total => precioFinal * cantidad;

  factory BoletaEquipo.fromMap(Map<String, dynamic> map) {
    final inventario = map['inventario'] as Map<String, dynamic>?;
    return BoletaEquipo(
      boletaEquipoId: map['boleta_equipo_id'] as int?,
      boletaId: map['boleta_id'] as int?,
      numeroActivo: map['numero_activo'] as int?,
      precioFinal: (map['precio_final'] as num).toDouble(),
      observacionEquipo: map['observacion_equipo'] as String?,
      cantidad: (map['cantidad'] as int?) ?? 1,
      dias: (map['dias'] as int?) ?? 1,
      nombreEquipo: inventario?['nombre_equipo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'boleta_id': boletaId,
      'numero_activo': numeroActivo,
      'precio_final': precioFinal,
      'observacion_equipo': observacionEquipo,
      'cantidad': cantidad,
      'dias': dias,
    };
  }
}
