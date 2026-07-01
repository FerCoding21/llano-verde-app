import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/providers/inventario_imagen_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../domain/models/inventario.dart';

class InventarioFormScreen extends ConsumerStatefulWidget {
  const InventarioFormScreen({super.key, this.equipoExistente});

  final Inventario? equipoExistente;

  @override
  ConsumerState<InventarioFormScreen> createState() => _InventarioFormScreenState();
}

class _InventarioFormScreenState extends ConsumerState<InventarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController =
      TextEditingController(text: widget.equipoExistente?.nombreEquipo);
  late final _descripcionController =
      TextEditingController(text: widget.equipoExistente?.descripcion);
  late EstadoInventario _estado =
      widget.equipoExistente?.estado ?? EstadoInventario.disponible;

  Inventario? _equipoGuardado;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _equipoGuardado = widget.equipoExistente;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final repository = ref.read(inventarioRepositoryProvider);
      final equipo = Inventario(
        numeroActivo: _equipoGuardado?.numeroActivo,
        nombreEquipo: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        estado: _estado,
      );

      final resultado = equipo.numeroActivo == null
          ? await repository.create(equipo)
          : await repository.update(equipo);

      ref.invalidate(inventarioListProvider);
      setState(() => _equipoGuardado = resultado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipo guardado')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _agregarFoto() async {
    final equipo = _equipoGuardado;
    if (equipo?.numeroActivo == null) return;

    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (archivo == null) return;

    setState(() => _subiendoFoto = true);
    try {
      final bytes = await archivo.readAsBytes();
      final extension = archivo.path.split('.').last;
      await ref.read(imagenesEquipoControllerProvider).agregarImagen(
            numeroActivo: equipo!.numeroActivo!,
            bytes: bytes,
            extension: extension,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = _equipoGuardado?.numeroActivo == null;

    return Scaffold(
      appBar: AppBar(title: Text(esNuevo ? 'Nuevo equipo' : 'Editar equipo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del equipo'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingresa una descripción' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EstadoInventario>(
                initialValue: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: EstadoInventario.values
                    .map((estado) => DropdownMenuItem(value: estado, child: Text(estado.name)))
                    .toList(),
                onChanged: (value) => setState(() => _estado = value!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Fotos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (esNuevo)
                const Text('Guarda el equipo primero para poder agregar fotos.')
              else
                _GaleriaFotos(
                  numeroActivo: _equipoGuardado!.numeroActivo!,
                  subiendo: _subiendoFoto,
                  onAgregar: _agregarFoto,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaleriaFotos extends ConsumerWidget {
  const _GaleriaFotos({
    required this.numeroActivo,
    required this.subiendo,
    required this.onAgregar,
  });

  final int numeroActivo;
  final bool subiendo;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagenesAsync = ref.watch(imagenesEquipoProvider(numeroActivo));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imagenesAsync.when(
          data: (imagenes) {
            if (imagenes.isEmpty) {
              return const Text('Sin fotos todavía');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imagenes.map((imagen) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imagen.urlImagen,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => ref
                            .read(imagenesEquipoControllerProvider)
                            .eliminarImagen(imagen),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error al cargar fotos: $error'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: subiendo ? null : onAgregar,
          icon: subiendo
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo),
          label: const Text('Agregar foto'),
        ),
      ],
    );
  }
}
