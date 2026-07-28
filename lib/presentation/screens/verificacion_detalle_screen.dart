import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/notification_service.dart';
import '../../data/providers/boleta_providers.dart';
import '../../data/providers/inventario_providers.dart';
import '../../domain/models/boleta.dart';
import '../../domain/models/inventario.dart';

const _verde = Color(0xFF2E7D32);
const _verdeOscuro = Color(0xFF1B5E20);
const _fondoVerde = Color(0xFFF0F7F0);

class VerificacionDetalleScreen extends ConsumerWidget {
  const VerificacionDetalleScreen({super.key, required this.boleta});

  final Boleta boleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equiposAsync =
        ref.watch(boletaEquiposProvider(boleta.boletaId!));
    final imagenesAsync =
        ref.watch(imagenesBoletaProvider(boleta.boletaId!));
    final dateFmt = DateFormat('dd/MM/yyyy');
    final fmt = NumberFormat('#,##0.00');
    final diasRestantes =
        boleta.fechaRetiro.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text('Boleta #${boleta.boletaId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Tarjeta resumen con urgencia ─────────────────────────
          _TarjetaResumen(
            boleta: boleta,
            diasRestantes: diasRestantes,
            dateFmt: dateFmt,
          ),
          const SizedBox(height: 12),

          // ── Equipos alquilados ───────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                            color: _verde,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Equipos alquilados',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                ),
                equiposAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('Sin equipos registrados.',
                            style:
                                TextStyle(color: Color(0xFF9E9E9E))),
                      );
                    }
                    final subtotal =
                        items.fold(0.0, (sum, e) => sum + e.total);
                    return Column(
                      children: [
                        ...items.map((e) => Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12, 4, 12, 0),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.construction_outlined,
                                      size: 18,
                                      color: Color(0xFF9E9E9E)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.nombreEquipo ??
                                              'Equipo #${e.numeroActivo}',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        Text(
                                          'Cant: ${e.cantidad}  ·  ${e.dias} días',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Color(0xFF9E9E9E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmt.format(e.total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )),
                        Container(
                          margin:
                              const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _fondoVerde,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal equipos',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _verdeOscuro)),
                              Text(fmt.format(subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _verdeOscuro)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Fotos del equipo ─────────────────────────────────────
          Container(
            width: double.infinity,
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
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Fotos del equipo',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                imagenesAsync.when(
                  data: (imgs) {
                    if (imgs.isEmpty) {
                      return const Text(
                        'Sin fotos registradas.',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: imgs.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imgs[i].urlImagen,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Acciones (solo boletas activas) ───────────────────────
          if (boleta.estado == EstadoBoleta.activa) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _verde,
                side: const BorderSide(color: _verde),
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Extender fecha de retiro',
                  style: TextStyle(fontSize: 15)),
              onPressed: () => _extenderFechaRetiro(context, ref),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _verdeOscuro,
                minimumSize: const Size(double.infinity, 52),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finalizar boleta y liberar equipos',
                  style: TextStyle(fontSize: 15)),
              onPressed: () => _confirmarFinalizacion(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _extenderFechaRetiro(
      BuildContext context, WidgetRef ref) async {
    final nueva = await showDatePicker(
      context: context,
      initialDate: boleta.fechaRetiro.add(const Duration(days: 1)),
      firstDate: boleta.fechaRetiro.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (nueva == null || !context.mounted) return;
    try {
      await ref
          .read(boletaRepositoryProvider)
          .extenderFechaRetiro(boleta.boletaId!, nueva);
      ref.invalidate(boletasActivasProvider);
      ref.invalidate(boletaListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fecha de retiro extendida al ${DateFormat('d/M/yyyy').format(nueva)}'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmarFinalizacion(
      BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Finalizar boleta'),
        content: const Text(
            'Se marcará la boleta como finalizada y todos los equipos '
            'volverán al estado disponible. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _verde),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      final boletaRepo = ref.read(boletaRepositoryProvider);
      final inventarioRepo = ref.read(inventarioRepositoryProvider);

      // 1. Marcar boleta como finalizada
      await boletaRepo.finalizar(boleta.boletaId!);

      // 2. Liberar equipos — consulta simple sin JOIN
      final numerosActivos =
          await boletaRepo.getNumeroActivos(boleta.boletaId!);
      for (final n in numerosActivos) {
        await inventarioRepo.updateEstado(
            n, EstadoInventario.disponible);
      }

      // 3. Cancelar notificaciones (solo Android; ignoramos error en otras plataformas)
      try {
        await NotificationService.cancelarAlertas(boleta.boletaId!);
      } catch (_) {}

      // 4. Refrescar listas
      ref.invalidate(boletasActivasProvider);
      ref.invalidate(boletaListProvider);
      ref.invalidate(inventarioListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Boleta finalizada. Equipos marcados como disponibles.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // Mostramos el error completo en un diálogo para poder diagnosticarlo
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Error al finalizar'),
            content: SingleChildScrollView(
              child: Text(e.toString()),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: _verde,
                    minimumSize: const Size(80, 40)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }
}

// ── Tarjeta resumen superior ──────────────────────────────────────────────────

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.boleta,
    required this.diasRestantes,
    required this.dateFmt,
  });

  final Boleta boleta;
  final int diasRestantes;
  final DateFormat dateFmt;

  Color get _color {
    if (diasRestantes < 0) return const Color(0xFFB71C1C);
    if (diasRestantes <= 1) return const Color(0xFFE65100);
    if (diasRestantes <= 7) return const Color(0xFFF9A825);
    return _verde;
  }

  String get _mensajeDias {
    if (diasRestantes < 0) return 'Vencido hace ${diasRestantes.abs()} días';
    if (diasRestantes == 0) return 'Vence hoy';
    if (diasRestantes == 1) return 'Vence mañana';
    return 'Vence en $diasRestantes días';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color, width: 2),
      ),
      child: Column(
        children: [
          // Franja de color superior
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        boleta.nombreEmpresaCliente,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mensajeDias,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (boleta.contacto != null) ...[
                  const SizedBox(height: 4),
                  Text(boleta.contacto!,
                      style: const TextStyle(
                          color: Color(0xFF757575), fontSize: 13)),
                ],
                const SizedBox(height: 10),
                _fila(Icons.phone_outlined, boleta.telefono),
                _fila(Icons.mail_outline, boleta.correo),
                _fila(
                  Icons.calendar_today_outlined,
                  '${dateFmt.format(boleta.fechaInicio)}  →  ${dateFmt.format(boleta.fechaRetiro)}',
                ),
                if (boleta.proformaId != null)
                  _fila(Icons.link_outlined,
                      'Proforma #${boleta.proformaId}'),
                if (boleta.observaciones != null)
                  _fila(Icons.notes_outlined, boleta.observaciones!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF555555))),
          ),
        ],
      ),
    );
  }
}
