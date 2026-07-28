import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/notification_service.dart';
import 'data/supabase/supabase_client.dart';
import 'presentation/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseClientConfig.initialize();
  await NotificationService.inicializar();
  await NotificationService.solicitarPermisos();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llano Verde',
      debugShowCheckedModeBanner: false,
      theme: _tema(),
      home: const AuthGate(),
    );
  }

  ThemeData _tema() {
    // Paleta: verde bosque + dorado cálido
    const verdeOscuro = Color(0xFF1B5E20);
    const verde = Color(0xFF2E7D32);
    const dorado = Color(0xFFFFBF00);
    const fondo = Color(0xFFF5F3EE); // crema cálido

    final cs = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: Brightness.light,
    ).copyWith(
      primary: verde,
      surface: Colors.white,
      surfaceContainerHighest: fondo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: fondo,

      // AppBar verde con texto blanco
      appBarTheme: const AppBarTheme(
        backgroundColor: verdeOscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards blancos, bordes redondeados
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Campos con relleno suave
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEECE6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: verde, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      ),

      // Botón principal verde — sin ancho forzado para no romper Rows
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // FAB dorado — ícono oscuro para contraste
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: dorado,
        foregroundColor: Color(0xFF1A3A00),
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8E4DA),
        thickness: 1,
        space: 1,
      ),

      // Barra de navegación: verde oscuro + dorado seleccionado
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: verdeOscuro,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black45,
        elevation: 8,
        indicatorColor: dorado.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            color: sel ? dorado : Colors.white60,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? dorado : Colors.white60,
            size: 24,
          );
        }),
      ),
    );
  }
}
