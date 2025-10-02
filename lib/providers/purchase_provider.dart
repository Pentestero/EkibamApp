import 'package:flutter/material.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/services/excel_service.dart';

const List<String> _projectTypes = ['Client', 'Interne', 'Mixte'];
const Map<String, Map<String, double>> _paymentFeePercentages = {
  'MoMo': {'percentage': 0.015, 'fixed': 4.0},
  'OM': {'percentage': 0.015, 'fixed': 4.0},
  'Wave': {'percentage': 0.01, 'fixed': 0.0},
  'Especes': {'percentage': 0.0, 'fixed': 0.0},
  'Aucun': {'percentage': 0.0, 'fixed': 0.0},
};

class PurchaseProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  final AuthService _authService = AuthService.instance;

  List<Purchase> _purchases = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  List<String> _requesters = [];
  List<String> _paymentMethods = [];

  bool _isLoading = false;
  String _errorMessage = '';
  int? _editingPurchaseId;

  Purchase _purchaseBuilder = Purchase(date: DateTime.now(), owner: '', projectType: _projectTypes.first, paymentMethod: '', createdAt: DateTime.now());
  List<PurchaseItem> _itemsBuilder = [];

  List<Purchase> get purchases => _purchases;
  List<Product> get products => _products;
  List<Supplier> get suppliers => _suppliers;
  List<String> get requesters => _requesters;
  List<String> get projectTypes => _projectTypes;
  List<String> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isEditing => _editingPurchaseId != null;

  String? get currentUserIdentifier => _authService.currentUser?.identifier;

  Map<String, double> get supplierTotals => _calculateAnalytics((item) => item.supplierName ?? 'N/A', (item) => item.total);
  Map<String, double> get projectTypeTotals => _calculateAnalytics((purchase) => purchase.projectType, (purchase) => purchase.grandTotal, isPurchaseLevel: true);
  double get totalSpent => _purchases.fold(0.0, (sum, p) => sum + p.grandTotal);
  int get totalPurchases => _purchases.length;

  Purchase get purchaseBuilder => _purchaseBuilder;
  List<PurchaseItem> get itemsBuilder => _itemsBuilder;
  double get grandTotalBuilder => _itemsBuilder.fold(0.0, (sum, item) => sum + item.total);

  Future<void> initialize() async {
    if (!_authService.isLoggedIn()) return;
    _setLoading(true);
    await Future.wait([
      loadPurchases(),
      _loadProducts(),
      _loadSuppliers(),
      _loadRequesters(),
      _loadPaymentMethods(),
    ]);
    _resetPurchaseBuilder();
    _setLoading(false);
  }

  Future<void> loadPurchases() async {
    if (!_authService.isLoggedIn()) return;
    _setLoading(true);
    try {
      _purchases = await _dbService.getAllPurchases(_authService.currentUser!.identifier); 
      _setErrorMessage('');
    } catch (e) {
      _setErrorMessage('Erreur chargement achats: $e');
    }
    _setLoading(false);
  }

  Future<void> _savePurchases() async {
    if (!_authService.isLoggedIn()) return;
    try {
      await _dbService.saveAllPurchases(_authService.currentUser!.identifier, _purchases);
    } catch (e) {
      _setErrorMessage('Erreur sauvegarde achats: $e');
    }
  }

  Future<Purchase?> addPurchase() async {
    if (_itemsBuilder.isEmpty) {
      _setErrorMessage('Veuillez ajouter au moins un article.');
      return null;
    }
    _setLoading(true);
    try {
      final newPurchase = _preparePurchaseForSaving();
      _purchases.insert(0, newPurchase);
      await _savePurchases();
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
    if (_editingPurchaseId == null) return null;
    _setLoading(true);
    try {
      final updatedPurchase = _preparePurchaseForSaving();
      final index = _purchases.indexWhere((p) => p.id == _editingPurchaseId);
      if (index != -1) {
        _purchases[index] = updatedPurchase;
      }
      await _savePurchases();
      clearForm();
      _setLoading(false);
      return updatedPurchase;
    } catch (e) {
      _setErrorMessage("Erreur lors de la mise à jour: $e");
      _setLoading(false);
      return null;
    }
  }

  Future<void> deletePurchase(int id) async {
    _purchases.removeWhere((p) => p.id == id);
    await _savePurchases();
    notifyListeners();
  }

  void loadPurchaseForEditing(Purchase purchase) {
    _editingPurchaseId = purchase.id;
    _purchaseBuilder = purchase.copyWith();
    _itemsBuilder = List<PurchaseItem>.from(purchase.items.map((item) => item.copyWith()));
    notifyListeners();
  }

  void clearForm() {
    _editingPurchaseId = null;
    _resetPurchaseBuilder();
    _itemsBuilder = [];
    notifyListeners();
  }

  void _resetPurchaseBuilder() {
    _purchaseBuilder = Purchase(
      date: DateTime.now(),
      owner: _requesters.isNotEmpty ? _requesters.first : '',
      projectType: _projectTypes.first,
      paymentMethod: _paymentMethods.isNotEmpty ? _paymentMethods.first : '',
      createdAt: DateTime.now(),
    );
  }

  Purchase _preparePurchaseForSaving() {
    final now = DateTime.now();
    final datePrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int dailyCounter = 1;
    for (final p in _purchases) {
      if (p.createdAt.year == now.year && p.createdAt.month == now.month && p.createdAt.day == now.day) {
        final pRequestNumber = p.requestNumber ?? '';
        final parts = pRequestNumber.split('-');
        if (parts.length == 4) {
          dailyCounter = (int.tryParse(parts.last) ?? 0) + 1;
          break;
        }
      }
    }
    final requestNumber = '#EKA-$datePrefix-$dailyCounter';

    final int purchaseId = _editingPurchaseId ?? (_purchases.isNotEmpty ? _purchases.map((p) => p.id!).reduce((a, b) => a > b ? a : b) + 1 : 1);
    
    return _purchaseBuilder.copyWith(
      id: purchaseId,
      requestNumber: _editingPurchaseId == null ? requestNumber : _purchaseBuilder.requestNumber,
      items: _itemsBuilder,
      createdAt: _editingPurchaseId == null ? now : _purchaseBuilder.createdAt,
    );
  }

  // --- Item Management ---
  void addNewItem() {
    if (_products.isEmpty || _suppliers.isEmpty) return;
    final newItem = PurchaseItem(
      purchaseId: _editingPurchaseId ?? 0,
      productId: _products.first.id!,
      supplierId: _suppliers.first.id!,
      quantity: 1.0,
      unitPrice: _products.first.defaultPrice,
    );
    _itemsBuilder.add(newItem);
    _recalculateAllItemFees();
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _itemsBuilder.length) {
      _itemsBuilder.removeAt(index);
      _recalculateAllItemFees();
      notifyListeners();
    }
  }

  void updateItem(int index, {int? productId, int? supplierId, double? quantity, double? unitPrice}) {
    if (index < 0 || index >= _itemsBuilder.length) return;
    final oldItem = _itemsBuilder[index];
    double newUnitPrice = unitPrice ?? oldItem.unitPrice;
    if (productId != null && productId != oldItem.productId && unitPrice == null) {
      newUnitPrice = _products.firstWhere((p) => p.id == productId, orElse: () => _products.first).defaultPrice;
    }
    _itemsBuilder[index] = oldItem.copyWith(productId: productId, supplierId: supplierId, quantity: quantity, unitPrice: newUnitPrice);
    _recalculateAllItemFees();
    notifyListeners();
  }

  void updatePurchaseHeader({DateTime? date, String? owner, String? projectType, String? paymentMethod, String? comments}) {
    _purchaseBuilder = _purchaseBuilder.copyWith(date: date, owner: owner, projectType: projectType, paymentMethod: paymentMethod, comments: comments);
    if (paymentMethod != null) _recalculateAllItemFees();
    notifyListeners();
  }

  void _recalculateAllItemFees() {
    final feeConfig = _paymentFeePercentages[_purchaseBuilder.paymentMethod] ?? {'percentage': 0.0, 'fixed': 0.0};
    for (int i = 0; i < _itemsBuilder.length; i++) {
      final item = _itemsBuilder[i];
      final itemTotal = item.quantity * item.unitPrice;
      final newPaymentFee = (itemTotal * feeConfig['percentage']!) + feeConfig['fixed']!;
      _itemsBuilder[i] = item.copyWith(paymentFee: newPaymentFee);
    }
  }

  // --- Metadata Loading ---
  Future<void> _loadProducts() async => _products = await _dbService.getProducts(_authService.currentUser!.identifier)..sort((a, b) => a.name.compareTo(b.name));
  Future<void> _loadSuppliers() async => _suppliers = await _dbService.getSuppliers(_authService.currentUser!.identifier)..sort((a, b) => a.name.compareTo(b.name));
  Future<void> _loadRequesters() async => _requesters = await _dbService.getRequesters(_authService.currentUser!.identifier)..sort((a, b) => a.compareTo(b));
  Future<void> _loadPaymentMethods() async => _paymentMethods = await _dbService.getPaymentMethods(_authService.currentUser!.identifier)..sort((a, b) => a.compareTo(b));

  // --- Metadata Adding ---
  Future<Product> addNewProduct({required String name, required String unit, required String category, double defaultPrice = 0.0}) async {
    final newProduct = await _dbService.insertProduct(_authService.currentUser!.identifier, Product(name: '$category: $name', unit: unit, defaultPrice: defaultPrice));
    await _loadProducts();
    notifyListeners();
    return newProduct;
  }

  Future<Supplier> addNewSupplier({required String name}) async {
    final newSupplier = await _dbService.insertSupplier(_authService.currentUser!.identifier, Supplier(name: name));
    await _loadSuppliers();
    notifyListeners();
    return newSupplier;
  }

  Future<String> addNewRequester({required String name}) async {
    final savedRequester = await _dbService.insertRequester(_authService.currentUser!.identifier, name);
    await _loadRequesters();
    updatePurchaseHeader(owner: savedRequester);
    return savedRequester;
  }

  Future<String> addNewPaymentMethod({required String name}) async {
    final savedPaymentMethod = await _dbService.insertPaymentMethod(_authService.currentUser!.identifier, name);
    await _loadPaymentMethods();
    updatePurchaseHeader(paymentMethod: savedPaymentMethod);
    return savedPaymentMethod;
  }

  // --- Helpers ---
  Future<void> exportToExcel() async {
    _setLoading(true);
    await ExcelService.shareExcelReport(_purchases);
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Map<String, double> _calculateAnalytics(Function(dynamic) getKey, Function(dynamic) getValue, {bool isPurchaseLevel = false}) {
    final Map<String, double> totals = {};
    final Iterable<dynamic> items = isPurchaseLevel ? _purchases : _purchases.expand((p) => p.items);
    for (final item in items) {
      final key = getKey(item);
      totals[key] = (totals[key] ?? 0) + getValue(item);
    }
    return totals;
  }
}