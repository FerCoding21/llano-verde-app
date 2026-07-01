enum Moneda {
  colon,
  dolar;

  static Moneda fromString(String value) {
    return Moneda.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Moneda invalida: $value'),
    );
  }

  String get simbolo => this == Moneda.colon ? '₡' : '\$';
  String get simboloPdf => this == Moneda.colon ? 'CRC' : 'USD';
  String get etiqueta => this == Moneda.colon ? 'Colones (₡)' : 'Dolares (\$)';
}

class Proforma {
  final int? proformaId;
  final String nombreCliente;
  final String? contacto;
  final String correoCliente;
  final String telefonoCliente;
  final String? informacionDetalle;
  final String? observaciones;
  final Moneda moneda;
  final double transporte;
  final double descuento;
  final DateTime? fechaCreacion;

  const Proforma({
    this.proformaId,
    required this.nombreCliente,
    this.contacto,
    required this.correoCliente,
    required this.telefonoCliente,
    this.informacionDetalle,
    this.observaciones,
    required this.moneda,
    this.transporte = 0,
    this.descuento = 0,
    this.fechaCreacion,
  });

  factory Proforma.fromMap(Map<String, dynamic> map) {
    return Proforma(
      proformaId: map['proforma_id'] as int?,
      nombreCliente: map['nombre_cliente'] as String,
      contacto: map['contacto'] as String?,
      correoCliente: map['correo_cliente'] as String,
      telefonoCliente: map['telefono_cliente'] as String,
      informacionDetalle: map['informacion_detalle'] as String?,
      observaciones: map['observaciones'] as String?,
      moneda: Moneda.fromString(map['moneda'] as String),
      transporte: (map['transporte'] as num?)?.toDouble() ?? 0,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
      fechaCreacion: map['fecha_creacion'] == null
          ? null
          : DateTime.parse(map['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_cliente': nombreCliente,
      'contacto': contacto,
      'correo_cliente': correoCliente,
      'telefono_cliente': telefonoCliente,
      'informacion_detalle': informacionDetalle,
      'observaciones': observaciones,
      'moneda': moneda.name,
      'transporte': transporte,
      'descuento': descuento,
    };
  }

  Proforma copyWith({
    int? proformaId,
    String? nombreCliente,
    String? contacto,
    String? correoCliente,
    String? telefonoCliente,
    String? informacionDetalle,
    String? observaciones,
    Moneda? moneda,
    double? transporte,
    double? descuento,
    DateTime? fechaCreacion,
  }) {
    return Proforma(
      proformaId: proformaId ?? this.proformaId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      contacto: contacto ?? this.contacto,
      correoCliente: correoCliente ?? this.correoCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      informacionDetalle: informacionDetalle ?? this.informacionDetalle,
      observaciones: observaciones ?? this.observaciones,
      moneda: moneda ?? this.moneda,
      transporte: transporte ?? this.transporte,
      descuento: descuento ?? this.descuento,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
