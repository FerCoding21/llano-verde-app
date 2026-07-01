import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';
import 'proforma_pdf.dart';

class EmailService {
  static final _apiKey = dotenv.env['RESEND_API_KEY'] ?? '';
  static final _fromEmail = dotenv.env['RESEND_FROM_EMAIL'] ?? '';

  static Future<void> enviarProforma({
    required Proforma proforma,
    required List<ProformaEquipo> equipos,
  }) async {
    if (_apiKey.isEmpty || _fromEmail.isEmpty) {
      throw Exception(
          'RESEND_API_KEY y RESEND_FROM_EMAIL deben estar definidos en .env');
    }

    final pdfBytes = await ProformaPdf.generarBytes(
      proforma: proforma,
      equipos: equipos,
    );

    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': _fromEmail,
        'to': [proforma.correoCliente],
        'subject':
            'Proforma N.° ${proforma.proformaId} - Alquileres de Equipo Llano Verde',
        'html': _construirHtml(proforma, equipos),
        'attachments': [
          {
            'filename':
                'proforma-${proforma.proformaId}-${proforma.nombreCliente}.pdf',
            'content': base64Encode(pdfBytes),
          }
        ],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception('Error al enviar correo: ${body['message'] ?? response.body}');
    }
  }

  static String _construirHtml(
      Proforma proforma, List<ProformaEquipo> equipos) {
    final fmt = NumberFormat('#,##0.00');
    final s = proforma.moneda.simboloPdf;
    final subtotal = equipos.fold(0.0, (sum, e) => sum + e.costo);
    final iva = subtotal * 0.13;
    final total = subtotal + iva;

    final filasTbody = equipos.map((e) => '''
      <tr>
        <td style="padding:8px;border:1px solid #ddd">${e.nombreEquipo ?? 'Equipo #${e.numeroActivo}'}</td>
        <td style="padding:8px;border:1px solid #ddd">${e.observacion ?? ''}</td>
        <td style="padding:8px;border:1px solid #ddd;text-align:right">$s ${fmt.format(e.costo)}</td>
      </tr>''').join();

    return '''
<!DOCTYPE html>
<html>
<body style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:auto;padding:20px">
  <h2 style="color:#1a1a2e">Alquileres de Equipo Llano Verde</h2>
  <p>Estimado/a <strong>${proforma.nombreCliente}</strong>,</p>
  <p>Adjunto encontrará la proforma N.° <strong>${proforma.proformaId}</strong> con el detalle de los equipos solicitados.</p>

  <table style="width:100%;border-collapse:collapse;margin-top:16px">
    <thead>
      <tr style="background:#f0f0f0">
        <th style="padding:8px;border:1px solid #ddd;text-align:left">Equipo</th>
        <th style="padding:8px;border:1px solid #ddd;text-align:left">Observación</th>
        <th style="padding:8px;border:1px solid #ddd;text-align:right">Costo</th>
      </tr>
    </thead>
    <tbody>$filasTbody</tbody>
  </table>

  <table style="width:100%;margin-top:8px">
    <tr><td style="text-align:right">Subtotal:</td><td style="text-align:right;width:120px">$s ${fmt.format(subtotal)}</td></tr>
    <tr><td style="text-align:right">IVA (13%):</td><td style="text-align:right">$s ${fmt.format(iva)}</td></tr>
    <tr><td style="text-align:right"><strong>Total:</strong></td><td style="text-align:right"><strong>$s ${fmt.format(total)}</strong></td></tr>
  </table>

  <p style="margin-top:24px;font-size:13px;color:#666">
    Esta proforma tiene una vigencia de 30 días. Para cualquier consulta puede contactarnos.
  </p>
  <p style="font-size:13px">Atentamente,<br><strong>Alquileres de Equipo Llano Verde</strong></p>
</body>
</html>''';
  }
}
