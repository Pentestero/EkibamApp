import 'package:flutter/material.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/services/excel_service.dart';

// Constants for dropdowns that are still static
const List<String> _projectTypes = ['Client', 'Interne', 'Mixte'];

// Configurable payment fee percentages
const Map<String, Map<String, double>> _paymentFeePercentages = {
  'MoMo': {'percentage': 0.015, 'fixed': 4.0}, // 1.5% + 4frs
  'OM': {'percentage': 0.015, 'fixed': 4.0},   // 1.5% + 4frs
  'Wave': {'percentage': 0.01, 'fixed': 0.0},  // 1%
  'Especes': {'percentage': 0.0, 'fixed': 0.0}, // 0%
  'Aucun': {'percentage': 0.0, 'fixed': 0.0},   // 0%
  // Add other payment methods here with their respective fees
};

class PurchaseProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  // Data lists
  List<Purchase> _purchases = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  List<String> _requesters = [];
  List<String> _paymentMethods = [];

  // State
  bool _isLoading = false;
  String _errorMessage = '';
  int? _editingPurchaseId;

  // Analytics data
  Map<String, double> _supplierTotals = {};
  Map<String, double> _projectTypeTotals = {};
  Map<String, double> _productTotals = {};
  double _totalSpent = 0;
  int _totalPurchases = 0;

  // Form state
  Purchase _purchaseBuilder = Purchase(
    date: DateTime.now(),
    owner: '', // Will be set after requesters are loaded
    projectType: _projectTypes.first,
    paymentMethod: '', // Will be set after payment methods are loaded
    createdAt: DateTime.now(),
  );
  List<PurchaseItem> _itemsBuilder = [];

  // Getters
  List<Purchase> get purchases => _purchases;
  List<Product> get products => _products;
  List<Supplier> get suppliers => _suppliers;
  List<String> get requesters => _requesters;
  List<String> get projectTypes => _projectTypes;
  List<String> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isEditing => _editingPurchaseId != null;

  List<String> get productCategories {
    final categories = _products.map((p) {
      final parts = p.name.split(':');
      return parts.length > 1 ? parts.first.trim() : 'Autres';
    }).toSet().toList();
    categories.sort();
    return categories;
  }

  Map<String, double> get supplierTotals => _supplierTotals;
  Map<String, double> get projectTypeTotals => _projectTypeTotals;
  Map<String, double> get productTotals => _productTotals;
  double get totalSpent => _totalSpent;
  int get totalPurchases => _totalPurchases;

  // Form getters
  Purchase get purchaseBuilder => _purchaseBuilder;
  List<PurchaseItem> get itemsBuilder => _itemsBuilder;
  double get grandTotalBuilder => _itemsBuilder.fold(0.0, (sum, item) => sum + item.total);

  // Initializer
  Future<void> initialize() async {
    _setLoading(true);
    await Future.wait([
      loadPurchases(),
      _loadProducts(),
      _loadSuppliers(),
      _loadRequesters(),
      _loadPaymentMethods(),
    ]);
    
    if (_requesters.isNotEmpty && _purchaseBuilder.owner.isEmpty) {
      _purchaseBuilder = _purchaseBuilder.copyWith(owner: _requesters.first);
    }
    if (_paymentMethods.isNotEmpty && _purchaseBuilder.paymentMethod.isEmpty) {
      _purchaseBuilder = _purchaseBuilder.copyWith(paymentMethod: _paymentMethods.first);
    }

    _setLoading(false);
  }

  // Form state management
  void loadPurchaseForEditing(Purchase purchase) {
    _editingPurchaseId = purchase.id;
    _purchaseBuilder = purchase.copyWith();
    _itemsBuilder = List<PurchaseItem>.from(purchase.items.map((item) => item.copyWith()));
    notifyListeners();
  }

  void updatePurchaseHeader({
    DateTime? date,
    String? owner,
    String? projectType,
    String? paymentMethod,
    String? comments,
  }) {
    _purchaseBuilder = _purchaseBuilder.copyWith(
      date: date,
      owner: owner,
      projectType: projectType,
      paymentMethod: paymentMethod,
      comments: comments,
    );
    // Recalculate fees if payment method changes
    if (paymentMethod != null) {
      _recalculateAllItemFees();
    }
    notifyListeners();
  }

  void _recalculateAllItemFees() {
    final currentPaymentMethod = _purchaseBuilder.paymentMethod;
    final feeConfig = _paymentFeePercentages[currentPaymentMethod] ?? {'percentage': 0.0, 'fixed': 0.0};
    final feePercentage = feeConfig['percentage']!;
    final fixedFee = feeConfig['fixed']!;

    for (int i = 0; i < _itemsBuilder.length; i++) {
      final item = _itemsBuilder[i];
      final itemTotal = item.quantity * item.unitPrice;
      final newPaymentFee = (itemTotal * feePercentage) + fixedFee;
      _itemsBuilder[i] = item.copyWith(paymentFee: newPaymentFee);
    }
    notifyListeners();
  }

  void addNewItem() {
    if (_products.isEmpty || _suppliers.isEmpty) return;

    final currentPaymentMethod = _purchaseBuilder.paymentMethod;
    final feeConfig = _paymentFeePercentages[currentPaymentMethod] ?? {'percentage': 0.0, 'fixed': 0.0};
    final feePercentage = feeConfig['percentage']!;
    final fixedFee = feeConfig['fixed']!;

    final defaultUnitPrice = _products.first.defaultPrice;
    final defaultQuantity = 1.0;
    final initialItemTotal = defaultQuantity * defaultUnitPrice;
    final initialPaymentFee = (initialItemTotal * feePercentage) + fixedFee;

    _itemsBuilder.add(
      PurchaseItem(
        purchaseId: _editingPurchaseId ?? 0,
        productId: _products.first.id!,
        supplierId: _suppliers.first.id!,
        quantity: defaultQuantity,
        unitPrice: defaultUnitPrice,
        paymentFee: initialPaymentFee,
      )
    );
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _itemsBuilder.length) {
      _itemsBuilder.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(int index, {
    int? productId,
    int? supplierId,
    double? quantity,
    double? unitPrice,
  }) {
    if (index < 0 || index >= _itemsBuilder.length) return;

    final oldItem = _itemsBuilder[index];
    
    double newUnitPrice = unitPrice ?? oldItem.unitPrice;
    if (productId != null && productId != oldItem.productId && unitPrice == null) {
      final newProduct = _products.firstWhere((p) => p.id == productId, orElse: () => _products.first);
      newUnitPrice = newProduct.defaultPrice;
    }

    final newQuantity = quantity ?? oldItem.quantity;
    final currentPaymentMethod = _purchaseBuilder.paymentMethod;
    final feeConfig = _paymentFeePercentages[currentPaymentMethod] ?? {'percentage': 0.0, 'fixed': 0.0};
    final feePercentage = feeConfig['percentage']!;
    final fixedFee = feeConfig['fixed']!;

    final newItemTotal = newQuantity * newUnitPrice;
    final newPaymentFee = (newItemTotal * feePercentage) + fixedFee;

    _itemsBuilder[index] = oldItem.copyWith(
      productId: productId,
      supplierId: supplierId,
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      paymentFee: newPaymentFee,
    );
    notifyListeners();
  }

  void clearForm() {
    _editingPurchaseId = null;
    _purchaseBuilder = Purchase(
      date: DateTime.now(),
      owner: _requesters.isNotEmpty ? _requesters.first : '',
      projectType: _projectTypes.first,
      paymentMethod: _paymentMethods.isNotEmpty ? _paymentMethods.first : '',
      createdAt: DateTime.now(),
    );
    _itemsBuilder = [];
    _recalculateAllItemFees(); // Recalculate fees for cleared form (empty items, but sets up for new ones)
    notifyListeners();
  }

  // Database operations
  Future<void> _loadProducts() async {
    try {
      _products = await _dbService.getProducts();
      _products.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _setErrorMessage('Erreur chargement produits: $e');
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      _suppliers = await _dbService.getSuppliers();
      _suppliers.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _setErrorMessage('Erreur chargement fournisseurs: $e');
    }
  }

  Future<void> _loadRequesters() async {
    try {
      _requesters = await _dbService.getRequesters();
      // Remove 'CET' if it exists, to ensure it's added at the beginning
      _requesters.remove('CET');
      _requesters.sort(); // Sort the remaining requesters
      _requesters.insert(0, 'CET'); // Insert 'CET' at the first position
    } catch (e) {
      _setErrorMessage('Erreur chargement demandeurs: $e');
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      _paymentMethods = await _dbService.getPaymentMethods();
      _paymentMethods.sort();
    } catch (e) {
      _setErrorMessage('Erreur chargement modes de paiement: $e');
    }
  }

  Future<void> loadPurchases() async {
    _setLoading(true);
    try {
      _purchases = await _dbService.getAllPurchases();
      await loadAnalytics();
      _setErrorMessage('');
    } catch (e) {
      _setErrorMessage('Erreur chargement achats: $e');
    }
    _setLoading(false);
  }

  Future<Purchase?> addPurchase() async {
    if (_itemsBuilder.isEmpty) {
      _setErrorMessage('Veuillez ajouter au moins un article.');
      return null;
    }

    _setLoading(true);
    try {
      _purchaseBuilder.items = _itemsBuilder;
      final newPurchase = await _dbService.insertPurchase(_purchaseBuilder);
      
      await loadPurchases();
      clearForm();
      _setLoading(false);
      return newPurchase;
    } catch (e) {
      _setErrorMessage("Erreur lors de l'ajout: $e");
      _setLoading(false);
      return null;
    }
  }

  Future<Purchase?> updatePurchase() async {
    if (_editingPurchaseId == null) {
      _setErrorMessage('Aucun achat en cours de modification.');
      return null;
    }
    if (_itemsBuilder.isEmpty) {
      _setErrorMessage('Un achat doit contenir au moins un article.');
      return null;
    }

    _setLoading(true);
    try {
      _purchaseBuilder.items = _itemsBuilder;
      final updatedPurchase = await _dbService.updatePurchase(_purchaseBuilder);

      await loadPurchases();
      clearForm();
      _setLoading(false);
      return updatedPurchase;
    } catch (e) {
      _setErrorMessage("Erreur lors de la mise à jour: $e");
      _setLoading(false);
      return null;
    }
  }

  Future<Product> addNewProduct({
    required String name,
    required String unit,
    required String category,
    double defaultPrice = 0.0,
  }) async {
    _setLoading(true);
    try {
      final fullName = '$category: $name';
      final newProduct = Product(name: fullName, unit: unit, defaultPrice: defaultPrice);
      final savedProduct = await _dbService.insertProduct(newProduct);
      await _loadProducts();
      _setLoading(false);
      return savedProduct;
    } catch (e) {
      _setErrorMessage("Erreur lors de l'ajout du produit: $e");
      _setLoading(false);
      rethrow;
    }
  }

  Future<Supplier> addNewSupplier({required String name}) async {
    _setLoading(true);
    try {
      final newSupplier = Supplier(name: name);
      final savedSupplier = await _dbService.insertSupplier(newSupplier);
      await _loadSuppliers();
      _setLoading(false);
      return savedSupplier;
    } catch (e) {
      _setErrorMessage("Erreur lors de l'ajout du fournisseur: $e");
      _setLoading(false);
      rethrow;
    }
  }

  Future<String> addNewRequester({required String name}) async {
    _setLoading(true);
    try {
      final savedRequester = await _dbService.insertRequester(name);
      await _loadRequesters();
      updatePurchaseHeader(owner: savedRequester);
      _setLoading(false);
      return savedRequester;
    } catch (e) {
      _setErrorMessage("Erreur lors de l'ajout du demandeur: $e");
      _setLoading(false);
      rethrow;
    }
  }

  Future<String> addNewPaymentMethod({required String name}) async {
    _setLoading(true);
    try {
      final savedPaymentMethod = await _dbService.insertPaymentMethod(name);
      await _loadPaymentMethods();
      updatePurchaseHeader(paymentMethod: savedPaymentMethod);
      _setLoading(false);
      return savedPaymentMethod;
    } catch (e) {
      _setErrorMessage("Erreur lors de l'ajout du mode de paiement: $e");
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await _dbService.deletePurchase(id);
      await loadPurchases();
    } catch (e) {
      _setErrorMessage('Erreur lors de la suppression: $e');
    }
  }

  Future<void> loadAnalytics() async {
    try {
      _supplierTotals = await _dbService.getTotalBySupplier();
      _projectTypeTotals = await _dbService.getTotalByProjectType();
      _productTotals = await _dbService.getTotalByProduct();
      _totalSpent = await _dbService.getTotalSpent();
      _totalPurchases = await _dbService.getTotalPurchases();
    } catch (e) {
      _setErrorMessage('Erreur chargement analyses: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      _setLoading(true);
      await ExcelService.shareExcelReport(_purchases);
    } catch (e) {
      _setErrorMessage("Erreur lors de l'export: $e");
    }
    _setLoading(false);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}