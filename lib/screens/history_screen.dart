

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/screens/purchase_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tous';
  late List<String> _filterOptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
    _filterOptions = ['Tous', 'Cette semaine', 'Ce mois'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        actions: [
          _buildFilterMenu(),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => context.read<PurchaseProvider>().exportToExcel(),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.purchases.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(context, provider);
          }

          final filteredPurchases = _getFilteredPurchases(provider.purchases);

          if (filteredPurchases.isEmpty) {
            return _buildEmptyStateWidget(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPurchases(),
            child: Column(
              children: [
                _buildSummaryHeader(context, filteredPurchases),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredPurchases.length,
                    itemBuilder: (context, index) {
                      final purchase = filteredPurchases[index];
                      return PurchaseExpansionCard(purchase: purchase);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PopupMenuButton<String> _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() => _selectedFilter = value),
      itemBuilder: (context) => _filterOptions.map((option) => PopupMenuItem(
        value: option,
        child: Text(option, style: TextStyle(fontWeight: _selectedFilter == option ? FontWeight.bold : FontWeight.normal)),
      )).toList(),
    );
  }

  Widget _buildErrorWidget(BuildContext context, PurchaseProvider provider) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 64, color: Colors.red),
      const SizedBox(height: 16), Text(provider.errorMessage, textAlign: TextAlign.center),
      const SizedBox(height: 16), ElevatedButton(onPressed: () => provider.loadPurchases(), child: const Text('Réessayer')),
    ]));
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.history, size: 64, color: Colors.grey),
      const SizedBox(height: 16), Text(_selectedFilter == 'Tous' ? 'Aucun achat enregistré' : 'Aucun achat pour ce filtre'),
    ]));
  }

  Container _buildSummaryHeader(BuildContext context, List<Purchase> purchases) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface.withAlpha(100),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Filtre: $_selectedFilter (${purchases.length})'),
        Text('Total: ${NumberFormat('#,##0', 'fr_FR').format(_getTotalAmount(purchases))} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  List<Purchase> _getFilteredPurchases(List<Purchase> purchases) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Cette semaine':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return purchases.where((p) => p.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
      case 'Ce mois':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return purchases.where((p) => p.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
      default:
        return purchases;
    }
  }

  double _getTotalAmount(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, p) => sum + p.grandTotal);
  }
}

class PurchaseExpansionCard extends StatelessWidget {
  final Purchase purchase;
  const PurchaseExpansionCard({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PurchaseProvider>();
    final formattedDate = DateFormat('dd/MM/yyyy').format(purchase.date);
    final totalItems = purchase.items.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(purchase.requestNumber ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Demandeur: ${purchase.owner} • Projet: ${purchase.projectType}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,##0.00', 'fr_FR').format(purchase.grandTotal)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text('$totalItems article(s) • $formattedDate'),
          ],
        ),
        children: [
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...purchase.items.map((item) {
                  final itemSubtotal = item.quantity * item.unitPrice;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName ?? 'Produit inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (item.supplierName != null && item.supplierName != 'N/A')
                          Text('Fournisseur: ${item.supplierName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${NumberFormat('#,##0.00', 'fr_FR').format(item.quantity)} x ${NumberFormat('#,##0.00', 'fr_FR').format(item.unitPrice)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,##0.00', 'fr_FR').format(itemSubtotal)} FCFA',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (item.paymentFee > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Frais de paiement:', style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                              Text(
                                '+ ${NumberFormat('#,##0.00', 'fr_FR').format(item.paymentFee)} FCFA',
                                style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        const Divider(height: 8),
                      ],
                    ),
                  );
                }).toList(),

                if (purchase.totalPaymentFees > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Frais de paiement totaux', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${NumberFormat('#,##0.00', 'fr_FR').format(purchase.totalPaymentFees)} FCFA',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                        ),
                      ],
                    ),
                  ),

                if (purchase.comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Commentaires: ${purchase.comments}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchaseFormScreen(purchase: purchase),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _showDeleteDialog(context, provider, purchase),
              ),
            ],
          )
        ],
      ),
    );
  }
}

void _showDeleteDialog(BuildContext context, PurchaseProvider provider, Purchase purchase) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer l\'achat'),
      content: Text('Êtes-vous sûr de vouloir supprimer cet achat du ${DateFormat('dd/MM/yyyy').format(purchase.date)} ? Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
            provider.deletePurchase(purchase.id!);
          },
        ),
      ],
    ),
  );
}