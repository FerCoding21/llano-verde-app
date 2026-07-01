class BoletaImagen {
  final int? imagenId;
  final int? boletaId;
  final String urlImagen;
  final DateTime? fechaSubida;

  const BoletaImagen({
    this.imagenId,
    this.boletaId,
    required this.urlImagen,
    this.fechaSubida,
  });

  factory BoletaImagen.fromMap(Map<String, dynamic> map) {
    return BoletaImagen(
      imagenId: map['imagen_id'] as int?,
      boletaId: map['boleta_id'] as int?,
      urlImagen: map['url_imagen'] as String,
      fechaSubida: map['fecha_subida'] == null
          ? null
          : DateTime.parse(map['fecha_subida'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'boleta_id': boletaId,
      'url_imagen': urlImagen,
    };
  }
}
