import 'package:flutter/material.dart';

import 'shoe_form_screen.dart';
import 'stats_view.dart';
import 'stock_view.dart';

/// Coquille de l'application : onglets Stock / Statistiques + bouton Ajouter.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  Future<void> _addShoe() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Chaussure ajoutée au stock')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [StockView(), StatsView()],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _addShoe,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }
}
