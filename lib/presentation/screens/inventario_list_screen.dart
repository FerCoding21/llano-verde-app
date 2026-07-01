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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    ref.read(busquedaInventarioProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButton<EstadoInventario?>(
                  value: estadoFiltro,
                  hint: const Text('Filtrar por estado'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...EstadoInventario.values.map(
                      (estado) => DropdownMenuItem(
                        value: estado,
                        child: Text(estado.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(estadoFiltroProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: inventarioAsync.when(
              data: (equipos) {
                if (equipos.isEmpty) {
                  return const Center(child: Text('Sin equipos registrados'));
                }
                return ListView.builder(
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = equipos[index];
                    return ListTile(
                      leading: _MiniaturaEquipo(
                        numeroActivo: equipo.numeroActivo!,
                      ),
                      title: Text(equipo.nombreEquipo),
                      subtitle: Text(equipo.descripcion),
                      trailing: Chip(label: Text(equipo.estado.name)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InventarioFormScreen(equipoExistente: equipo),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error al cargar inventario: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventarioFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MiniaturaEquipo extends ConsumerWidget {
  const _MiniaturaEquipo({required this.numeroActivo});

  final int numeroActivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagenesAsync = ref.watch(imagenesEquipoProvider(numeroActivo));

    return imagenesAsync.when(
      data: (imagenes) {
        if (imagenes.isEmpty) {
          return const CircleAvatar(child: Icon(Icons.construction));
        }
        return CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(imagenes.first.urlImagen),
        );
      },
      loading: () => const CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const CircleAvatar(child: Icon(Icons.construction)),
    );
  }
}
