
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/supplier.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // --- Key Generation ---
  String _purchasesKey(String userId) => 'user_purchases_$userId';
  String _productsKey(String userId) => 'user_products_$userId';
  String _suppliersKey(String userId) => 'user_suppliers_$userId';
  String _requestersKey(String userId) => 'user_requesters_$userId';
  String _paymentMethodsKey(String userId) => 'user_payment_methods_$userId';
  String _seededKey(String userId) => 'user_seeded_$userId';

  Future<void> _seedDatabase(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey(userId)) ?? false) return;

    await prefs.setString(_productsKey(userId), json.encode(_getSeedProducts().map((p) => p.toMap()).toList()));
    await prefs.setString(_suppliersKey(userId), json.encode(_getSeedSuppliers().map((s) => s.toMap()).toList()));
    await prefs.setStringList(_requestersKey(userId), _getSeedRequesters());
    await prefs.setStringList(_paymentMethodsKey(userId), _getSeedPaymentMethods());
    await prefs.setBool(_seededKey(userId), true);
  }

  // --- Data Access Methods ---

  Future<List<Product>> getProducts(String userId) async {
    await _seedDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey(userId)) ?? '[]';
    return (json.decode(jsonString) as List).map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Supplier>> getSuppliers(String userId) async {
    await _seedDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_suppliersKey(userId)) ?? '[]';
    return (json.decode(jsonString) as List).map((map) => Supplier.fromMap(map)).toList();
  }

  Future<List<String>> getRequesters(String userId) async {
    await _seedDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_requestersKey(userId)) ?? [];
  }

  Future<List<String>> getPaymentMethods(String userId) async {
    await _seedDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_paymentMethodsKey(userId)) ?? [];
  }

  Future<List<Purchase>> getAllPurchases(String userId) async {
    await _seedDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_purchasesKey(userId)) ?? '[]';
    final List<dynamic> purchaseListJson = json.decode(jsonString);

    if (purchaseListJson.isEmpty) return [];

    final products = await getProducts(userId);
    final suppliers = await getSuppliers(userId);
    final productMap = {for (var p in products) p.id: p};
    final supplierMap = {for (var s in suppliers) s.id: s};

    List<Purchase> purchases = purchaseListJson.map((pMap) {
      final purchase = Purchase.fromMap(pMap);
      purchase.items = (pMap['items'] as List).map((itemMap) {
        final item = PurchaseItem.fromMap(itemMap);
        return item.copyWith(
          productName: productMap[item.productId]?.name ?? 'N/A',
          supplierName: supplierMap[item.supplierId]?.name ?? 'N/A',
        );
      }).toList();
      return purchase;
    }).toList();

    purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return purchases;
  }

  Future<void> saveAllPurchases(String userId, List<Purchase> purchases) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> purchaseList = purchases.map((p) => p.toMapWithItems()).toList();
    await prefs.setString(_purchasesKey(userId), json.encode(purchaseList));
  }
  
  Future<Product> insertProduct(String userId, Product product) async {
    final products = await getProducts(userId);
    final newId = (products.isNotEmpty ? products.map((p) => p.id!).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final newProduct = product.copyWith(id: newId);
    products.add(newProduct);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey(userId), json.encode(products.map((p) => p.toMap()).toList()));
    return newProduct;
  }

  Future<Supplier> insertSupplier(String userId, Supplier supplier) async {
    final suppliers = await getSuppliers(userId);
    final newId = (suppliers.isNotEmpty ? suppliers.map((s) => s.id!).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final newSupplier = supplier.copyWith(id: newId);
    suppliers.add(newSupplier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_suppliersKey(userId), json.encode(suppliers.map((s) => s.toMap()).toList()));
    return newSupplier;
  }

  Future<String> insertRequester(String userId, String name) async {
    final requesters = await getRequesters(userId);
    if (!requesters.contains(name)) {
      requesters.add(name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_requestersKey(userId), requesters);
    }
    return name;
  }

  Future<String> insertPaymentMethod(String userId, String name) async {
    final paymentMethods = await getPaymentMethods(userId);
    if (!paymentMethods.contains(name)) {
      paymentMethods.add(name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_paymentMethodsKey(userId), paymentMethods);
    }
    return name;
  }

  // --- Seeding Data Definitions (same as before) ---
  List<String> _getSeedRequesters() => ['CET', 'Aurelien', 'Joseph', 'Cabrel', 'Marcel'];
  List<String> _getSeedPaymentMethods() => ['Especes', 'MoMo', 'OM', 'Wave'];
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
    productList.sort((a, b) => a.name.compareTo(b.name));
    return productList;
  }

  List<Supplier> _getSeedSuppliers() {
    int idCounter = 0;
    final suppliers = ['ENEO', 'CAMTEL', 'AGOGO', 'Quincaillerie EDEA', 'Quincaillerie Douala', 'Quincallerie Yaounde', 'Aucun'];
    return suppliers.map((name) => Supplier(id: ++idCounter, name: name)).toList();
  }
}
