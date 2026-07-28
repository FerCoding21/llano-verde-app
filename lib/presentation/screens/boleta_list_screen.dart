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
      backgroundColor: const Color(0xFFF7F7F5),
      body: boletasAsync.when(
        data: (boletas) {
          if (boletas.isEmpty) {
            return const _EstadoVacio();
          }
          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: boletas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = boletas[i];
              return _ItemBoleta(boleta: b, dateFmt: dateFmt, ref: ref);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
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

class _ItemBoleta extends StatelessWidget {
  const _ItemBoleta(
      {required this.boleta,
      required this.dateFmt,
      required this.ref});

  final Boleta boleta;
  final DateFormat dateFmt;
  final WidgetRef ref;

  Color get _colorEstado {
    switch (boleta.estado) {
      case EstadoBoleta.activa:
        return const Color(0xFF2E7D32);
      case EstadoBoleta.finalizada:
        return const Color(0xFF1565C0);
      case EstadoBoleta.cancelada:
        return const Color(0xFFB71C1C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoletaFormScreen(boletaExistente: boleta),
          ),
        ).then((_) => ref.invalidate(boletaListProvider)),
        child: Row(
          children: [
            // Barra lateral de color según estado
            Container(
              width: 5,
              height: 80,
              decoration: BoxDecoration(
                color: _colorEstado,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boleta.nombreEmpresaCliente,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dateFmt.format(boleta.fechaInicio)} → ${dateFmt.format(boleta.fechaRetiro)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                    if (boleta.contacto != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        boleta.contacto!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFBBBBBB)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Badge de estado
            _BadgeEstado(boleta.estado),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  const _BadgeEstado(this.estado);
  final EstadoBoleta estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: estado.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined,
              size: 56, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'No hay boletas registradas',
            style:
                TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
