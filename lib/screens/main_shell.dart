import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Estrutura com as 4 abas (igual ao iFood): Início, Busca, Pedidos e Perfil.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Aba atual. Outras telas podem trocar de aba: `MainShell.tab.value = 1`.
  static final tab = ValueNotifier<int>(0);

  static const homeTab = 0;
  static const searchTab = 1;
  static const ordersTab = 2;
  static const profileTab = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainShell.tab.value = MainShell.homeTab;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.tab,
      builder: (context, index, _) => PopScope(
        // No Android, "voltar" numa aba leva para o Início antes de sair.
        canPop: index == MainShell.homeTab,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) MainShell.tab.value = MainShell.homeTab;
        },
        child: Scaffold(
          body: IndexedStack(index: index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => MainShell.tab.value = i,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.manage_search_rounded),
                label: 'Busca',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Pedidos',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
