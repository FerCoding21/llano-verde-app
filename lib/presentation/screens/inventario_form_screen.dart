import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/providers/inventario_imagen_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../domain/models/inventario.dart';

const _verde = Color(0xFF2E7D32);
const _verdeOscuro = Color(0xFF1B5E20);

class InventarioFormScreen extends ConsumerStatefulWidget {
  const InventarioFormScreen({super.key, this.equipoExistente});

  final Inventario? equipoExistente;

  @override
  ConsumerState<InventarioFormScreen> createState() =>
      _InventarioFormScreenState();
}

class _InventarioFormScreenState
    extends ConsumerState<InventarioFormScreen> {
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

  Future<void> _setFotoPrincipal(String url) async {
    final equipo = _equipoGuardado;
    if (equipo?.numeroActivo == null) return;
    try {
      await ref
          .read(inventarioRepositoryProvider)
          .setFotoPortada(equipo!.numeroActivo!, url);
      // Invalidar el provider que la galería observa para que recargue desde BD
      ref.invalidate(inventarioItemProvider(equipo.numeroActivo!));
      ref.invalidate(inventarioListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _agregarFoto() async {
    final equipo = _equipoGuardado;
    if (equipo?.numeroActivo == null) return;
    final archivo =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
      appBar: AppBar(
        title: Text(esNuevo ? 'Nuevo equipo' : 'Editar equipo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Datos del equipo ────────────────────────────────────
            _Seccion(
              titulo: 'Datos del equipo',
              children: [
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                    prefixIcon:
                        Icon(Icons.construction_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                    prefixIcon:
                        Icon(Icons.notes_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoInventario>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon:
                        Icon(Icons.circle_outlined, size: 20),
                  ),
                  items: EstadoInventario.values.map((e) {
                    final color = _colorEstado(e);
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
              ],
            ),

            // ── Guardar ──────────────────────────────────────────────
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
                    : const Text('Guardar equipo',
                        style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Fotos ────────────────────────────────────────────────
            _Seccion(
              titulo: 'Fotos del equipo',
              children: [
                if (esNuevo)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Color(0xFF9E9E9E)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guarda el equipo primero para poder agregar fotos.',
                            style: TextStyle(
                                color: Color(0xFF757575), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _GaleriaFotos(
                    numeroActivo: _equipoGuardado!.numeroActivo!,
                    subiendo: _subiendoFoto,
                    onAgregar: _agregarFoto,
                    onSetPrincipal: _setFotoPrincipal,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(EstadoInventario e) {
    switch (e) {
      case EstadoInventario.disponible:
        return const Color(0xFF2E7D32);
      case EstadoInventario.alquilado:
        return const Color(0xFFE65100);
      case EstadoInventario.mantenimiento:
        return const Color(0xFFB71C1C);
    }
  }
}

// ── Galería de fotos ──────────────────────────────────────────────────────────

class _GaleriaFotos extends ConsumerWidget {
  const _GaleriaFotos({
    required this.numeroActivo,
    required this.subiendo,
    required this.onAgregar,
    required this.onSetPrincipal,
  });

  final int numeroActivo;
  final bool subiendo;
  final VoidCallback onAgregar;
  final void Function(String url) onSetPrincipal;

  static const _dorado = Color(0xFFFFBF00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagenesAsync = ref.watch(imagenesEquipoProvider(numeroActivo));
    // Lee fotoPortada siempre fresca desde BD para evitar desfase con el estado del parent
    final fotoPortada =
        ref.watch(inventarioItemProvider(numeroActivo)).valueOrNull?.fotoPortada;

    return imagenesAsync.when(
      data: (imagenes) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagenes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imagenes.map((img) {
                final esPrincipal = img.urlImagen == fotoPortada;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: img.urlImagen,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Botón eliminar
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(imagenesEquipoControllerProvider)
                            .eliminarImagen(img),
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
                    // Botón foto principal
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: () => onSetPrincipal(img.urlImagen),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: esPrincipal
                                ? _dorado
                                : Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            esPrincipal ? Icons.star : Icons.star_border,
                            size: 14,
                            color: esPrincipal
                                ? const Color(0xFF1A3A00)
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca ★ para marcar como foto principal (aparece en PDF)',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: subiendo ? null : onAgregar,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _verde),
              foregroundColor: _verde,
            ),
            icon: subiendo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _verde),
                  )
                : const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(subiendo ? 'Subiendo...' : 'Agregar foto'),
          ),
        ],
      ),
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      )),
      error: (e, _) => Text('Error: $e',
          style: const TextStyle(color: Colors.red)),
    );
  }
}

// ── Widget reutilizable de sección ────────────────────────────────────────────

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
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
