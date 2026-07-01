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

class ProformaFormScreen extends ConsumerStatefulWidget {
  const ProformaFormScreen({super.key, this.proformaExistente});

  final Proforma? proformaExistente;

  @override
  ConsumerState<ProformaFormScreen> createState() => _ProformaFormScreenState();
}

class _ProformaFormScreenState extends ConsumerState<ProformaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nombreController =
      TextEditingController(text: widget.proformaExistente?.nombreCliente);
  late final _contactoController =
      TextEditingController(text: widget.proformaExistente?.contacto);
  late final _correoController =
      TextEditingController(text: widget.proformaExistente?.correoCliente);
  late final _telefonoController =
      TextEditingController(text: widget.proformaExistente?.telefonoCliente);
  late final _infoDetalleController = TextEditingController(
      text: widget.proformaExistente?.informacionDetalle);
  late final _observacionesController =
      TextEditingController(text: widget.proformaExistente?.observaciones);
  late final _transporteController = TextEditingController(
      text: widget.proformaExistente?.transporte.toStringAsFixed(2) ?? '0.00');
  late final _descuentoController = TextEditingController(
      text: widget.proformaExistente?.descuento.toStringAsFixed(2) ?? '0.00');
  late Moneda _moneda = widget.proformaExistente?.moneda ?? Moneda.colon;

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
        observaciones: _observacionesController.text.trim().isEmpty
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Proforma guardada')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _generarPdf() async {
    final equipos = await ref
        .read(proformaRepositoryProvider)
        .getEquipos(_proformaGuardada!.proformaId!);
    await ProformaPdf.mostrar(proforma: _proformaGuardada!, equipos: equipos);
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

    return Scaffold(
      appBar: AppBar(
          title: Text(esNueva ? 'Nueva proforma' : 'Editar proforma')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos del cliente',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration:
                    const InputDecoration(labelText: 'Cliente / Empresa'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactoController,
                decoration:
                    const InputDecoration(labelText: 'Contacto (opcional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _infoDetalleController,
                decoration: const InputDecoration(
                    labelText: 'Info / detalle (ej: Proyecto X)'),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Text('Proforma',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<Moneda>(
                initialValue: _moneda,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: Moneda.values
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(m.etiqueta)))
                    .toList(),
                onChanged: (v) => setState(() => _moneda = v!),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _transporteController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Transporte'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _descuentoController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Descuento'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Informacion relacionada (opcional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                  if (_proformaGuardada?.proformaId != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                      onPressed: _generarPdf,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Enviar'),
                      onPressed: _enviarCorreo,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              if (esNueva)
                const Text(
                    'Guarda la proforma primero para poder agregar equipos.')
              else
                _SeccionEquipos(proforma: _proformaGuardada!),
            ],
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Equipos',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              onPressed: () => _mostrarDialogo(context, ref),
            ),
          ],
        ),
        equiposAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Sin equipos agregados'));
            }
            final subtotal = items.fold(0.0, (sum, e) => sum + e.total);
            final base = subtotal + proforma.transporte;
            final iva = base * 0.13;
            final total = base + iva - proforma.descuento;

            return Column(
              children: [
                ...items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.nombreEquipo ??
                          'Equipo #${item.numeroActivo}'),
                      subtitle: Text(
                          'Cant: ${item.cantidad}  |  Dias: ${item.dias}'
                          '${item.observacion != null ? '  |  ${item.observacion}' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$s ${fmt.format(item.total)}'),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                _eliminar(context, ref, item),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                _filaResumen('Subtotal', '$s ${fmt.format(subtotal)}'),
                _filaResumen('Transporte',
                    '$s ${fmt.format(proforma.transporte)}'),
                _filaResumen(
                    'IVA (13%)', '$s ${fmt.format(iva)}'),
                _filaResumen('Descuento',
                    '$s ${fmt.format(proforma.descuento)}'),
                const Divider(),
                _filaResumen('Total', '$s ${fmt.format(total)}',
                    negrita: true),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _filaResumen(String label, String valor,
      {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      negrita ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 24),
          SizedBox(
              width: 120,
              child: Text(valor,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: negrita
                          ? FontWeight.bold
                          : FontWeight.normal))),
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
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final _dateFmt = DateFormat('d/M/yyyy');

  @override
  void dispose() {
    _cantidadController.dispose();
    _diasController.dispose();
    _costoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (esDesde) {
        _fechaDesde = picked;
      } else {
        _fechaHasta = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventarioAsync = ref.watch(inventarioListProvider);

    return AlertDialog(
      title: const Text('Agregar equipo'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                inventarioAsync.when(
                  data: (equipos) => DropdownButtonFormField<Inventario>(
                    initialValue: _equipoSeleccionado,
                    hint: const Text('Selecciona un equipo'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.nombreEquipo)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _equipoSeleccionado = v),
                    validator: (v) =>
                        v == null ? 'Selecciona un equipo' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Cantidad'),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null) ? 'Invalido' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _diasController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Dias'),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null) ? 'Invalido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(true),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Desde'),
                          child: Text(_fechaDesde != null
                              ? _dateFmt.format(_fechaDesde!)
                              : '—'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(false),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Hasta'),
                          child: Text(_fechaHasta != null
                              ? _dateFmt.format(_fechaHasta!)
                              : '—'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _costoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText:
                          'Precio unitario (${widget.proforma.moneda.simbolo})'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Valor invalido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observacionController,
                  decoration: const InputDecoration(
                      labelText: 'Observacion (opcional)'),
                ),
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
            onPressed: _confirmar, child: const Text('Agregar')),
      ],
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProformaEquipo(
        proformaId: widget.proforma.proformaId,
        numeroActivo: _equipoSeleccionado!.numeroActivo,
        cantidad: int.parse(_cantidadController.text.trim()),
        dias: int.parse(_diasController.text.trim()),
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
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
