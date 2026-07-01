import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers/proforma_providers.dart';
import 'proforma_form_screen.dart';

class ProformaListScreen extends ConsumerWidget {
  const ProformaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proformasAsync = ref.watch(proformaListProvider);

    return Scaffold(
      body: proformasAsync.when(
        data: (proformas) {
          if (proformas.isEmpty) {
            return const Center(child: Text('Sin proformas registradas'));
          }
          return ListView.builder(
            itemCount: proformas.length,
            itemBuilder: (context, index) {
              final proforma = proformas[index];
              final fecha = proforma.fechaCreacion != null
                  ? DateFormat('dd/MM/yyyy').format(proforma.fechaCreacion!)
                  : '';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.description)),
                title: Text(proforma.nombreCliente),
                subtitle: Text(fecha),
                trailing: Chip(label: Text(proforma.moneda.etiqueta)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProformaFormScreen(proformaExistente: proforma),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error al cargar proformas: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProformaFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
