import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/utils/boleta_pdf.dart';
import '../../core/utils/email_service.dart';
import '../../core/utils/notification_service.dart';
import '../../data/providers/boleta_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../data/providers/proforma_providers.dart';
import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';
import '../../domain/models/boleta_imagen.dart';
import '../../domain/models/inventario.dart';
import '../../domain/models/proforma.dart';

const _verde = Color(0xFF2E7D32);
const _verdeOscuro = Color(0xFF1B5E20);
const _fondoVerde = Color(0xFFF0F7F0);

class BoletaFormScreen extends ConsumerStatefulWidget {
  const BoletaFormScreen({super.key, this.boletaExistente});

  final Boleta? boletaExistente;

  @override
  ConsumerState<BoletaFormScreen> createState() =>
      _BoletaFormScreenState();
}

class _BoletaFormScreenState extends ConsumerState<BoletaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _empresaController =
      TextEditingController(text: widget.boletaExistente?.nombreEmpresaCliente);
  late final _contactoController =
      TextEditingController(text: widget.boletaExistente?.contacto);
  late final _correoController =
      TextEditingController(text: widget.boletaExistente?.correo);
  late final _telefonoController =
      TextEditingController(text: widget.boletaExistente?.telefono);
  late final _facturaUrlController =
      TextEditingController(text: widget.boletaExistente?.facturaUrl);
  late final _ordenCompraController =
      TextEditingController(text: widget.boletaExistente?.ordenCompra);
  late final _observacionesController =
      TextEditingController(text: widget.boletaExistente?.observaciones);
  late final _transporteController = TextEditingController(
      text: widget.boletaExistente?.transporte.toStringAsFixed(2) ??
          '0.00');
  late final _descuentoController = TextEditingController(
      text: widget.boletaExistente?.descuento.toStringAsFixed(2) ??
          '0.00');

  late EstadoBoleta _estado =
      widget.boletaExistente?.estado ?? EstadoBoleta.activa;
  late DateTime? _fechaInicio = widget.boletaExistente?.fechaInicio;
  late DateTime? _fechaRetiro = widget.boletaExistente?.fechaRetiro;

  Proforma? _proformaSeleccionada;
  Boleta? _boletaGuardada;
  bool _guardando = false;
  final _dateFmt = DateFormat('d/M/yyyy');

  @override
  void initState() {
    super.initState();
    _boletaGuardada = widget.boletaExistente;
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _contactoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _facturaUrlController.dispose();
    _ordenCompraController.dispose();
    _observacionesController.dispose();
    _transporteController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
      } else {
        _fechaRetiro = picked;
      }
    });
  }

  void _rellenarDesdeProforma(Proforma p) {
    _empresaController.text = p.nombreCliente;
    _contactoController.text = p.contacto ?? '';
    _correoController.text = p.correoCliente;
    _telefonoController.text = p.telefonoCliente;
    _transporteController.text = p.transporte.toStringAsFixed(2);
    _descuentoController.text = p.descuento.toStringAsFixed(2);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaRetiro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona las fechas de inicio y retiro')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final repo = ref.read(boletaRepositoryProvider);
      final boleta = Boleta(
        boletaId: _boletaGuardada?.boletaId,
        proformaId: _proformaSeleccionada?.proformaId ??
            widget.boletaExistente?.proformaId,
        nombreEmpresaCliente: _empresaController.text.trim(),
        contacto: _contactoController.text.trim().isEmpty
            ? null
            : _contactoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        facturaUrl: _facturaUrlController.text.trim().isEmpty
            ? null
            : _facturaUrlController.text.trim(),
        ordenCompra: _ordenCompraController.text.trim().isEmpty
            ? null
            : _ordenCompraController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        estado: _estado,
        fechaInicio: _fechaInicio!,
        fechaRetiro: _fechaRetiro!,
        transporte: double.tryParse(
                _transporteController.text.trim().replaceAll(',', '.')) ??
            0,
        descuento: double.tryParse(
                _descuentoController.text.trim().replaceAll(',', '.')) ??
            0,
      );
      final resultado = boleta.boletaId == null
          ? await repo.create(boleta)
          : await repo.update(boleta);
      ref.invalidate(boletaListProvider);
      ref.invalidate(boletasActivasProvider);
      setState(() => _boletaGuardada = resultado);
      await NotificationService.programarAlertas(resultado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boleta guardada')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _generarPdf() async {
    final equipos = await ref
        .read(boletaRepositoryProvider)
        .getEquipos(_boletaGuardada!.boletaId!);
    await BoletaPdf.mostrar(boleta: _boletaGuardada!, equipos: equipos);
  }

  Future<void> _enviarCorreo() async {
    final equipos = await ref
        .read(boletaRepositoryProvider)
        .getEquipos(_boletaGuardada!.boletaId!);
    try {
      await EmailService.enviarBoleta(
          boleta: _boletaGuardada!, equipos: equipos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Boleta enviada a ${_boletaGuardada!.correo}')));
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
    final esNueva = _boletaGuardada?.boletaId == null;
    final guardada = _boletaGuardada?.boletaId != null;
    final proformaListAsync = ref.watch(proformaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(esNueva ? 'Nueva boleta' : 'Editar boleta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Vincular proforma (solo boletas nuevas) ──────────────
            if (esNueva) ...[
              _Seccion(
                titulo: 'Vincular a proforma (opcional)',
                children: [
                  proformaListAsync.when(
                    data: (proformas) =>
                        DropdownButtonFormField<Proforma>(
                      initialValue: _proformaSeleccionada,
                      hint: const Text('Selecciona una proforma...'),
                      decoration: const InputDecoration(
                        labelText: 'Proforma',
                        prefixIcon:
                            Icon(Icons.link_outlined, size: 20),
                      ),
                      items: proformas
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                    'P#${p.proformaId} — ${p.nombreCliente}'),
                              ))
                          .toList(),
                      onChanged: (p) {
                        setState(() => _proformaSeleccionada = p);
                        if (p != null) _rellenarDesdeProforma(p);
                      },
                    ),
                    loading: () =>
                        const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ] else if (_boletaGuardada?.proformaId != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: _verde),
                    const SizedBox(width: 8),
                    Text(
                      'Vinculada a Proforma #${_boletaGuardada!.proformaId}',
                      style: const TextStyle(
                          color: _verde, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            // ── Cliente ──────────────────────────────────────────────
            _Seccion(
              titulo: 'Datos del cliente',
              children: [
                TextFormField(
                  controller: _empresaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Empresa / Cliente',
                    prefixIcon:
                        Icon(Icons.business_outlined, size: 20),
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
                    prefixIcon:
                        Icon(Icons.person_outline, size: 20),
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
              ],
            ),

            // ── Detalles del alquiler ────────────────────────────────
            _Seccion(
              titulo: 'Detalles del alquiler',
              children: [
                // Fechas
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha inicio',
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18),
                            filled: true,
                            fillColor: const Color(0xFFEEECE6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Text(
                            _fechaInicio != null
                                ? _dateFmt.format(_fechaInicio!)
                                : 'Seleccionar',
                            style: TextStyle(
                              color: _fechaInicio != null
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha retiro',
                            prefixIcon: const Icon(
                                Icons.event_outlined,
                                size: 18),
                            filled: true,
                            fillColor: const Color(0xFFEEECE6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Text(
                            _fechaRetiro != null
                                ? _dateFmt.format(_fechaRetiro!)
                                : 'Seleccionar',
                            style: TextStyle(
                              color: _fechaRetiro != null
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoBoleta>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon:
                        Icon(Icons.circle_outlined, size: 18),
                  ),
                  items: EstadoBoleta.values.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Row(children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: e.color,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(e.etiqueta),
                      ]),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _estado = v!),
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
                          prefixIcon: Icon(
                              Icons.local_shipping_outlined,
                              size: 18),
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
                          prefixIcon:
                              Icon(Icons.discount_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _facturaUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL factura (opcional)',
                    prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ordenCompraController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Orden de compra (opcional)',
                    prefixIcon: Icon(Icons.tag_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon:
                        Icon(Icons.notes_outlined, size: 18),
                  ),
                ),
              ],
            ),

            // ── Botones acción ───────────────────────────────────────
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
                    : const Text('Guardar boleta',
                        style: TextStyle(fontSize: 15)),
              ),
            ),
            if (guardada) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                          Icons.picture_as_pdf_outlined,
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

            // ── Equipos e imágenes ───────────────────────────────────
            if (esNueva)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF9E9E9E), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Guarda la boleta primero para agregar equipos y fotos.',
                        style: TextStyle(
                            color: Color(0xFF757575), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _SeccionEquipos(
                boleta: _boletaGuardada!,
                proformaVinculada: _proformaSeleccionada,
              ),
              const SizedBox(height: 12),
              _SeccionImagenes(boletaId: _boletaGuardada!.boletaId!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sección equipos ───────────────────────────────────────────────────────────

class _SeccionEquipos extends ConsumerWidget {
  const _SeccionEquipos({
    required this.boleta,
    this.proformaVinculada,
  });

  final Boleta boleta;
  final Proforma? proformaVinculada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equiposAsync =
        ref.watch(boletaEquiposProvider(boleta.boletaId!));
    final fmt = NumberFormat('#,##0.00');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (proformaVinculada != null)
                  TextButton.icon(
                    icon: const Icon(Icons.download_outlined,
                        size: 16),
                    label: Text(
                        'Importar P#${proformaVinculada!.proformaId}'),
                    style:
                        TextButton.styleFrom(foregroundColor: _verde),
                    onPressed: () =>
                        _importarDesdeProforma(context, ref),
                  ),
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
              final base = subtotal + boleta.transporte;
              final iva = base * 0.13;
              final total = base + iva - boleta.descuento;

              return Column(
                children: [
                  ...items.map((item) => _ItemEquipo(
                        nombre: item.nombreEquipo ??
                            'Equipo #${item.numeroActivo}',
                        detalle:
                            'Cant: ${item.cantidad}  ·  ${item.dias} días'
                            '${item.observacionEquipo != null ? '  ·  ${item.observacionEquipo}' : ''}',
                        total: fmt.format(item.total),
                        onEliminar: () =>
                            _eliminar(context, ref, item),
                      )),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _fondoVerde,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _FilaTotal(
                            'Subtotal', fmt.format(subtotal)),
                        _FilaTotal('Transporte',
                            fmt.format(boleta.transporte)),
                        _FilaTotal('IVA (13%)', fmt.format(iva)),
                        _FilaTotal('Descuento',
                            '- ${fmt.format(boleta.descuento)}'),
                        const Divider(height: 16),
                        _FilaTotal('Total', fmt.format(total),
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

  Future<void> _importarDesdeProforma(
      BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Importar equipos'),
        content: Text(
            'Se copiarán los equipos de la Proforma #${proformaVinculada!.proformaId} '
            'a esta boleta. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _verde),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final proformaEquipos = await ref
          .read(proformaRepositoryProvider)
          .getEquipos(proformaVinculada!.proformaId!);
      final boletaRepo = ref.read(boletaRepositoryProvider);
      final inventarioRepo = ref.read(inventarioRepositoryProvider);
      for (final pe in proformaEquipos) {
        await boletaRepo.addEquipo(BoletaEquipo(
          boletaId: boleta.boletaId,
          numeroActivo: pe.numeroActivo,
          cantidad: pe.cantidad,
          dias: pe.dias,
          precioFinal: pe.costo,
          observacionEquipo: pe.observacion,
          nombreEquipo: pe.nombreEquipo,
        ));
        if (pe.numeroActivo != null) {
          await inventarioRepo.updateEstado(
              pe.numeroActivo!, EstadoInventario.alquilado);
        }
      }
      ref.invalidate(inventarioListProvider);
      ref.invalidate(inventarioDisponibleProvider);
      ref.invalidate(boletaEquiposProvider(boleta.boletaId!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${proformaEquipos.length} equipos importados')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al importar: $e')));
      }
    }
  }

  Future<void> _mostrarDialogo(
      BuildContext context, WidgetRef ref) async {
    final resultado = await showDialog<BoletaEquipo>(
      context: context,
      builder: (_) => _DialogoEquipo(boletaId: boleta.boletaId!),
    );
    if (resultado == null) return;
    try {
      await ref.read(boletaRepositoryProvider).addEquipo(resultado);
      if (resultado.numeroActivo != null) {
        await ref.read(inventarioRepositoryProvider).updateEstado(
            resultado.numeroActivo!, EstadoInventario.alquilado);
        ref.invalidate(inventarioListProvider);
        ref.invalidate(inventarioDisponibleProvider);
      }
      ref.invalidate(boletaEquiposProvider(boleta.boletaId!));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar equipo: $e')));
      }
    }
  }

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, BoletaEquipo item) async {
    try {
      await ref
          .read(boletaRepositoryProvider)
          .deleteEquipo(item.boletaEquipoId!);
      if (item.numeroActivo != null) {
        await ref.read(inventarioRepositoryProvider).updateEstado(
            item.numeroActivo!, EstadoInventario.disponible);
        ref.invalidate(inventarioListProvider);
        ref.invalidate(inventarioDisponibleProvider);
      }
      ref.invalidate(boletaEquiposProvider(boleta.boletaId!));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}

// ── Sección imágenes ──────────────────────────────────────────────────────────

class _SeccionImagenes extends ConsumerStatefulWidget {
  const _SeccionImagenes({required this.boletaId});

  final int boletaId;

  @override
  ConsumerState<_SeccionImagenes> createState() =>
      _SeccionImagenesState();
}

class _SeccionImagenesState extends ConsumerState<_SeccionImagenes> {
  bool _subiendo = false;

  Future<void> _agregar() async {
    final archivo = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (archivo == null) return;
    setState(() => _subiendo = true);
    try {
      await BoletaImagenesController(ref)
          .agregar(widget.boletaId, archivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _eliminar(BoletaImagen imagen) async {
    try {
      await BoletaImagenesController(ref)
          .eliminar(widget.boletaId, imagen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenesAsync =
        ref.watch(imagenesBoletaProvider(widget.boletaId));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  'Fotos del equipo',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A)),
                ),
                const Spacer(),
                _subiendo
                    ? const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _verde),
                        ),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.add_a_photo_outlined,
                            size: 18),
                        label: const Text('Foto'),
                        style: TextButton.styleFrom(
                            foregroundColor: _verde),
                        onPressed: _agregar,
                      ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: imagenesAsync.when(
              data: (imgs) {
                if (imgs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin fotos agregadas.',
                        style:
                            TextStyle(color: Color(0xFF9E9E9E))),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: imgs.length,
                  itemBuilder: (_, i) {
                    final img = imgs[i];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: img.urlImagen,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminar(img),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo agregar equipo ────────────────────────────────────────────────────

class _DialogoEquipo extends ConsumerStatefulWidget {
  const _DialogoEquipo({required this.boletaId});

  final int boletaId;

  @override
  ConsumerState<_DialogoEquipo> createState() => _DialogoEquipoState();
}

class _DialogoEquipoState extends ConsumerState<_DialogoEquipo> {
  final _formKey = GlobalKey<FormState>();
  Inventario? _equipoSeleccionado;
  final _cantidadController = TextEditingController(text: '1');
  final _diasController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _diasController.dispose();
    _precioController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventarioAsync = ref.watch(inventarioDisponibleProvider);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Agregar equipo',
          style: TextStyle(fontWeight: FontWeight.w700)),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        labelText: 'Equipo disponible'),
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
                  loading: () => const LinearProgressIndicator(),
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
                            int.tryParse(v ?? '') == null
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
                            int.tryParse(v ?? '') == null
                                ? 'Inválido'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Precio final'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Inválido';
                    }
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
    Navigator.of(context).pop(
      BoletaEquipo(
        boletaId: widget.boletaId,
        numeroActivo: _equipoSeleccionado!.numeroActivo,
        cantidad: int.parse(_cantidadController.text.trim()),
        dias: int.parse(_diasController.text.trim()),
        precioFinal: double.parse(
            _precioController.text.trim().replaceAll(',', '.')),
        observacionEquipo:
            _observacionController.text.trim().isEmpty
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
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
