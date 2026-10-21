import 'package:flutter/material.dart';

import '../../features/categories/categories_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/transactions/transactions_screen.dart';

/// Pestañas principales de la app con animación direccional: si vas a una
/// pestaña a la derecha, el contenido entra deslizándose desde la derecha;
/// si vas a una a la izquierda, entra desde la izquierda. Igual que en
/// cualquier app con pestañas en la parte inferior (estilo iOS/Android).
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  final _pageController = PageController();
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    TransactionsScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        // El usuario cambia de pestaña tocando la barra de abajo, no
        // deslizando (eso se reserva para gestos dentro de cada pantalla,
        // como borrar un movimiento deslizando hacia un lado).
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
