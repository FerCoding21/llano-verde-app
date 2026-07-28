enum EstadoInventario {
  disponible,
  alquilado,
  mantenimiento;

  static EstadoInventario fromString(String value) {
    return EstadoInventario.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Estado de inventario inválido: $value'),
    );
  }
}

class Inventario {
  final int? numeroActivo;
  final String nombreEquipo;
  final String descripcion;
  final EstadoInventario estado;
  final String? fotoPortada;

  const Inventario({
    this.numeroActivo,
    required this.nombreEquipo,
    required this.descripcion,
    required this.estado,
    this.fotoPortada,
  });

  factory Inventario.fromMap(Map<String, dynamic> map) {
    return Inventario(
      numeroActivo: map['numero_activo'] as int?,
      nombreEquipo: map['nombre_equipo'] as String,
      descripcion: map['descripcion'] as String,
      estado: EstadoInventario.fromString(map['estado'] as String),
      fotoPortada: map['foto_portada'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_equipo': nombreEquipo,
      'descripcion': descripcion,
      'estado': estado.name,
      // foto_portada se actualiza aparte con setFotoPortada()
    };
  }

  Inventario copyWith({
    int? numeroActivo,
    String? nombreEquipo,
    String? descripcion,
    EstadoInventario? estado,
    String? fotoPortada,
  }) {
    return Inventario(
      numeroActivo: numeroActivo ?? this.numeroActivo,
      nombreEquipo: nombreEquipo ?? this.nombreEquipo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fotoPortada: fotoPortada ?? this.fotoPortada,
    );
  }
}
