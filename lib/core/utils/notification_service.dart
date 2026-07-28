import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/boleta.dart';

const _canalId = 'llano_verde_alertas';
const _canalNombre = 'Alertas de alquileres';
const _zona = 'America/Costa_Rica';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static Future<void> solicitarPermisos() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Programa las dos alertas de una boleta activa.
  // Se llama cada vez que se guarda o actualiza una boleta.
  static Future<void> programarAlertas(Boleta boleta) async {
    if (boleta.boletaId == null) return;
    await cancelarAlertas(boleta.boletaId!);
    if (boleta.estado != EstadoBoleta.activa) return;

    final ahora = DateTime.now();
    final fmt = DateFormat('d/M/yyyy');
    final location = tz.getLocation(_zona);

    // Alerta 7 días antes de fecha_retiro (devolución del cliente)
    final t1 = boleta.fechaRetiro.subtract(const Duration(days: 7));
    if (t1.isAfter(ahora)) {
      await _programar(
        id: boleta.boletaId! * 2,
        titulo: 'Devolucion de equipo en 7 dias',
        cuerpo:
            '${boleta.nombreEmpresaCliente} — vence ${fmt.format(boleta.fechaRetiro)}',
        cuando: tz.TZDateTime.from(t1, location),
      );
    }

    // Alerta 1 día antes de fecha_retiro (devolución del cliente)
    final t2 = boleta.fechaRetiro.subtract(const Duration(days: 1));
    if (t2.isAfter(ahora)) {
      await _programar(
        id: boleta.boletaId! * 2 + 1,
        titulo: 'Devolucion de equipo manana',
        cuerpo:
            '${boleta.nombreEmpresaCliente} — vence ${fmt.format(boleta.fechaRetiro)}',
        cuando: tz.TZDateTime.from(t2, location),
      );
    }
  }

  static Future<void> cancelarAlertas(int boletaId) async {
    await _plugin.cancel(boletaId * 2);
    await _plugin.cancel(boletaId * 2 + 1);
  }

  static Future<void> _programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required tz.TZDateTime cuando,
  }) async {
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      cuando,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNombre,
          channelDescription:
              'Alertas de vencimiento de alquileres Llano Verde',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
