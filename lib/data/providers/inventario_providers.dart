import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventario.dart';
import '../repositories/inventario_repository.dart';

final inventarioRepositoryProvider = Provider<InventarioRepository>((ref) {
  return InventarioRepository();
});

final busquedaInventarioProvider = StateProvider<String>((ref) => '');

final estadoFiltroProvider = StateProvider<EstadoInventario?>((ref) => null);

final inventarioListProvider = FutureProvider<List<Inventario>>((ref) async {
  final repository = ref.watch(inventarioRepositoryProvider);
  final busqueda = ref.watch(busquedaInventarioProvider);
  final estado = ref.watch(estadoFiltroProvider);
  return repository.getAll(estado: estado, busqueda: busqueda);
});

// Solo equipos disponibles — para los selectores de proforma y boleta
final inventarioDisponibleProvider = FutureProvider<List<Inventario>>((ref) {
  return ref.watch(inventarioRepositoryProvider)
      .getAll(estado: EstadoInventario.disponible);
});
