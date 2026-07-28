import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers/boleta_providers.dart';
import '../../domain/models/boleta.dart';
import 'verificacion_detalle_screen.dart';

class VerificacionScreen extends ConsumerWidget {
  const VerificacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activasAsync = ref.watch(boletasActivasProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: activasAsync.when(
        data: (boletas) {
          if (boletas.isEmpty) {
            return const _EstadoLibre();
          }
          final urgentes =
              boletas.where((b) => _diasRestantes(b) <= 7).length;

          return Column(
            children: [
              // Resumen rápido
              _HeaderResumen(
                  total: boletas.length, urgentes: urgentes),
              // Lista
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: boletas.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TarjetaBoleta(
                      boleta: boletas[i], dateFmt: dateFmt),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

int _diasRestantes(Boleta b) =>
    b.fechaRetiro.difference(DateTime.now()).inDays;

class _HeaderResumen extends StatelessWidget {
  const _HeaderResumen(
      {required this.total, required this.urgentes});

  final int total;
  final int urgentes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _Stat(
            valor: '$total',
            etiqueta: 'Activos',
            color: Colors.white,
          ),
          const SizedBox(width: 24),
          if (urgentes > 0)
            _Stat(
              valor: '$urgentes',
              etiqueta: 'Urgentes',
              color: const Color(0xFFFFBF00),
            ),
          const Spacer(),
          const Icon(Icons.info_outline,
              size: 16, color: Colors.white38),
          const SizedBox(width: 4),
          const Text(
            'Ordenado por fecha retiro',
            style: TextStyle(
                fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.valor,
      required this.etiqueta,
      required this.color});

  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          etiqueta,
          style: const TextStyle(
              fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _TarjetaBoleta extends StatelessWidget {
  const _TarjetaBoleta(
      {required this.boleta, required this.dateFmt});

  final Boleta boleta;
  final DateFormat dateFmt;

  int get _dias => _diasRestantes(boleta);

  Color get _color {
    final d = _dias;
    if (d < 0) return const Color(0xFFB71C1C);
    if (d <= 1) return const Color(0xFFE65100);
    if (d <= 7) return const Color(0xFFF57F17);
    return const Color(0xFF2E7D32);
  }

  String get _etiqueta {
    final d = _dias;
    if (d < 0) return '${d.abs()}d vencido';
    if (d == 0) return 'Vence hoy';
    if (d == 1) return 'Mañana';
    return 'En ${d}d';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerificacionDetalleScreen(boleta: boleta),
          ),
        ),
        child: Row(
          children: [
            // Barra lateral de urgencia
            Container(
              width: 5,
              height: 82,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
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
                            fontSize: 12,
                            color: Color(0xFFBBBBBB)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Badge de urgencia
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _EstadoLibre extends StatelessWidget {
  const _EstadoLibre();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 40, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Todo en orden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No hay equipos actualmente alquilados',
            style:
                TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
