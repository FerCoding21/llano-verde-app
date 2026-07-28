import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers/proforma_providers.dart';
import '../../domain/models/proforma.dart';
import 'proforma_form_screen.dart';

class ProformaListScreen extends ConsumerWidget {
  const ProformaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proformasAsync = ref.watch(proformaListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: proformasAsync.when(
        data: (proformas) {
          if (proformas.isEmpty) {
            return const _EstadoVacio();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: proformas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = proformas[i];
              return _ItemProforma(proforma: p, dateFmt: dateFmt);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

class _ItemProforma extends StatelessWidget {
  const _ItemProforma(
      {required this.proforma, required this.dateFmt});

  final Proforma proforma;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final fecha = proforma.fechaCreacion != null
        ? dateFmt.format(proforma.fechaCreacion!)
        : '—';
    final esCRC = proforma.moneda == Moneda.colon;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ProformaFormScreen(proformaExistente: proforma),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Acento vertical verde
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Ícono
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined,
                    color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proforma.nombreCliente,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P#${proforma.proformaId ?? '—'} · $fecha',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),

              // Badge moneda
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: esCRC
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  proforma.moneda.etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: esCRC
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFCCCCCC)),
            ],
          ),
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
          Icon(Icons.description_outlined,
              size: 56, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'Sin proformas registradas',
            style:
                TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
