import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';

// Colores de marca
const _verde = PdfColor.fromInt(0xFF4CAF50);
const _grisOscuro = PdfColor.fromInt(0xFF2D2D2D);
const _grisClaro = PdfColor.fromInt(0xFFF5F5F5);
const _grisBorde = PdfColor.fromInt(0xFFCCCCCC);

// Clausulas fijas que aparecen en todas las proformas
const _clausulas = [
  'Los contratos iniciales no tienen nota de credito.',
  'La forma de pago es via transferencia o deposito.',
  'Aplica deposito de Garantia segun corresponda.',
  'Se formaliza el Servicio Previa Orden de Compra.',
  'Previa revision al devolver el bien, todo dano provocado al bien sera cubierto por el cliente en su totalidad.',
];

class ProformaPdf {
  static Future<void> mostrar({
    required Proforma proforma,
    required List<ProformaEquipo> equipos,
  }) async {
    final doc = await _generar(proforma, equipos);
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Proforma-${proforma.proformaId}-${proforma.nombreCliente}',
    );
  }

  static Future<List<int>> generarBytes({
    required Proforma proforma,
    required List<ProformaEquipo> equipos,
  }) async {
    final doc = await _generar(proforma, equipos);
    return doc.save();
  }

  static Future<pw.Document> _generar(
    Proforma proforma,
    List<ProformaEquipo> equipos,
  ) async {
    final logoData = await rootBundle.load('docs/logo llano verde.jpeg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d/M/yyyy');
    final s = proforma.moneda.simboloPdf;
    final fecha = proforma.fechaCreacion != null
        ? dateFmt.format(proforma.fechaCreacion!)
        : dateFmt.format(DateTime.now());

    final subtotal =
        equipos.fold(0.0, (sum, e) => sum + e.total);
    final base = subtotal + proforma.transporte;
    final iva = base * 0.13;
    final total = base + iva - proforma.descuento;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _encabezado(logoImage, proforma, fecha),
            pw.SizedBox(height: 14),
            _seccionCliente(proforma),
            pw.SizedBox(height: 14),
            _tablaEquipos(equipos, fmt, dateFmt, s),
            pw.SizedBox(height: 16),
            _seccionInferior(
              proforma: proforma,
              fmt: fmt,
              s: s,
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

  // ── Encabezado ─────────────────────────────────────────────────────────────

  static pw.Widget _encabezado(
    pw.MemoryImage logo,
    Proforma proforma,
    String fecha,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo
        pw.Image(logo, width: 90, height: 90),
        pw.SizedBox(width: 16),
        // Datos de la empresa
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
        // N° y fecha
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _verde,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('PROFORMA',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
            ),
            pw.SizedBox(height: 6),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: 'N°  ',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(
                    text: '${proforma.proformaId}',
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
                    text: fecha,
                    style: const pw.TextStyle(fontSize: 10)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ── Sección cliente ─────────────────────────────────────────────────────────

  static pw.Widget _seccionCliente(Proforma proforma) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisBorde),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _filaCliente('CLIENTE', proforma.nombreCliente, negrita: true),
          if (proforma.contacto != null && proforma.contacto!.isNotEmpty)
            _filaCliente('CONTACTO', proforma.contacto!),
          _filaCliente('Telefono', proforma.telefonoCliente),
          _filaCliente('Correo', proforma.correoCliente),
          if (proforma.informacionDetalle != null &&
              proforma.informacionDetalle!.isNotEmpty)
            _filaCliente('Info / detalle', proforma.informacionDetalle!),
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
                  fontWeight:
                      negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ]),
    );
  }

  // ── Tabla de equipos ────────────────────────────────────────────────────────

  static pw.Widget _tablaEquipos(
    List<ProformaEquipo> equipos,
    NumberFormat fmt,
    DateFormat dateFmt,
    String s,
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
            child: pw.Text('PROFORMA DE ALQUILER DE EQUIPO',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11)),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: _grisBorde),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FixedColumnWidth(30),
            2: const pw.FixedColumnWidth(30),
            3: const pw.FixedColumnWidth(52),
            4: const pw.FixedColumnWidth(52),
            5: const pw.FixedColumnWidth(60),
            6: const pw.FixedColumnWidth(60),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _grisClaro),
              children: [
                _th('DESCRIPCION DEL ARTICULO'),
                _th('Cant'),
                _th('Dias'),
                _th('Desde'),
                _th('Hasta'),
                _th('Precio', align: pw.TextAlign.right),
                _th('Total', align: pw.TextAlign.right),
              ],
            ),
            ...equipos.map((e) => pw.TableRow(
                  children: [
                    _td(e.nombreEquipo ?? 'Equipo #${e.numeroActivo}'),
                    _td('${e.cantidad}', align: pw.TextAlign.center),
                    _td('${e.dias}', align: pw.TextAlign.center),
                    _td(e.fechaDesde != null ? dateFmt.format(e.fechaDesde!) : '',
                        align: pw.TextAlign.center),
                    _td(e.fechaHasta != null ? dateFmt.format(e.fechaHasta!) : '',
                        align: pw.TextAlign.center),
                    _td('$s ${fmt.format(e.costo)}',
                        align: pw.TextAlign.right),
                    _td('$s ${fmt.format(e.total)}',
                        align: pw.TextAlign.right),
                  ],
                )),
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
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
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
    required Proforma proforma,
    required NumberFormat fmt,
    required String s,
    required double subtotal,
    required double iva,
    required double total,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna izquierda: info relacionada + clausulas
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (proforma.observaciones != null &&
                  proforma.observaciones!.isNotEmpty) ...[
                pw.Text('Informacion Relacionada:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 4),
                pw.Text(proforma.observaciones!,
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
        // Columna derecha: totales
        pw.SizedBox(
          width: 180,
          child: pw.Table(
            border: pw.TableBorder.all(color: _grisBorde),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _filaTotal('Sub total:', '$s ${fmt.format(subtotal)}'),
              _filaTotal('Transporte:',
                  '$s ${fmt.format(proforma.transporte)}'),
              _filaTotal(
                  'Impuesto de ventas:', '$s ${fmt.format(iva)}'),
              _filaTotal('Descuento: Tarifa especial',
                  '$s ${fmt.format(proforma.descuento)}'),
              _filaTotalNegrita('Total:', '$s ${fmt.format(total)}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _filaTotal(String label, String valor) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(label,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(valor,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }
}
