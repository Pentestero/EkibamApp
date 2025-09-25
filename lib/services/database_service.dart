import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/supplier.dart';

/// A web-friendly persistence layer using SharedPreferences.
/// This service mimics a relational database structure to support the app's data model.
class DatabaseService {
  // Keys for storing data collections in SharedPreferences
  static const String _productsKey = 'db_products_v5';
  static const String _suppliersKey = 'db_suppliers_v5';
  static const String _requestersKey = 'db_requesters_v5';
  static const String _paymentMethodsKey = 'db_payment_methods_v5'; // New key for payment methods
  static const String _purchasesKey = 'db_purchases_v5';
  static const String _purchaseItemsKey = 'db_purchase_items_v5';
  static const String _seededKey = 'db_seeded_v6'; // Flag to check if db has been seeded

  // Singleton instance
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // Seeding data on first launch
  Future<void> _seedDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) return; // Already seeded

    // Seed Products
    final products = _getSeedProducts();
    await prefs.setString(_productsKey, json.encode(products.map((p) => p.toMap()).toList()));

    // Seed Suppliers
    final suppliers = _getSeedSuppliers();
    await prefs.setString(_suppliersKey, json.encode(suppliers.map((s) => s.toMap()).toList()));

    // Seed Requesters
    await prefs.setStringList(_requestersKey, _getSeedRequesters());

    // Seed Payment Methods
    await prefs.setStringList(_paymentMethodsKey, _getSeedPaymentMethods());

    await prefs.setBool(_seededKey, true);
  }

  // --- Data Access Methods ---

  Future<List<Product>> getProducts() async {
    await _seedDatabase(); // Ensure DB is seeded
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Supplier>> getSuppliers() async {
    await _seedDatabase(); // Ensure DB is seeded
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_suppliersKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<List<String>> getRequesters() async {
    await _seedDatabase(); // Ensure DB is seeded
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_requestersKey) ?? [];
  }

  Future<List<String>> getPaymentMethods() async {
    await _seedDatabase(); // Ensure DB is seeded
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_paymentMethodsKey) ?? [];
  }

  Future<Purchase> insertPurchase(Purchase purchase) async {
    final prefs = await SharedPreferences.getInstance();

    // Load current purchases and items
    final purchasesJson = prefs.getString(_purchasesKey) ?? '[]';
    final itemsJson = prefs.getString(_purchaseItemsKey) ?? '[]';
    final List<dynamic> purchaseList = json.decode(purchasesJson);
    final List<dynamic> itemList = json.decode(itemsJson);

    // --- Generate Request Number ---
    final now = DateTime.now();
    final datePrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    int dailyCounter = 1;
    for (final p in purchaseList.reversed) {
      final pDate = DateTime.fromMillisecondsSinceEpoch(p['createdAt']);
      if (pDate.year == now.year && pDate.month == now.month && pDate.day == now.day) {
        final pRequestNumber = p['requestNumber'] as String? ?? '';
        final parts = pRequestNumber.split('-');
        if (parts.length == 4) {
          dailyCounter = (int.tryParse(parts.last) ?? 0) + 1;
          break;
        }
      }
    }

    final requestNumber = '#EKA-$datePrefix-$dailyCounter';
    // --- End Generate Request Number ---

    final newPurchaseId = (purchaseList.isNotEmpty ? purchaseList.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1;
    
    final newPurchase = purchase.copyWith(
      id: newPurchaseId,
      requestNumber: requestNumber,
    );

    purchaseList.add(newPurchase.toMap());

    int newItemId = (itemList.isNotEmpty ? itemList.map((i) => i['id'] as int).reduce((a, b) => a > b ? a : b) : 0);
    for (final item in newPurchase.items) {
      newItemId++;
      final itemMap = item.toMap()
        ..['id'] = newItemId
        ..['purchaseId'] = newPurchaseId
        ..['paymentFee'] = item.paymentFee; // Include paymentFee
      itemList.add(itemMap);
    }

    await prefs.setString(_purchasesKey, json.encode(purchaseList));
    await prefs.setString(_purchaseItemsKey, json.encode(itemList));

    return newPurchase;
  }

  Future<Product> insertProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey) ?? '[]';
    final List<dynamic> productList = json.decode(jsonString);

    final newId = (productList.isNotEmpty
            ? productList.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b)
            : 0) +
        1;
    final newProduct = Product(
      id: newId,
      name: product.name,
      unit: product.unit,
      defaultPrice: product.defaultPrice,
    );

    productList.add(newProduct.toMap());
    await prefs.setString(_productsKey, json.encode(productList));
    return newProduct;
  }

  Future<Supplier> insertSupplier(Supplier supplier) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_suppliersKey) ?? '[]';
    final List<dynamic> supplierList = json.decode(jsonString);

    final newId = (supplierList.isNotEmpty
            ? supplierList.map((s) => s['id'] as int).reduce((a, b) => a > b ? a : b)
            : 0) +
        1;
    final newSupplier = Supplier(
      id: newId,
      name: supplier.name,
    );

    supplierList.add(newSupplier.toMap());
    await prefs.setString(_suppliersKey, json.encode(supplierList));
    return newSupplier;
  }

  Future<String> insertRequester(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final requesters = await getRequesters();
    if (!requesters.contains(name)) {
      requesters.add(name);
      await prefs.setStringList(_requestersKey, requesters);
    }
    return name;
  }

  Future<String> insertPaymentMethod(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentMethods = await getPaymentMethods();
    if (!paymentMethods.contains(name)) {
      paymentMethods.add(name);
      await prefs.setStringList(_paymentMethodsKey, paymentMethods);
    }
    return name;
  }

  Future<List<Purchase>> getAllPurchases() async {
    await _seedDatabase();
    final prefs = await SharedPreferences.getInstance();

    final purchasesJson = prefs.getString(_purchasesKey) ?? '[]';
    final itemsJson = prefs.getString(_purchaseItemsKey) ?? '[]';
    final List<dynamic> purchaseListJson = json.decode(purchasesJson);
    final List<dynamic> itemListJson = json.decode(itemsJson);

    if (purchaseListJson.isEmpty) return [];

    // For efficient lookup
    final products = await getProducts();
    final suppliers = await getSuppliers();
    final productMap = {for (var p in products) p.id: p};
    final supplierMap = {for (var s in suppliers) s.id: s};

    // Create a map of items by their purchaseId
    final Map<int, List<PurchaseItem>> itemsByPurchaseId = {};
    for (final itemMap in itemListJson) {
      final item = PurchaseItem.fromMap(itemMap).copyWith(
        productName: productMap[itemMap['productId']]?.name ?? 'N/A',
        supplierName: itemMap['supplierId'] != null ? supplierMap[itemMap['supplierId']]?.name ?? 'N/A' : 'Aucun',
      );
      (itemsByPurchaseId[item.purchaseId] ??= []).add(item);
    }

    // Build the final list of Purchase objects
    List<Purchase> purchases = [];
    for (final pMap in purchaseListJson) {
      final purchase = Purchase.fromMap(pMap);
      purchase.items = itemsByPurchaseId[purchase.id] ?? [];
      purchases.add(purchase);
    }
    
    // Sort by creation date descending
    purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return purchases;
  }

  Future<int> deletePurchase(int id) async {
    final prefs = await SharedPreferences.getInstance();

    final purchasesJson = prefs.getString(_purchasesKey) ?? '[]';
    final itemsJson = prefs.getString(_purchaseItemsKey) ?? '[]';
    List<dynamic> purchaseList = json.decode(purchasesJson);
    List<dynamic> itemList = json.decode(itemsJson);

    final initialLength = purchaseList.length;
    purchaseList.removeWhere((p) => p['id'] == id);
    itemList.removeWhere((i) => i['purchaseId'] == id);

    await prefs.setString(_purchasesKey, json.encode(purchaseList));
    await prefs.setString(_purchaseItemsKey, json.encode(itemList));

    return initialLength - purchaseList.length; // 1 if deleted, 0 if not found
  }

  Future<Purchase> updatePurchase(Purchase purchase) async {
    final prefs = await SharedPreferences.getInstance();

    // Load current purchases and items
    final purchasesJson = prefs.getString(_purchasesKey) ?? '[]';
    final itemsJson = prefs.getString(_purchaseItemsKey) ?? '[]';
    final List<dynamic> purchaseList = json.decode(purchasesJson);
    final List<dynamic> itemList = json.decode(itemsJson);

    // Find and update the purchase
    final purchaseIndex = purchaseList.indexWhere((p) => p['id'] == purchase.id);
    if (purchaseIndex != -1) {
      purchaseList[purchaseIndex] = purchase.toMap();
    } else {
      // Or should we insert if not found? For now, let's throw.
      throw Exception('Purchase with id ${purchase.id} not found for update.');
    }

    // Remove old items for this purchase
    itemList.removeWhere((item) => item['purchaseId'] == purchase.id);

    // Add new/updated items for this purchase, ensuring they have IDs
    int newItemId = (itemList.isNotEmpty ? itemList.map((i) => i['id'] as int).reduce((a, b) => a > b ? a : b) : 0);
    for (final item in purchase.items) {
      newItemId++;
      final itemMap = item.toMap()
        ..['id'] = newItemId
        ..['purchaseId'] = purchase.id
        ..['paymentFee'] = item.paymentFee; // Include paymentFee
      itemList.add(itemMap);
    }

    // Save back to SharedPreferences
    await prefs.setString(_purchasesKey, json.encode(purchaseList));
    await prefs.setString(_purchaseItemsKey, json.encode(itemList));

    return purchase;
  }

  // --- Analytics --- (These are now more expensive, but work)

  Future<Map<String, double>> getTotalBySupplier() async {
    final purchases = await getAllPurchases();
    final Map<String, double> totals = {};
    for (final p in purchases) {
      for (final item in p.items) {
        final supplierName = item.supplierId != null ? item.supplierName ?? 'N/A' : 'Aucun';
        totals[supplierName] = (totals[supplierName] ?? 0) + item.total;
      }
    }
    return totals;
  }

  Future<Map<String, double>> getTotalByProjectType() async {
    final purchases = await getAllPurchases();
    final Map<String, double> totals = {};
    for (final p in purchases) {
      totals[p.projectType] = (totals[p.projectType] ?? 0) + p.grandTotal;
    }
    return totals;
  }

  Future<Map<String, double>> getTotalByProduct() async {
    final purchases = await getAllPurchases();
    final Map<String, double> totals = {};
    for (final p in purchases) {
      for (final item in p.items) {
        final productName = item.productName ?? 'Autre';
        totals[productName] = (totals[productName] ?? 0) + item.total;
      }
    }
    return totals;
  }

  Future<double> getTotalSpent() async {
    final purchases = await getAllPurchases();
    return purchases.fold<double>(0.0, (sum, p) => sum + p.grandTotal);
  }

  Future<int> getTotalPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasesJson = prefs.getString(_purchasesKey) ?? '[]';
    return (json.decode(purchasesJson) as List).length;
  }

  // Temporary method to clear all data for debugging
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear ALL SharedPreferences data
    print('All SharedPreferences data cleared!');
  }

  // --- Seeding Data Definitions ---

  List<String> _getSeedRequesters() {
    return [
      'CET', 'Aurelien', 'Joseph', 'Cabrel', 'Marcel'
    ];
  }

  List<String> _getSeedPaymentMethods() {
    return [
      'Especes', 'MoMo', 'OM', 'Wave'
    ];
  }

  List<Product> _getSeedProducts() {
    int idCounter = 0;
    final Map<String, List<Map<String, dynamic>>> categorizedProducts = {
      'Matières premières - Bois & Panneaux': [
        {'name': 'Bois en planches', 'unit': 'pièce', 'price': 0},
        {'name': 'CP brut 18- 20 mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP brut 15 mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP brut 8-12 mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP stratifié 18-20mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP stratifié 15 mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP stratifié 8-12mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP stratifié - 4mm', 'unit': 'plaque', 'price': 0},
        {'name': 'CP MOE pour stratification', 'unit': 'plaque', 'price': 0},
      ],
      'Fournitures & Services Généraux': [
        {'name': 'Camtel', 'unit': 'facture', 'price': 0},
        {'name': 'ENEO', 'unit': 'facture', 'price': 0},
      ],
      'Transport & Déplacements': [
        {'name': 'Transport - Expédition marchandise', 'unit': 'course', 'price': 0},
        {'name': 'Transport - personnel en mission', 'unit': 'course', 'price': 0},
        {'name': 'Transport - Autre - voir commentaire', 'unit': 'course', 'price': 0},
        {'name': 'Carburant Véhicule', 'unit': 'L', 'price': 0},
        {'name': 'Carburant Hyster', 'unit': 'L', 'price': 0},
      ],
      'Frais de Mission': [
        {'name': 'Hebergement ou repas- personnel en mission', 'unit': 'jour', 'price': 0},
      ],
      'Maintenance & Entretien': [
        {'name': 'Consommables- Entretien Machine', 'unit': 'pièce', 'price': 0},
        {'name': 'Pièce détachée - Entretien Machine', 'unit': 'pièce', 'price': 0},
        {'name': 'MOE technicien - Entretien machine', 'unit': 'heure', 'price': 0},
      ],
      'Sous-traitance': [
        {'name': 'Indemnité sous traitant - voir commentaire', 'unit': 'forfait', 'price': 0},
      ],
      'Quincaillerie': [
        {'name': 'Quincaillerie Interne atelier', 'unit': 'pièce', 'price': 0},
        {'name': 'Quincaillerie - projet client - Voir commentaires', 'unit': 'pièce', 'price': 0},
      ],
      'Finitions': [
        {'name': 'Finitions - peinture', 'unit': 'L', 'price': 0},
        {'name': 'Finitions - Teintes', 'unit': 'L', 'price': 0},
        {'name': 'Finitions - vernis auto', 'unit': 'L', 'price': 0},
        {'name': 'Finitions - vernis cellulo', 'unit': 'L', 'price': 0},
        {'name': 'Finitions Ducco', 'unit': 'pièce', 'price': 0},
        {'name': 'Finitions - Diluant Cellulosique', 'unit': 'L', 'price': 0},
        {'name': 'Finitions - Diluant Nitro', 'unit': 'L', 'price': 0},
      ],
      'Atelier & Menuiserie': [
        {'name': 'EPI pour personnel', 'unit': 'pièce', 'price': 0},
        {'name': 'Menuiserie - colle rapide', 'unit': 'kg', 'price': 0},
        {'name': 'Menuiserie - Colle blanche', 'unit': 'kg', 'price': 0},
        {'name': 'Menuiserie - Affutage outils', 'unit': 'pièce', 'price': 0},
        {'name': 'Petit matériel technique - voir commentaires', 'unit': 'pièce', 'price': 0},
      ],
      'Fournitures de Bureau': [
        {'name': 'Bureautique - divers', 'unit': 'pièce', 'price': 0},
      ],
    };

    final List<Product> productList = [];
    categorizedProducts.forEach((category, products) {
      for (var p in products) {
        productList.add(Product(
          id: ++idCounter,
          name: '$category: ${p['name']}',
          unit: p['unit']! as String,
          defaultPrice: (p['price']! as num).toDouble(),
        ));
      }
    });
    // Sort alphabetically by name for better UX in dropdown
    productList.sort((a, b) => a.name.compareTo(b.name));
    return productList;
  }

  List<Supplier> _getSeedSuppliers() {
    int idCounter = 0;
    final suppliers = [
      'ENEO', 'CAMTEL', 'AGOGO', 'Quincaillerie EDEA', 
      'Quincaillerie Douala', 'Quincallerie Yaounde', 'Aucun'
    ];
    return suppliers.map((name) => Supplier(id: ++idCounter, name: name)).toList();
  }
}