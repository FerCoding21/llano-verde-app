import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EstadoBoleta {
  activa,
  finalizada,
  cancelada;

  static EstadoBoleta fromString(String value) {
    return EstadoBoleta.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Estado invalido: $value'),
    );
  }

  String get etiqueta {
    switch (this) {
      case EstadoBoleta.activa:
        return 'Activa';
      case EstadoBoleta.finalizada:
        return 'Finalizada';
      case EstadoBoleta.cancelada:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case EstadoBoleta.activa:
        return Colors.green;
      case EstadoBoleta.finalizada:
        return Colors.blue;
      case EstadoBoleta.cancelada:
        return Colors.red;
    }
  }
}

class Boleta {
  final int? boletaId;
  final int? proformaId;
  final String nombreEmpresaCliente;
  final String? contacto;
  final String correo;
  final String telefono;
  final String? observaciones;
  final String? facturaUrl;
  final DateTime? fechaCreacion;
  final DateTime fechaInicio;
  final DateTime fechaRetiro;
  final EstadoBoleta estado;

  const Boleta({
    this.boletaId,
    this.proformaId,
    required this.nombreEmpresaCliente,
    this.contacto,
    required this.correo,
    required this.telefono,
    this.observaciones,
    this.facturaUrl,
    this.fechaCreacion,
    required this.fechaInicio,
    required this.fechaRetiro,
    this.estado = EstadoBoleta.activa,
  });

  factory Boleta.fromMap(Map<String, dynamic> map) {
    return Boleta(
      boletaId: map['boleta_id'] as int?,
      proformaId: map['proforma_id'] as int?,
      nombreEmpresaCliente: map['nombre_empresa_cliente'] as String,
      contacto: map['contacto'] as String?,
      correo: map['correo'] as String,
      telefono: map['telefono'] as String,
      observaciones: map['observaciones'] as String?,
      facturaUrl: map['factura_url'] as String?,
      fechaCreacion: map['fecha_creacion'] == null
          ? null
          : DateTime.parse(map['fecha_creacion'] as String),
      fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
      fechaRetiro: DateTime.parse(map['fecha_retiro'] as String),
      estado: EstadoBoleta.fromString(map['estado'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final fmt = DateFormat('yyyy-MM-dd');
    return {
      'proforma_id': proformaId,
      'nombre_empresa_cliente': nombreEmpresaCliente,
      'contacto': contacto,
      'correo': correo,
      'telefono': telefono,
      'observaciones': observaciones,
      'factura_url': facturaUrl,
      'fecha_inicio': fmt.format(fechaInicio),
      'fecha_retiro': fmt.format(fechaRetiro),
      'estado': estado.name,
    };
  }

  Boleta copyWith({
    int? boletaId,
    int? proformaId,
    String? nombreEmpresaCliente,
    String? contacto,
    String? correo,
    String? telefono,
    String? observaciones,
    String? facturaUrl,
    DateTime? fechaCreacion,
    DateTime? fechaInicio,
    DateTime? fechaRetiro,
    EstadoBoleta? estado,
  }) {
    return Boleta(
      boletaId: boletaId ?? this.boletaId,
      proformaId: proformaId ?? this.proformaId,
      nombreEmpresaCliente: nombreEmpresaCliente ?? this.nombreEmpresaCliente,
      contacto: contacto ?? this.contacto,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      observaciones: observaciones ?? this.observaciones,
      facturaUrl: facturaUrl ?? this.facturaUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaRetiro: fechaRetiro ?? this.fechaRetiro,
      estado: estado ?? this.estado,
    );
  }
}
