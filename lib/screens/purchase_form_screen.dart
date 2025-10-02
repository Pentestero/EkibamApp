import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:intl/intl.dart';

class PurchaseFormScreen extends StatefulWidget {
  final Purchase? purchase; // Optional purchase for editing
  const PurchaseFormScreen({super.key, this.purchase});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseProvider>();
      if (widget.purchase != null) {
        provider.loadPurchaseForEditing(widget.purchase!);
      } else {
        provider.clearForm(); // Ensure form is clear for new purchase
      }
      provider.initialize(); 
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  void _showAddRequesterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: _AddRequesterDialog(),
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: _AddPaymentMethodDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return Text(provider.isEditing ? 'Modifier l\'achat' : 'Nouvel Achat');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PurchaseProvider>().clearForm();
              _commentsController.clear();
            },
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (_commentsController.text != provider.purchaseBuilder.comments) {
            _commentsController.text = provider.purchaseBuilder.comments;
          }

          if (provider.isLoading && provider.requesters.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context, provider),
                  const SizedBox(height: 24),
                  _buildItemsSection(context, provider),
                  const SizedBox(height: 24),
                  _buildTotalsCard(context, provider),
                  const SizedBox(height: 32),
                  _buildSubmitButton(context, provider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PurchaseProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Générales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date de l\'achat'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(provider.purchaseBuilder.date)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _selectDate(context, provider),
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: provider.requesters.contains(provider.purchaseBuilder.owner) 
                        ? provider.purchaseBuilder.owner 
                        : null,
                    decoration: const InputDecoration(labelText: 'Demandeur', prefixIcon: Icon(Icons.person)),
                    items: provider.requesters.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (value) => provider.updatePurchaseHeader(owner: value),
                    validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Créer un nouveau demandeur',
                  onPressed: _showAddRequesterDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: provider.purchaseBuilder.projectType,
              decoration: const InputDecoration(labelText: 'Type de Projet', prefixIcon: Icon(Icons.work)),
              items: provider.projectTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) => provider.updatePurchaseHeader(projectType: value),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: provider.paymentMethods.contains(provider.purchaseBuilder.paymentMethod)
                        ? provider.purchaseBuilder.paymentMethod
                        : null,
                    decoration: const InputDecoration(labelText: 'Mode de paiement', prefixIcon: Icon(Icons.payment)),
                    items: provider.paymentMethods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (value) => provider.updatePurchaseHeader(paymentMethod: value),
                    validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Créer un nouveau mode de paiement',
                  onPressed: _showAddPaymentMethodDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(labelText: 'Commentaires (optionnel)', prefixIcon: Icon(Icons.comment)),
              onChanged: (value) => provider.updatePurchaseHeader(comments: value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, PurchaseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Articles', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (provider.itemsBuilder.isEmpty)
          const Center(child: Text('Appuyez sur "Ajouter un article" pour commencer.')),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.itemsBuilder.length,
          itemBuilder: (context, index) {
            return _PurchaseItemCard(index: index);
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: provider.addNewItem,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un article'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(BuildContext context, PurchaseProvider provider) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Sous-total des articles', style: Theme.of(context).textTheme.titleMedium)),
                Expanded(
                  child: Text(
                    '${NumberFormat('#,##0.00', 'fr_FR').format(provider.grandTotalBuilder - provider.purchaseBuilder.totalPaymentFees)} FCFA',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (provider.purchaseBuilder.totalPaymentFees > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Frais de paiement totaux', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange[700]))),
                    Expanded(
                      child: Text(
                        '${NumberFormat('#,##0.00', 'fr_FR').format(provider.purchaseBuilder.totalPaymentFees)} FCFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange[700]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('GRAND TOTAL', style: Theme.of(context).textTheme.titleLarge)),
                Expanded(
                  child: Text(
                    '${NumberFormat('#,##0.00', 'fr_FR').format(provider.grandTotalBuilder)} FCFA',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, PurchaseProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.isLoading ? null : () => _submitForm(context, provider),
        icon: provider.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(provider.isLoading
            ? 'Enregistrement...'
            : (provider.isEditing ? 'Mettre à jour l\'achat' : 'Enregistrer l\'Achat')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, PurchaseProvider provider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: provider.purchaseBuilder.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      provider.updatePurchaseHeader(date: date);
    }
  }

  Future<void> _submitForm(BuildContext context, PurchaseProvider provider) async {
    if (!(_formKey.currentState?.validate() ?? false) || provider.itemsBuilder.isEmpty) {
      if (provider.itemsBuilder.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins un article.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer l\'enregistrement'),
          content: const Text('Êtes-vous sûr de vouloir enregistrer cet achat ? Veuillez vérifier que toutes les informations sont correctes.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Purchase? resultPurchase;
      if (provider.isEditing) {
        resultPurchase = await provider.updatePurchase();
      } else {
        resultPurchase = await provider.addPurchase();
      }

      if (!mounted) return;
      if (resultPurchase != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Achat enregistré avec succès ! N°: ${resultPurchase.requestNumber}'),
              backgroundColor: Colors.green),
        );
        // If editing, pop back to history screen
        if (provider.isEditing) {
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${provider.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PurchaseItemCard extends StatefulWidget {
  final int index;
  const _PurchaseItemCard({required this.index});

  @override
  State<_PurchaseItemCard> createState() => _PurchaseItemCardState();
}

class _PurchaseItemCardState extends State<_PurchaseItemCard> {
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final item = context.read<PurchaseProvider>().itemsBuilder[widget.index];
    _quantityController = TextEditingController(text: item.quantity.toString());
    _priceController = TextEditingController(text: item.unitPrice.toString());
    _commentController = TextEditingController(text: item.comment);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PurchaseItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = context.read<PurchaseProvider>().itemsBuilder[widget.index];
    if (_quantityController.text != item.quantity.toString()) {
      _quantityController.text = item.quantity.toString();
    }
    if (_priceController.text != item.unitPrice.toString()) {
      _priceController.text = item.unitPrice.toString();
    }
    if (_commentController.text != item.comment) {
      _commentController.text = item.comment ?? '';
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: _AddProductDialog(),
        );
      },
    ).then((newProduct) {
      if (newProduct != null && newProduct is Product) {
        context.read<PurchaseProvider>().updateItem(widget.index, productId: newProduct.id);
      }
    });
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: _AddSupplierDialog(),
        );
      },
    ).then((newSupplier) {
      if (newSupplier != null && newSupplier is Supplier) {
        context.read<PurchaseProvider>().updateItem(widget.index, supplierId: newSupplier.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];
    final product = provider.products.firstWhere((p) => p.id == item.productId, orElse: () => provider.products.first);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Article #${widget.index + 1}', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => provider.removeItem(widget.index),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: item.productId,
                    decoration: const InputDecoration(labelText: 'Produit'),
                    items: provider.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateItem(widget.index, productId: value);
                      }
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Créer un nouveau produit',
                  onPressed: _showAddProductDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: item.supplierId,
                    decoration: const InputDecoration(labelText: 'Fournisseur'),
                    items: provider.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateItem(widget.index, supplierId: value);
                      }
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Créer un nouveau fournisseur',
                  onPressed: _showAddSupplierDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantité', suffixText: product.unit),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]+'))],
                    onChanged: (value) {
                      final qty = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                      provider.updateItem(widget.index, quantity: qty);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Prix Unitaire', suffixText: 'FCFA'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]+'))],
                    onChanged: (value) {
                      final price = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                      provider.updateItem(widget.index, unitPrice: price);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Commentaire (optionnel)', prefixIcon: Icon(Icons.comment)),
              onChanged: (value) {
                provider.updateItemComment(widget.index, value);
              },
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Sous-total (HT):',
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${NumberFormat('#,##0', 'fr_FR').format(item.quantity * item.unitPrice)} FCFA',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.paymentFee > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Frais de paiement:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${NumberFormat('#,##0.00', 'fr_FR').format(item.paymentFee)} FCFA',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange[700]),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Total Article:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${NumberFormat('#,##0.00', 'fr_FR').format(item.total)} FCFA',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Dialog for adding a new requester
class _AddRequesterDialog extends StatefulWidget {
  @override
  __AddRequesterDialogState createState() => __AddRequesterDialogState();
}

class __AddRequesterDialogState extends State<_AddRequesterDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un nouveau demandeur'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Nom du demandeur'),
          onSaved: (value) => _name = value ?? '',
          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await context.read<PurchaseProvider>().addNewRequester(name: _name);
              if (mounted) Navigator.of(context).pop();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// Dialog for adding a new Payment Method
class _AddPaymentMethodDialog extends StatefulWidget {
  @override
  __AddPaymentMethodDialogState createState() => __AddPaymentMethodDialogState();
}

class __AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un nouveau mode de paiement'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Nom du mode de paiement'),
          onSaved: (value) => _name = value ?? '',
          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await context.read<PurchaseProvider>().addNewPaymentMethod(name: _name);
              if (mounted) Navigator.of(context).pop();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}


// Dialog for adding a new product
class _AddProductDialog extends StatefulWidget {
  @override
  __AddProductDialogState createState() => __AddProductDialogState();
}

class __AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  String _category = '';
  String _name = '';
  String _unit = '';
  double _defaultPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PurchaseProvider>();
    final categories = provider.products.map((p) {
      final parts = p.name.split(':');
      return parts.length > 1 ? parts.first.trim() : 'Autres';
    }).toSet().toList();
    if (_category.isEmpty && categories.isNotEmpty) {
      _category = categories.first;
    }

    return AlertDialog(
      title: const Text('Créer un nouveau produit'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                onSaved: (value) => _name = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Unité (ex: pièce, kg, L)'),
                onSaved: (value) => _unit = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prix par défaut (optionnel)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]+'))],
                onSaved: (value) => _defaultPrice = double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0.0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final newProduct = await provider.addNewProduct(
                category: _category,
                name: _name,
                unit: _unit,
                defaultPrice: _defaultPrice,
              );
              Navigator.of(context).pop(newProduct);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// Dialog for adding a new supplier
class _AddSupplierDialog extends StatefulWidget {
  @override
  __AddSupplierDialogState createState() => __AddSupplierDialogState();
}

class __AddSupplierDialogState extends State<_AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PurchaseProvider>();

    return AlertDialog(
      title: const Text('Créer un nouveau fournisseur'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Nom du fournisseur'),
          onSaved: (value) => _name = value ?? '',
          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final newSupplier = await provider.addNewSupplier(name: _name);
              Navigator.of(context).pop(newSupplier);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}