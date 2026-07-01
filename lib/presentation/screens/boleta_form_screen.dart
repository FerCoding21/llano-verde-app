import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/providers/boleta_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../domain/models/boleta.dart';
import '../../domain/models/boleta_equipo.dart';
import '../../domain/models/boleta_imagen.dart';
import '../../domain/models/inventario.dart';

class BoletaFormScreen extends ConsumerStatefulWidget {
  const BoletaFormScreen({super.key, this.boletaExistente});

  final Boleta? boletaExistente;

  @override
  ConsumerState<BoletaFormScreen> createState() => _BoletaFormScreenState();
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
  late final _observacionesController =
      TextEditingController(text: widget.boletaExistente?.observaciones);

  late EstadoBoleta _estado =
      widget.boletaExistente?.estado ?? EstadoBoleta.activa;
  late DateTime? _fechaInicio = widget.boletaExistente?.fechaInicio;
  late DateTime? _fechaRetiro = widget.boletaExistente?.fechaRetiro;

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
    _observacionesController.dispose();
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
        nombreEmpresaCliente: _empresaController.text.trim(),
        contacto: _contactoController.text.trim().isEmpty
            ? null
            : _contactoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        facturaUrl: _facturaUrlController.text.trim().isEmpty
            ? null
            : _facturaUrlController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        estado: _estado,
        fechaInicio: _fechaInicio!,
        fechaRetiro: _fechaRetiro!,
      );
      final resultado = boleta.boletaId == null
          ? await repo.create(boleta)
          : await repo.update(boleta);
      ref.invalidate(boletaListProvider);
      setState(() => _boletaGuardada = resultado);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Boleta guardada')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = _boletaGuardada?.boletaId == null;

    return Scaffold(
      appBar: AppBar(
          title: Text(esNueva ? 'Nueva boleta' : 'Editar boleta')),
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
                controller: _empresaController,
                decoration:
                    const InputDecoration(labelText: 'Empresa / Cliente'),
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
                decoration: const InputDecoration(labelText: 'Telefono'),
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
              const SizedBox(height: 12),
              const Divider(),
              Text('Detalles del alquiler',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(true),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Fecha inicio'),
                        child: Text(_fechaInicio != null
                            ? _dateFmt.format(_fechaInicio!)
                            : 'Seleccionar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(false),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Fecha retiro'),
                        child: Text(_fechaRetiro != null
                            ? _dateFmt.format(_fechaRetiro!)
                            : 'Seleccionar'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EstadoBoleta>(
                initialValue: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: EstadoBoleta.values
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.etiqueta)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _facturaUrlController,
                decoration:
                    const InputDecoration(labelText: 'URL factura (opcional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              if (esNueva)
                const Text(
                    'Guarda la boleta primero para agregar equipos y fotos.')
              else ...[
                _SeccionEquipos(boleta: _boletaGuardada!),
                const SizedBox(height: 24),
                const Divider(),
                _SeccionImagenes(boletaId: _boletaGuardada!.boletaId!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección de equipos ────────────────────────────────────────────────────────

class _SeccionEquipos extends ConsumerWidget {
  const _SeccionEquipos({required this.boleta});

  final Boleta boleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equiposAsync =
        ref.watch(boletaEquiposProvider(boleta.boletaId!));
    final fmt = NumberFormat('#,##0.00');

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
                child: Text('Sin equipos agregados'),
              );
            }
            final total =
                items.fold(0.0, (sum, e) => sum + e.total);
            return Column(
              children: [
                ...items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.nombreEquipo ??
                          'Equipo #${item.numeroActivo}'),
                      subtitle: Text(
                        'Cant: ${item.cantidad}  |  Dias: ${item.dias}'
                        '${item.observacionEquipo != null ? '  |  ${item.observacionEquipo}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(fmt.format(item.total)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Total: ${fmt.format(total)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogo(BuildContext context, WidgetRef ref) async {
    final resultado = await showDialog<BoletaEquipo>(
      context: context,
      builder: (_) => _DialogoEquipo(boletaId: boleta.boletaId!),
    );
    if (resultado == null) return;
    try {
      await ref.read(boletaRepositoryProvider).addEquipo(resultado);
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
      ref.invalidate(boletaEquiposProvider(boleta.boletaId!));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}

// ── Sección de imágenes ───────────────────────────────────────────────────────

class _SeccionImagenes extends ConsumerStatefulWidget {
  const _SeccionImagenes({required this.boletaId});

  final int boletaId;

  @override
  ConsumerState<_SeccionImagenes> createState() => _SeccionImagenesState();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fotos del equipo',
                style: Theme.of(context).textTheme.titleMedium),
            _subiendo
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Agregar foto'),
                    onPressed: _agregar,
                  ),
          ],
        ),
        imagenesAsync.when(
          data: (imgs) {
            if (imgs.isEmpty) return const Text('Sin fotos agregadas');
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: imgs.length,
              itemBuilder: (context, i) {
                final img = imgs[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: img.urlImagen,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _eliminar(img),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
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
                            int.tryParse(v ?? '') == null
                                ? 'Invalido'
                                : null,
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
                            int.tryParse(v ?? '') == null
                                ? 'Invalido'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Precio final'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Invalido';
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
      BoletaEquipo(
        boletaId: widget.boletaId,
        numeroActivo: _equipoSeleccionado!.numeroActivo,
        cantidad: int.parse(_cantidadController.text.trim()),
        dias: int.parse(_diasController.text.trim()),
        precioFinal: double.parse(
            _precioController.text.trim().replaceAll(',', '.')),
        observacionEquipo: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        nombreEquipo: _equipoSeleccionado!.nombreEquipo,
      ),
    );
  }
}
