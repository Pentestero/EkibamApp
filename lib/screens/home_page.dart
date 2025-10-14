import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/screens/dashboard_screen.dart';
import 'package:provisions/screens/purchase_form_screen.dart';
import 'package:provisions/screens/history_screen.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(navigateToHistory: () => _navigateTo(2)),
      const PurchaseFormScreen(),
      const HistoryScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the provider with the user from the widget.
      context.read<PurchaseProvider>().initialize(widget.user);
    });
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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