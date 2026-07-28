import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/email_service.dart';
import '../../core/utils/proforma_pdf.dart';
import '../../data/providers/inventario_providers.dart';
import '../../data/providers/proforma_providers.dart';
import '../../domain/models/inventario.dart';
import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';

const _verde = Color(0xFF2E7D32);
const _verdeOscuro = Color(0xFF1B5E20);
const _fondoVerde = Color(0xFFF0F7F0);

class ProformaFormScreen extends ConsumerStatefulWidget {
  const ProformaFormScreen({super.key, this.proformaExistente});

  final Proforma? proformaExistente;

  @override
  ConsumerState<ProformaFormScreen> createState() =>
      _ProformaFormScreenState();
}

class _ProformaFormScreenState
    extends ConsumerState<ProformaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nombreController =
      TextEditingController(text: widget.proformaExistente?.nombreCliente);
  late final _contactoController =
      TextEditingController(text: widget.proformaExistente?.contacto);
  late final _correoController =
      TextEditingController(
          text: widget.proformaExistente?.correoCliente);
  late final _telefonoController =
      TextEditingController(
          text: widget.proformaExistente?.telefonoCliente);
  late final _infoDetalleController = TextEditingController(
      text: widget.proformaExistente?.informacionDetalle);
  late final _observacionesController =
      TextEditingController(
          text: widget.proformaExistente?.observaciones);
  late final _transporteController = TextEditingController(
      text:
          widget.proformaExistente?.transporte.toStringAsFixed(2) ??
              '0.00');
  late final _descuentoController = TextEditingController(
      text:
          widget.proformaExistente?.descuento.toStringAsFixed(2) ??
              '0.00');
  late Moneda _moneda =
      widget.proformaExistente?.moneda ?? Moneda.colon;

  Proforma? _proformaGuardada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _proformaGuardada = widget.proformaExistente;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _infoDetalleController.dispose();
    _observacionesController.dispose();
    _transporteController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final repository = ref.read(proformaRepositoryProvider);
      final proforma = Proforma(
        proformaId: _proformaGuardada?.proformaId,
        nombreCliente: _nombreController.text.trim(),
        contacto: _contactoController.text.trim().isEmpty
            ? null
            : _contactoController.text.trim(),
        correoCliente: _correoController.text.trim(),
        telefonoCliente: _telefonoController.text.trim(),
        informacionDetalle: _infoDetalleController.text.trim().isEmpty
            ? null
            : _infoDetalleController.text.trim(),
        observaciones:
            _observacionesController.text.trim().isEmpty
                ? null
                : _observacionesController.text.trim(),
        moneda: _moneda,
        transporte: double.tryParse(
                _transporteController.text.trim().replaceAll(',', '.')) ??
            0,
        descuento: double.tryParse(
                _descuentoController.text.trim().replaceAll(',', '.')) ??
            0,
      );
      final resultado = proforma.proformaId == null
          ? await repository.create(proforma)
          : await repository.update(proforma);
      ref.invalidate(proformaListProvider);
      setState(() => _proformaGuardada = resultado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proforma guardada')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _generarPdf() async {
    final equipos = await ref
        .read(proformaRepositoryProvider)
        .getEquipos(_proformaGuardada!.proformaId!);
    await ProformaPdf.mostrar(
        proforma: _proformaGuardada!, equipos: equipos);
  }

  Future<void> _enviarCorreo() async {
    final equipos = await ref
        .read(proformaRepositoryProvider)
        .getEquipos(_proformaGuardada!.proformaId!);
    try {
      await EmailService.enviarProforma(
          proforma: _proformaGuardada!, equipos: equipos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Proforma enviada a ${_proformaGuardada!.correoCliente}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = _proformaGuardada?.proformaId == null;
    final guardada = _proformaGuardada?.proformaId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esNueva ? 'Nueva proforma' : 'Editar proforma'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Cliente ──────────────────────────────────────────────
            _Seccion(
              titulo: 'Datos del cliente',
              children: [
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Cliente / Empresa',
                    prefixIcon: Icon(Icons.business_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Contacto (opcional)',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _infoDetalleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Detalle / proyecto (opcional)',
                    prefixIcon: Icon(Icons.work_outline, size: 20),
                  ),
                ),
              ],
            ),

            // ── Condiciones ──────────────────────────────────────────
            _Seccion(
              titulo: 'Condiciones',
              children: [
                DropdownButtonFormField<Moneda>(
                  initialValue: _moneda,
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                    prefixIcon:
                        Icon(Icons.monetization_on_outlined, size: 20),
                  ),
                  items: Moneda.values
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(m.etiqueta)))
                      .toList(),
                  onChanged: (v) => setState(() => _moneda = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _transporteController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Transporte',
                          prefixIcon:
                              Icon(Icons.local_shipping_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _descuentoController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Descuento',
                          prefixIcon: Icon(Icons.discount_outlined, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),

            // ── Botones ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _verdeOscuro,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Guardar proforma',
                        style: TextStyle(fontSize: 15)),
              ),
            ),
            if (guardada) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          size: 18),
                      label: const Text('PDF'),
                      onPressed: _generarPdf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _verde,
                        side: const BorderSide(color: _verde),
                        minimumSize: const Size(0, 46),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Enviar'),
                      onPressed: _enviarCorreo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _verde,
                        side: const BorderSide(color: _verde),
                        minimumSize: const Size(0, 46),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── Equipos ──────────────────────────────────────────────
            if (esNueva)
              _AvisionGuardar()
            else
              _SeccionEquipos(proforma: _proformaGuardada!),
          ],
        ),
      ),
    );
  }
}

// ── Aviso "guarda primero" ────────────────────────────────────────────────────

class _AvisionGuardar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF9E9E9E), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Guarda la proforma primero para poder agregar equipos.',
              style: TextStyle(color: Color(0xFF757575), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección de equipos ────────────────────────────────────────────────────────

class _SeccionEquipos extends ConsumerWidget {
  const _SeccionEquipos({required this.proforma});

  final Proforma proforma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equiposAsync =
        ref.watch(proformaEquiposProvider(proforma.proformaId!));
    final fmt = NumberFormat('#,##0.00');
    final s = proforma.moneda.simbolo;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la sección
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Equipos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A)),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: TextButton.styleFrom(foregroundColor: _verde),
                  onPressed: () => _mostrarDialogo(context, ref),
                ),
              ],
            ),
          ),

          equiposAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin equipos agregados.',
                      style: TextStyle(color: Color(0xFF9E9E9E))),
                );
              }
              final subtotal =
                  items.fold(0.0, (sum, e) => sum + e.total);
              final base = subtotal + proforma.transporte;
              final iva = base * 0.13;
              final total = base + iva - proforma.descuento;

              return Column(
                children: [
                  ...items.map((item) => _ItemEquipo(
                        nombre: item.nombreEquipo ??
                            'Equipo #${item.numeroActivo}',
                        detalle:
                            'Cant: ${item.cantidad}  ·  ${item.dias} días'
                            '${item.observacion != null ? '  ·  ${item.observacion}' : ''}',
                        total: '$s ${fmt.format(item.total)}',
                        onEliminar: () =>
                            _eliminar(context, ref, item),
                      )),
                  // Resumen de totales
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _fondoVerde,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _FilaTotal('Subtotal', '$s ${fmt.format(subtotal)}'),
                        _FilaTotal('Transporte',
                            '$s ${fmt.format(proforma.transporte)}'),
                        _FilaTotal('IVA (13%)', '$s ${fmt.format(iva)}'),
                        _FilaTotal('Descuento',
                            '- $s ${fmt.format(proforma.descuento)}'),
                        const Divider(height: 16),
                        _FilaTotal('Total', '$s ${fmt.format(total)}',
                            negrita: true, grande: true),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogo(BuildContext context, WidgetRef ref) async {
    final resultado = await showDialog<ProformaEquipo>(
      context: context,
      builder: (_) => _DialogoEquipo(proforma: proforma),
    );
    if (resultado == null) return;
    try {
      await ref.read(proformaRepositoryProvider).addEquipo(resultado);
      ref.invalidate(proformaEquiposProvider(proforma.proformaId!));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar equipo: $e')));
      }
    }
  }

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, ProformaEquipo item) async {
    try {
      await ref
          .read(proformaRepositoryProvider)
          .deleteEquipo(item.proformaEquipoId!);
      ref.invalidate(proformaEquiposProvider(proforma.proformaId!));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}

// ── Diálogo agregar equipo ────────────────────────────────────────────────────

class _DialogoEquipo extends ConsumerStatefulWidget {
  const _DialogoEquipo({required this.proforma});

  final Proforma proforma;

  @override
  ConsumerState<_DialogoEquipo> createState() => _DialogoEquipoState();
}

class _DialogoEquipoState extends ConsumerState<_DialogoEquipo> {
  final _formKey = GlobalKey<FormState>();
  Inventario? _equipoSeleccionado;
  final _cantidadController = TextEditingController(text: '1');
  final _diasController = TextEditingController(text: '1');
  final _costoController = TextEditingController();
  final _observacionController = TextEditingController();
  DateTime? _fechaEntrega;
  final _dateFmt = DateFormat('d/M/yyyy');

  @override
  void dispose() {
    _cantidadController.dispose();
    _diasController.dispose();
    _costoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaEntrega() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() => _fechaEntrega = picked);
  }

  @override
  Widget build(BuildContext context) {
    final inventarioAsync = ref.watch(inventarioListProvider);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Agregar equipo',
          style: TextStyle(fontWeight: FontWeight.w700)),
      contentPadding:
          const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                inventarioAsync.when(
                  data: (equipos) =>
                      DropdownButtonFormField<Inventario>(
                    initialValue: _equipoSeleccionado,
                    hint: const Text('Selecciona un equipo'),
                    decoration: const InputDecoration(
                        labelText: 'Equipo'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.nombreEquipo)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _equipoSeleccionado = v),
                    validator: (v) =>
                        v == null ? 'Selecciona un equipo' : null,
                  ),
                  loading: () =>
                      const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Cantidad'),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null)
                                ? 'Inválido'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _diasController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Días'),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null)
                                ? 'Inválido'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _seleccionarFechaEntrega,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Fecha de entrega (opcional)'),
                    child: Text(_fechaEntrega != null
                        ? _dateFmt.format(_fechaEntrega!)
                        : '—'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                      labelText:
                          'Precio unitario (${widget.proforma.moneda.simbolo})'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v.replaceAll(',', '.')) ==
                        null) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionController,
                  decoration: const InputDecoration(
                      labelText: 'Observación (opcional)'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _verde),
          onPressed: _confirmar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final dias = int.parse(_diasController.text.trim());
    final fechaHasta = _fechaEntrega?.add(Duration(days: dias));
    Navigator.of(context).pop(
      ProformaEquipo(
        proformaId: widget.proforma.proformaId,
        numeroActivo: _equipoSeleccionado!.numeroActivo,
        cantidad: int.parse(_cantidadController.text.trim()),
        dias: dias,
        fechaDesde: _fechaEntrega,
        fechaHasta: fechaHasta,
        costo: double.parse(
            _costoController.text.trim().replaceAll(',', '.')),
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        nombreEquipo: _equipoSeleccionado!.nombreEquipo,
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ItemEquipo extends StatelessWidget {
  const _ItemEquipo({
    required this.nombre,
    required this.detalle,
    required this.total,
    required this.onEliminar,
  });

  final String nombre;
  final String detalle;
  final String total;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          const Icon(Icons.construction_outlined,
              size: 18, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(detalle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Text(total,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.red),
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal(this.label, this.valor,
      {this.negrita = false, this.grande = false});

  final String label;
  final String valor;
  final bool negrita;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: negrita ? FontWeight.w700 : FontWeight.w400,
      fontSize: grande ? 15 : 13,
      color: grande
          ? const Color(0xFF1B5E20)
          : const Color(0xFF424242),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(valor, style: style),
        ],
      ),
    );
  }
}
