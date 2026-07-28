import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_providers.dart';
import 'boleta_list_screen.dart';
import 'inventario_list_screen.dart';
import 'proforma_list_screen.dart';
import 'verificacion_screen.dart';

// Dorado de la marca — coincide con el tema
const _dorado = Color(0xFFFFBF00);
const _verdeOscuro = Color(0xFF1B5E20);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabActual = 0;

  static const _tabs = [
    InventarioListScreen(),
    ProformaListScreen(),
    BoletaListScreen(),
    VerificacionScreen(),
  ];

  static const _titles = [
    'Inventario',
    'Proformas',
    'Boletas',
    'Verificación',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Color viene del tema (verdeOscuro)
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo con borde blanco para visibilidad sobre verde
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'docs/logo llano verde.jpeg',
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 32,
                    width: 32,
                    color: _dorado,
                    child: const Icon(Icons.eco,
                        color: _verdeOscuro, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_tabActual],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Cerrar sesión'),
                  content:
                      const Text('¿Seguro que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 36)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (confirmar == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tabActual,
        children: _tabs,
      ),
      // NavigationBar: verde oscuro con íconos dorados seleccionados
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        backgroundColor: _verdeOscuro,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _dorado.withValues(alpha: 0.22),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.construction_outlined,
                color: Colors.white54),
            selectedIcon:
                Icon(Icons.construction, color: _dorado),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined,
                color: Colors.white54),
            selectedIcon:
                Icon(Icons.description, color: _dorado),
            label: 'Proformas',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined,
                color: Colors.white54),
            selectedIcon:
                Icon(Icons.assignment, color: _dorado),
            label: 'Boletas',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined,
                color: Colors.white54),
            selectedIcon:
                Icon(Icons.fact_check, color: _dorado),
            label: 'Verificar',
          ),
        ],
      ),
    );
  }
}
