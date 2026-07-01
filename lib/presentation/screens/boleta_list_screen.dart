import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers/boleta_providers.dart';
import '../../domain/models/boleta.dart';
import 'boleta_form_screen.dart';

class BoletaListScreen extends ConsumerWidget {
  const BoletaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boletasAsync = ref.watch(boletaListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: boletasAsync.when(
        data: (boletas) {
          if (boletas.isEmpty) {
            return const Center(child: Text('No hay boletas registradas'));
          }
          return ListView.builder(
            itemCount: boletas.length,
            itemBuilder: (context, i) {
              final b = boletas[i];
              return ListTile(
                title: Text(b.nombreEmpresaCliente,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${dateFmt.format(b.fechaInicio)} → ${dateFmt.format(b.fechaRetiro)}'
                  '${b.contacto != null ? '\n${b.contacto}' : ''}',
                ),
                isThreeLine: b.contacto != null,
                trailing: _ChipEstado(b.estado),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BoletaFormScreen(boletaExistente: b),
                  ),
                ).then((_) => ref.invalidate(boletaListProvider)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BoletaFormScreen()),
        ).then((_) => ref.invalidate(boletaListProvider)),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado(this.estado);
  final EstadoBoleta estado;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        estado.etiqueta,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: estado.color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
