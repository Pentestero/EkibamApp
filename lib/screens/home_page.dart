import 'package:flutter/material.dart';
import 'package:provisions/screens/dashboard_screen.dart';
import 'package:provisions/screens/purchase_form_screen.dart';
import 'package:provisions/screens/history_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PurchaseFormScreen(),
    const HistoryScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard),
      label: 'Tableau de bord',
    ),
    const NavigationDestination(
      icon: Icon(Icons.add_shopping_cart),
      label: 'Nouvel Achat',
    ),
    const NavigationDestination(
      icon: Icon(Icons.history),
      label: 'Historique',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}