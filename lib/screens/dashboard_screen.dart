import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/widgets/supplier_chart.dart';
import 'package:provisions/widgets/project_type_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/auth_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback navigateToHistory;
  const DashboardScreen({super.key, required this.navigateToHistory});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    
    return Scaffold(
      appBar: AppBar(
                title: Consumer<PurchaseProvider>(
          builder: (context, purchaseProvider, child) {
            final user = Provider.of<AuthService>(context, listen: false).currentUser;
            final userName = user?.userMetadata?['name'] ?? '';
            return Text('Bienvenue, $userName');
          },
        ),
                actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await AuthService.instance.signOut();
            },
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPurchases(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer, // Use theme color
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimaryContainer, // Use theme color
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                            children: [
                              Text(
                                'Gestion des approvisionnements',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer, // Use theme color
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Key metrics
                Row(
                  children: [
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Total Dépensé',
                        value: '${currencyFormat.format(provider.totalSpent)} FCFA',
                        icon: Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.secondary, // Use theme color
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Achats Totaux',
                        value: provider.totalPurchases.toString(),
                        icon: Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.tertiary, // Use theme color
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                

                const SizedBox(height: 24),

                // Charts section
                if (provider.supplierTotals.isNotEmpty) ...[
                  Text(
                    'Répartition par Fournisseur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: SupplierChart(data: provider.supplierTotals),
                  ),
                  
                  const SizedBox(height: 24),
                ],

                if (provider.projectTypeTotals.isNotEmpty) ...[
                  Text(
                    'Répartition par Type de Projet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ProjectTypeChart(data: provider.projectTypeTotals),
                  ),
                  
                  const SizedBox(height: 24),
                ],

                // Recent purchases
                if (provider.purchases.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Achats Récents',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: navigateToHistory,
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...provider.purchases.take(2).map((purchase) => Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest, // Use theme color
                    margin: const EdgeInsets.symmetric(vertical: 6), // Add vertical margin
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Use theme color
                        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Use theme color
                        child: const Icon(Icons.shopping_cart),
                      ),
                      title: Text(
                        '${purchase.requestNumber ?? 'Achat'} de ${purchase.items.length} article(s)',
                        style: Theme.of(context).textTheme.titleMedium, // Use theme text style
                      ),
                      subtitle: Text(
                        'Demandeur: ${purchase.owner} • Projet: ${purchase.projectType}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, // Use theme color
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${currencyFormat.format(purchase.grandTotal)} FCFA',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary, // Use theme color
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(purchase.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )),
                ],

                if (provider.purchases.isEmpty)
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest, // Use theme color
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun achat enregistré',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par ajouter votre premier achat',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
