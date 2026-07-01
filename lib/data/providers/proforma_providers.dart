import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/proforma.dart';
import '../../domain/models/proforma_equipo.dart';
import '../repositories/proforma_repository.dart';

final proformaRepositoryProvider = Provider<ProformaRepository>((ref) {
  return ProformaRepository();
});

final proformaListProvider = FutureProvider<List<Proforma>>((ref) {
  return ref.watch(proformaRepositoryProvider).getAll();
});

final proformaEquiposProvider =
    FutureProvider.family<List<ProformaEquipo>, int>((ref, proformaId) {
  return ref.watch(proformaRepositoryProvider).getEquipos(proformaId);
});
