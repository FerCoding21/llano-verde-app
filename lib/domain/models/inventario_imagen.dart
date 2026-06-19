class InventarioImagen {
  final int? imagenId;
  final int? numeroActivo;
  final String urlImagen;
  final DateTime? fechaSubida;

  const InventarioImagen({
    this.imagenId,
    this.numeroActivo,
    required this.urlImagen,
    this.fechaSubida,
  });

  factory InventarioImagen.fromMap(Map<String, dynamic> map) {
    return InventarioImagen(
      imagenId: map['imagen_id'] as int?,
      numeroActivo: map['numero_activo'] as int?,
      urlImagen: map['url_imagen'] as String,
      fechaSubida: map['fecha_subida'] == null
          ? null
          : DateTime.parse(map['fecha_subida'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero_activo': numeroActivo,
      'url_imagen': urlImagen,
    };
  }
}
