import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_providers.dart';
import 'boleta_list_screen.dart';
import 'inventario_list_screen.dart';
import 'proforma_list_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabActual = 0;

  final _tabs = const [
    InventarioListScreen(),
    ProformaListScreen(),
    BoletaListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Llano Verde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabActual,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabActual,
        onTap: (index) => setState(() => _tabActual = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Proformas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Boletas',
          ),
        ],
      ),
    );
  }
}
