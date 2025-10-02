import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/widgets/supplier_chart.dart';
import 'package:provisions/widgets/project_type_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/auth_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    
    return Scaffold(
      appBar: AppBar(
                title: Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            final userName = AuthService.instance.currentUser?.name ?? '';
            return Text('Bienvenue, $userName');
          },
        ),
                actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Supprimer le compte',
            onPressed: () => _confirmDeleteAccount(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PurchaseProvider>().loadPurchases();
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              context.read<PurchaseProvider>().exportToExcel();
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.handyman,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                            children: [
                              Text(
                                'Gestion des approvisionnements',
                                style: Theme.of(context).textTheme.headlineSmall,
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
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Achats Totaux',
                        value: provider.totalPurchases.toString(),
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
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
                        onPressed: () {
                          // Note: Navigation to history will be handled by bottom nav
                        },
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...provider.purchases.take(3).map((purchase) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.shopping_cart),
                      ),
                      title: Text('${purchase.requestNumber ?? 'Achat'} de ${purchase.items.length} article(s)'),
                      subtitle: Text('Demandeur: ${purchase.owner} • Projet: ${purchase.projectType}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${currencyFormat.format(purchase.grandTotal)} FCFA',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le compte ?'),
          content: const Text('Cette action est irréversible. Toutes les données associées à ce compte seront définitivement perdues. Êtes-vous sûr ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () async {
                await AuthService.instance.deleteCurrentUser();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}