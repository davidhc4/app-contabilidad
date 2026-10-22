import 'package:flutter/material.dart';

import '../../features/cards/cards_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import 'soft_nav_bar.dart';

/// Pestañas principales de la app. Se puede cambiar de sección tocando la
/// barra de abajo o deslizando el dedo hacia los lados sobre la pantalla.
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  final _pageController = PageController();
  int _index = 0;

  // Cada pestaña conserva su estado (búsqueda, scroll) al deslizar.
  static const _screens = [
    _KeepAlive(child: DashboardScreen()),
    _KeepAlive(child: CardsScreen()),
    _KeepAlive(child: StatisticsScreen()),
    _KeepAlive(child: TransactionsScreen()),
    _KeepAlive(child: CategoriesScreen()),
    _KeepAlive(child: SettingsScreen()),
  ];

  static const _items = [
    SoftNavItem(
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
      label: 'Resumen',
    ),
    SoftNavItem(
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      label: 'Tarjetas',
    ),
    SoftNavItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Gráficas',
    ),
    SoftNavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'Historial',
    ),
    SoftNavItem(
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
      label: 'Categorías',
    ),
    SoftNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Ajustes',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _animating = false;

  Future<void> _goTo(int index) async {
    if (index == _index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
    // Mientras dura la animación se ignoran los avisos de las pestañas
    // intermedias, para que el indicador no parpadee.
    _animating = true;
    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _animating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // El botón "atrás" del celular regresa a Resumen antes de cerrar la app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          // Se puede deslizar hacia los lados para cambiar de sección.
          onPageChanged: (i) {
            if (_animating) return;
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _index = i);
          },
          children: _screens,
        ),
        bottomNavigationBar: SoftNavBar(
          selectedIndex: _index,
          onSelected: _goTo,
          items: _items,
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
