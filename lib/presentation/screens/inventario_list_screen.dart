import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/inventario_imagen_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../domain/models/inventario.dart';
import 'inventario_form_screen.dart';

class InventarioListScreen extends ConsumerWidget {
  const InventarioListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventarioAsync = ref.watch(inventarioListProvider);
    final estadoFiltro = ref.watch(estadoFiltroProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Column(
        children: [
          // Barra de búsqueda y filtros — header cálido
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                // Search pill — blanco sobre verde
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: TextField(
                    onChanged: (v) => ref
                        .read(busquedaInventarioProvider.notifier)
                        .state = v,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Buscar equipo...',
                      hintStyle:
                          TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white60, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        activo: estadoFiltro == null,
                        onTap: () => ref
                            .read(estadoFiltroProvider.notifier)
                            .state = null,
                      ),
                      const SizedBox(width: 8),
                      ...EstadoInventario.values.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FiltroChip(
                            label: _etiquetaEstado(e),
                            activo: estadoFiltro == e,
                            color: _colorEstado(e),
                            onTap: () => ref
                                .read(estadoFiltroProvider.notifier)
                                .state =
                                estadoFiltro == e ? null : e,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: inventarioAsync.when(
              data: (equipos) {
                if (equipos.isEmpty) {
                  return _EstadoVacio(
                    icon: Icons.construction_outlined,
                    mensaje: estadoFiltro == null
                        ? 'Sin equipos registrados'
                        : 'Sin equipos ${_etiquetaEstado(estadoFiltro).toLowerCase()}',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: equipos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _ItemEquipo(equipo: equipos[i]),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const InventarioFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemEquipo extends ConsumerWidget {
  const _ItemEquipo({required this.equipo});
  final Inventario equipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                InventarioFormScreen(equipoExistente: equipo),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen circular
              _MiniaturaEquipo(
                  numeroActivo: equipo.numeroActivo!),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo.nombreEquipo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (equipo.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        equipo.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _BadgeEstado(equipo.estado),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right,
                  color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniaturaEquipo extends ConsumerWidget {
  const _MiniaturaEquipo({required this.numeroActivo});
  final int numeroActivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagenesAsync =
        ref.watch(imagenesEquipoProvider(numeroActivo));

    return imagenesAsync.when(
      data: (imagenes) {
        if (imagenes.isEmpty) {
          return _avatarPlaceholder();
        }
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: imagenes.first.urlImagen,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (_, __) => _avatarPlaceholder(),
            errorWidget: (_, __, ___) => _avatarPlaceholder(),
          ),
        );
      },
      loading: () => _avatarPlaceholder(loading: true),
      error: (_, __) => _avatarPlaceholder(),
    );
  }

  Widget _avatarPlaceholder({bool loading = false}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFED),
        shape: BoxShape.circle,
      ),
      child: loading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.construction_outlined,
              color: Color(0xFFBBBBBB), size: 26),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  const _BadgeEstado(this.estado);
  final EstadoInventario estado;

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(estado);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _etiquetaEstado(estado),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool activo;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    const dorado = Color(0xFFFFBF00);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo
              ? dorado
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo
                ? dorado
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo
                ? const Color(0xFF1A3A00)
                : Colors.white,
            fontWeight:
                activo ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.icon, required this.mensaje});
  final IconData icon;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: const TextStyle(
                color: Color(0xFF9E9E9E), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

Color _colorEstado(EstadoInventario e) {
  switch (e) {
    case EstadoInventario.disponible:
      return const Color(0xFF2E7D32);
    case EstadoInventario.alquilado:
      return const Color(0xFFE65100);
    case EstadoInventario.mantenimiento:
      return const Color(0xFF757575);
  }
}

String _etiquetaEstado(EstadoInventario? e) {
  switch (e) {
    case EstadoInventario.disponible:
      return 'Disponible';
    case EstadoInventario.alquilado:
      return 'Alquilado';
    case EstadoInventario.mantenimiento:
      return 'Mantenimiento';
    case null:
      return '';
  }
}
