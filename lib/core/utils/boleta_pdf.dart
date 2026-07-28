import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';

const _verde = PdfColor.fromInt(0xFF4CAF50);
const _grisOscuro = PdfColor.fromInt(0xFF2D2D2D);
const _grisClaro = PdfColor.fromInt(0xFFF5F5F5);
const _grisBorde = PdfColor.fromInt(0xFFCCCCCC);

const _clausulas = [
  'Los contratos iniciales no tienen nota de credito.',
  'La forma de pago es via transferencia o deposito.',
  'Aplica deposito de Garantia segun corresponda.',
  'Se formaliza el Servicio Previa Orden de Compra.',
  'Previa revision al devolver el bien, todo dano provocado al bien sera cubierto por el cliente en su totalidad.',
];

class BoletaPdf {
  static Future<void> mostrar({
    required Boleta boleta,
    required List<BoletaEquipo> equipos,
  }) async {
    final doc = await _generar(boleta, equipos);
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Boleta-${boleta.boletaId}-${boleta.nombreEmpresaCliente}',
    );
  }

  static Future<List<int>> generarBytes({
    required Boleta boleta,
    required List<BoletaEquipo> equipos,
  }) async {
    final doc = await _generar(boleta, equipos);
    return doc.save();
  }

  static Future<pw.Document> _generar(
    Boleta boleta,
    List<BoletaEquipo> equipos,
  ) async {
    final logoData = await rootBundle.load('docs/logo llano verde.jpeg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Descargar fotos principales de equipos
    final Map<String, pw.MemoryImage> fotos = {};
    for (final e in equipos) {
      if (e.fotoPortada != null && !fotos.containsKey(e.fotoPortada)) {
        try {
          final resp = await http.get(Uri.parse(e.fotoPortada!));
          if (resp.statusCode == 200) {
            fotos[e.fotoPortada!] = pw.MemoryImage(resp.bodyBytes);
          }
        } catch (_) {}
      }
    }

    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d/M/yyyy');

    final subtotal = equipos.fold(0.0, (sum, e) => sum + e.total);
    final base = subtotal + boleta.transporte;
    final iva = base * 0.13;
    final total = base + iva - boleta.descuento;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _encabezado(logoImage, boleta, dateFmt),
            pw.SizedBox(height: 14),
            _seccionCliente(boleta, dateFmt),
            pw.SizedBox(height: 14),
            _tablaEquipos(equipos, fotos, fmt),
            pw.SizedBox(height: 16),
            _seccionInferior(
              boleta: boleta,
              fmt: fmt,
              subtotal: subtotal,
              iva: iva,
              total: total,
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ── Encabezado ──────────────────────────────────────────────────────────────

  static pw.Widget _encabezado(
    pw.MemoryImage logo,
    Boleta boleta,
    DateFormat dateFmt,
  ) {
    final fechaCreacion = boleta.fechaCreacion != null
        ? dateFmt.format(boleta.fechaCreacion!)
        : dateFmt.format(DateTime.now());

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(logo, width: 90, height: 90),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('TELEFONOS: 8886-3434 / 8875-3000',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('WhatsApp: 8837-3434',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('ventas@syesolucionessrl.com',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.blue)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _verde,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('BOLETA',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
            ),
            pw.SizedBox(height: 6),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: 'N  ',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(
                    text: '${boleta.boletaId}',
                    style: const pw.TextStyle(fontSize: 10)),
              ]),
            ),
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: 'Fecha:  ',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(
                    text: fechaCreacion,
                    style: const pw.TextStyle(fontSize: 10)),
              ]),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: _grisClaro,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(boleta.estado.name.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Sección cliente ─────────────────────────────────────────────────────────

  static pw.Widget _seccionCliente(Boleta boleta, DateFormat dateFmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisBorde),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _filaCliente('CLIENTE', boleta.nombreEmpresaCliente,
              negrita: true),
          if (boleta.contacto != null && boleta.contacto!.isNotEmpty)
            _filaCliente('CONTACTO', boleta.contacto!),
          _filaCliente('Telefono', boleta.telefono),
          _filaCliente('Correo', boleta.correo),
          _filaCliente('Periodo',
              '${dateFmt.format(boleta.fechaInicio)} - ${dateFmt.format(boleta.fechaRetiro)}'),
          if (boleta.ordenCompra != null && boleta.ordenCompra!.isNotEmpty)
            _filaCliente('Orden de compra', boleta.ordenCompra!),
          if (boleta.facturaUrl != null && boleta.facturaUrl!.isNotEmpty)
            _filaCliente('Factura', boleta.facturaUrl!),
        ],
      ),
    );
  }

  static pw.Widget _filaCliente(String label, String valor,
      {bool negrita = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text('$label:',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Expanded(
          child: pw.Text(valor,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: negrita
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal)),
        ),
      ]),
    );
  }

  // ── Tabla de equipos ────────────────────────────────────────────────────────

  static pw.Widget _tablaEquipos(
    List<BoletaEquipo> equipos,
    Map<String, pw.MemoryImage> fotos,
    NumberFormat fmt,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            color: _grisOscuro,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          child: pw.Center(
            child: pw.Text('BOLETA DE ALQUILER DE EQUIPO',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11)),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: _grisBorde),
          columnWidths: {
            0: const pw.FixedColumnWidth(46),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FixedColumnWidth(36),
            3: const pw.FixedColumnWidth(36),
            4: const pw.FixedColumnWidth(70),
            5: const pw.FixedColumnWidth(70),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _grisClaro),
              children: [
                _th(''),
                _th('DESCRIPCION DEL ARTICULO'),
                _th('Cant'),
                _th('Dias'),
                _th('Precio', align: pw.TextAlign.right),
                _th('Total', align: pw.TextAlign.right),
              ],
            ),
            ...equipos.map((e) {
              final foto = e.fotoPortada != null ? fotos[e.fotoPortada] : null;
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: foto != null
                        ? pw.Image(foto,
                            width: 40, height: 40, fit: pw.BoxFit.cover)
                        : pw.SizedBox(width: 40, height: 40),
                  ),
                  _td(e.nombreEquipo ?? 'Equipo #${e.numeroActivo}'),
                  _td('${e.cantidad}', align: pw.TextAlign.center),
                  _td('${e.dias}', align: pw.TextAlign.center),
                  _td(fmt.format(e.precioFinal), align: pw.TextAlign.right),
                  _td(fmt.format(e.total), align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _th(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text,
          style:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          textAlign: align),
    );
  }

  static pw.Widget _td(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }

  // ── Sección inferior ────────────────────────────────────────────────────────

  static pw.Widget _seccionInferior({
    required Boleta boleta,
    required NumberFormat fmt,
    required double subtotal,
    required double iva,
    required double total,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (boleta.observaciones != null &&
                  boleta.observaciones!.isNotEmpty) ...[
                pw.Text('Observaciones:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 4),
                pw.Text(boleta.observaciones!,
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 10),
              ],
              pw.Text('Clausulas Contractuales:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 4),
              ..._clausulas.map((c) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text('* $c',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                  )),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.SizedBox(
          width: 180,
          child: pw.Table(
            border: pw.TableBorder.all(color: _grisBorde),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _filaTotal('Sub total:', fmt.format(subtotal)),
              _filaTotal('Transporte:', fmt.format(boleta.transporte)),
              _filaTotal('Impuesto de ventas:', fmt.format(iva)),
              _filaTotal(
                  'Descuento:', fmt.format(boleta.descuento)),
              _filaTotalNegrita('Total:', fmt.format(total)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _filaTotal(String label, String valor) {
    return pw.TableRow(children: [
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ),
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(valor,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right),
      ),
    ]);
  }

  static pw.TableRow _filaTotalNegrita(String label, String valor) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _grisClaro),
      children: [
        pw.Padding(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(valor,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }
}
