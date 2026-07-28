import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';
import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';
import 'boleta_pdf.dart';
import 'proforma_pdf.dart';

class EmailService {
  static final _apiKey = dotenv.env['RESEND_API_KEY'] ?? '';
  static final _fromEmail = dotenv.env['RESEND_FROM_EMAIL'] ?? '';

  // ── Proforma ────────────────────────────────────────────────────────────────

  static Future<void> enviarProforma({
    required Proforma proforma,
    required List<ProformaEquipo> equipos,
  }) async {
    _validarCredenciales();
    final pdfBytes =
        await ProformaPdf.generarBytes(proforma: proforma, equipos: equipos);

    await _enviar(
      destinatario: proforma.correoCliente,
      asunto:
          'Proforma N. ${proforma.proformaId} - Alquileres de Equipo Llano Verde',
      html: _htmlProforma(proforma, equipos),
      nombreArchivo:
          'proforma-${proforma.proformaId}-${proforma.nombreCliente}.pdf',
      pdfBytes: pdfBytes,
    );
  }

  // ── Boleta ──────────────────────────────────────────────────────────────────

  static Future<void> enviarBoleta({
    required Boleta boleta,
    required List<BoletaEquipo> equipos,
  }) async {
    _validarCredenciales();
    final pdfBytes =
        await BoletaPdf.generarBytes(boleta: boleta, equipos: equipos);

    await _enviar(
      destinatario: boleta.correo,
      asunto:
          'Boleta N. ${boleta.boletaId} - Alquileres de Equipo Llano Verde',
      html: _htmlBoleta(boleta, equipos),
      nombreArchivo:
          'boleta-${boleta.boletaId}-${boleta.nombreEmpresaCliente}.pdf',
      pdfBytes: pdfBytes,
    );
  }

  // ── Privados ────────────────────────────────────────────────────────────────

  static void _validarCredenciales() {
    if (_apiKey.isEmpty || _fromEmail.isEmpty) {
      throw Exception(
          'RESEND_API_KEY y RESEND_FROM_EMAIL deben estar definidos en .env');
    }
  }

  static Future<void> _enviar({
    required String destinatario,
    required String asunto,
    required String html,
    required String nombreArchivo,
    required List<int> pdfBytes,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': _fromEmail,
        'to': [destinatario],
        'subject': asunto,
        'html': html,
        'attachments': [
          {
            'filename': nombreArchivo,
            'content': base64Encode(pdfBytes),
          }
        ],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(
          'Error al enviar correo: ${body['message'] ?? response.body}');
    }
  }

  static String _htmlProforma(
      Proforma proforma, List<ProformaEquipo> equipos) {
    final fmt = NumberFormat('#,##0.00');
    final s = proforma.moneda.simboloPdf;
    final subtotal = equipos.fold(0.0, (sum, e) => sum + e.total);
    final base = subtotal + proforma.transporte;
    final iva = base * 0.13;
    final total = base + iva - proforma.descuento;

    final filas = equipos.map((e) => '''
      <tr>
        <td style="padding:8px;border:1px solid #ddd">${e.nombreEquipo ?? 'Equipo #${e.numeroActivo}'}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:center">${e.cantidad}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:center">${e.dias}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:right">$s ${fmt.format(e.costo)}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:right">$s ${fmt.format(e.total)}</td>
      </tr>''').join();

    return '''<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:auto;padding:20px">
  <h2 style="color:#4CAF50">Alquileres de Equipo Llano Verde</h2>
  <p>Estimado/a <strong>${proforma.nombreCliente}</strong>,</p>
  <p>Adjunto encontrara la proforma N. <strong>${proforma.proformaId}</strong> con el detalle de los equipos solicitados.</p>
  <table style="width:100%;border-collapse:collapse;margin-top:16px">
    <thead><tr style="background:#f0f0f0">
      <th style="padding:8px;border:1px solid #ddd;text-align:left">Equipo</th>
      <th style="padding:8px;border:1px solid #ddd">Cant</th>
      <th style="padding:8px;border:1px solid #ddd">Dias</th>
      <th style="padding:8px;border:1px solid #ddd;text-align:right">Precio</th>
      <th style="padding:8px;border:1px solid #ddd;text-align:right">Total</th>
    </tr></thead>
    <tbody>$filas</tbody>
  </table>
  <table style="width:100%;margin-top:8px">
    <tr><td style="text-align:right">Subtotal:</td><td style="text-align:right;width:120px">$s ${fmt.format(subtotal)}</td></tr>
    <tr><td style="text-align:right">Transporte:</td><td style="text-align:right">$s ${fmt.format(proforma.transporte)}</td></tr>
    <tr><td style="text-align:right">IVA (13%):</td><td style="text-align:right">$s ${fmt.format(iva)}</td></tr>
    <tr><td style="text-align:right">Descuento:</td><td style="text-align:right">$s ${fmt.format(proforma.descuento)}</td></tr>
    <tr><td style="text-align:right"><strong>Total:</strong></td><td style="text-align:right"><strong>$s ${fmt.format(total)}</strong></td></tr>
  </table>
  <p style="margin-top:24px;font-size:13px;color:#666">Esta proforma tiene una vigencia de 30 dias.</p>
  <p style="font-size:13px">Atentamente,<br><strong>Alquileres de Equipo Llano Verde</strong></p>
</body></html>''';
  }

  static String _htmlBoleta(Boleta boleta, List<BoletaEquipo> equipos) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d/M/yyyy');
    final subtotal = equipos.fold(0.0, (sum, e) => sum + e.total);
    final base = subtotal + boleta.transporte;
    final iva = base * 0.13;
    final total = base + iva - boleta.descuento;

    final filas = equipos.map((e) => '''
      <tr>
        <td style="padding:8px;border:1px solid #ddd">${e.nombreEquipo ?? 'Equipo #${e.numeroActivo}'}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:center">${e.cantidad}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:center">${e.dias}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:right">${fmt.format(e.precioFinal)}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:right">${fmt.format(e.total)}</td>
      </tr>''').join();

    return '''<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:auto;padding:20px">
  <h2 style="color:#4CAF50">Alquileres de Equipo Llano Verde</h2>
  <p>Estimado/a <strong>${boleta.nombreEmpresaCliente}</strong>,</p>
  <p>Adjunto encontrara la boleta N. <strong>${boleta.boletaId}</strong> correspondiente al alquiler del periodo
     <strong>${dateFmt.format(boleta.fechaInicio)} - ${dateFmt.format(boleta.fechaRetiro)}</strong>.</p>
  <table style="width:100%;border-collapse:collapse;margin-top:16px">
    <thead><tr style="background:#f0f0f0">
      <th style="padding:8px;border:1px solid #ddd;text-align:left">Equipo</th>
      <th style="padding:8px;border:1px solid #ddd">Cant</th>
      <th style="padding:8px;border:1px solid #ddd">Dias</th>
      <th style="padding:8px;border:1px solid #ddd;text-align:right">Precio</th>
      <th style="padding:8px;border:1px solid #ddd;text-align:right">Total</th>
    </tr></thead>
    <tbody>$filas</tbody>
  </table>
  <table style="width:100%;margin-top:8px">
    <tr><td style="text-align:right">Subtotal:</td><td style="text-align:right;width:120px">${fmt.format(subtotal)}</td></tr>
    <tr><td style="text-align:right">Transporte:</td><td style="text-align:right">${fmt.format(boleta.transporte)}</td></tr>
    <tr><td style="text-align:right">IVA (13%):</td><td style="text-align:right">${fmt.format(iva)}</td></tr>
    <tr><td style="text-align:right">Descuento:</td><td style="text-align:right">${fmt.format(boleta.descuento)}</td></tr>
    <tr><td style="text-align:right"><strong>Total:</strong></td><td style="text-align:right"><strong>${fmt.format(total)}</strong></td></tr>
  </table>
  <p style="font-size:13px">Atentamente,<br><strong>Alquileres de Equipo Llano Verde</strong></p>
</body></html>''';
  }
}
