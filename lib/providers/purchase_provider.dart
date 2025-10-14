import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/models/product.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/services/excel_service.dart';
import 'package:provisions/services/pdf_service.dart';

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
  User? _user;

  List<Purchase> _purchases = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  List<String> _requesters = [];
  List<String> _paymentMethods = [];

  bool _isLoading = true; // Start with loading true
  String _errorMessage = '';
  int? _editingPurchaseId;

  Purchase _purchaseBuilder = Purchase(date: DateTime.now(), owner: '', creatorInitials: '', demander: '', projectType: _projectTypes.first, paymentMethod: '', createdAt: DateTime.now());
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

  String? get currentUserId => _user?.id;

  Map<String, double> get supplierTotals => _calculateAnalytics((item) => item.supplierName ?? 'N/A', (item) => item.total);
  Map<String, double> get projectTypeTotals => _calculateAnalytics((purchase) => purchase.projectType, (purchase) => purchase.grandTotal, isPurchaseLevel: true);
  double get totalSpent => _purchases.fold(0.0, (sum, p) => sum + p.grandTotal);
  int get totalPurchases => _purchases.length;

  Purchase get purchaseBuilder => _purchaseBuilder;
  List<PurchaseItem> get itemsBuilder => _itemsBuilder;
  double get grandTotalBuilder => _itemsBuilder.fold(0.0, (sum, item) => sum + item.total);

  Future<void> initialize(User user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadPurchases(notify: false),
      _loadProducts(),
      _loadSuppliers(),
      _loadRequesters(),
      _loadPaymentMethods(),
    ]);
    _resetPurchaseBuilder();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPurchases({bool notify = true}) async {
    if (_user == null) return;
    if (notify) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      _purchases = await _dbService.getAllPurchases();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur chargement achats: $e';
    } finally {
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<Purchase?> addPurchase() async {
    if (_user == null) {
      _errorMessage = 'Utilisateur non authentifié.';
      notifyListeners();
      return null;
    }
    if (_itemsBuilder.isEmpty) {
      _errorMessage = 'Veuillez ajouter au moins un article.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final purchaseToSave = _preparePurchaseForSaving();
      final newPurchase = await _dbService.addPurchase(purchaseToSave, _user!.id);
      
      _purchases.insert(0, newPurchase);
      clearForm();
      return newPurchase;
    } catch (e) {
      _errorMessage = "Erreur lors de l'ajout: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Purchase?> updatePurchase() async {
    print("Update feature not implemented yet.");
    return null;
  }

  Future<void> deletePurchase(int id) async {
    print("Delete feature not implemented yet.");
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
    if (_user == null) return;
    final userName = _user!.userMetadata?['name'] as String? ?? 'N/A';
    _purchaseBuilder = Purchase(
      date: DateTime.now(),
      owner: userName,
      creatorInitials: _getInitials(userName),
      demander: _requesters.isNotEmpty ? _requesters.first : '',
      projectType: _projectTypes.first,
      paymentMethod: _paymentMethods.isNotEmpty ? _paymentMethods.first : '',
      createdAt: DateTime.now(),
    );
  }

  Purchase _preparePurchaseForSaving() {
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    int dailyCounter = 1 + _purchases.where((p) {
      if (p.demander != _purchaseBuilder.demander) return false;
      return p.createdAt.year == now.year &&
             p.createdAt.month == now.month &&
             p.createdAt.day == now.day;
    }).length;

    final requestNumber = '${_purchaseBuilder.demander}-$datePrefix-${dailyCounter.toString().padLeft(2, '0')}';

    final int purchaseId = _editingPurchaseId ?? 0;

    final userName = _user?.userMetadata?['name'] as String? ?? 'N/A';

    final finalRequestNumber = _editingPurchaseId == null 
        ? requestNumber 
        : (_purchaseBuilder.requestNumber ?? requestNumber);

    return _purchaseBuilder.copyWith(
      id: purchaseId,
      requestNumber: finalRequestNumber,
      items: _itemsBuilder,
      createdAt: _editingPurchaseId == null ? now : _purchaseBuilder.createdAt,
      owner: userName,
      creatorInitials: _getInitials(userName),
    );
  }

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

  void updateItemComment(int index, String? comment) {
    if (index < 0 || index >= _itemsBuilder.length) return;
    final oldItem = _itemsBuilder[index];
    _itemsBuilder[index] = oldItem.copyWith(comment: comment);
    notifyListeners();
  }

  void updatePurchaseHeader({DateTime? date, String? owner, String? demander, String? projectType, String? paymentMethod, String? comments}) {
    _purchaseBuilder = _purchaseBuilder.copyWith(date: date, owner: owner, demander: demander, projectType: projectType, paymentMethod: paymentMethod, comments: comments);
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

  Future<void> _loadProducts() async => _products = await _dbService.getProducts()..sort((a, b) => a.name.compareTo(b.name));
  Future<void> _loadSuppliers() async => _suppliers = await _dbService.getSuppliers()..sort((a, b) => a.name.compareTo(b.name));
  Future<void> _loadRequesters() async {
    _requesters = ['CET', 'AOW', 'CNO', 'JMV', 'MNG'];
  }
  Future<void> _loadPaymentMethods() async => _paymentMethods = await _dbService.getPaymentMethods()..sort((a, b) => a.compareTo(b));

  Future<Product> addNewProduct({required String name, required String unit, required String category, double defaultPrice = 0.0}) async {
    if (_user == null) throw Exception('User not authenticated');
    final newProduct = await _dbService.insertProduct(_user!.id, Product(name: '$category: $name', unit: unit, defaultPrice: defaultPrice));
    await _loadProducts();
    notifyListeners();
    return newProduct;
  }

  Future<Supplier> addNewSupplier({required String name}) async {
    if (_user == null) throw Exception('User not authenticated');
    final newSupplier = await _dbService.insertSupplier(_user!.id, Supplier(name: name));
    await _loadSuppliers();
    notifyListeners();
    return newSupplier;
  }

  Future<String> addNewRequester({required String name}) async {
    return Future.value(name);
  }

  Future<String> addNewPaymentMethod({required String name}) async {
    if (_user == null) throw Exception('User not authenticated');
    final savedPaymentMethod = await _dbService.insertPaymentMethod(_user!.id, name);
    await _loadPaymentMethods();
    updatePurchaseHeader(paymentMethod: savedPaymentMethod);
    return savedPaymentMethod;
  }

  Future<void> exportToExcel() async {
    _isLoading = true;
    notifyListeners();
    await ExcelService.shareExcelReport(_purchases);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> exportToPdf() async {
    _isLoading = true;
    notifyListeners();
    await PdfService.generatePurchaseReport(_purchases);
    _isLoading = false;
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

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ').where((p) => p.isNotEmpty);
    if (parts.length > 1) {
      return parts.map((p) => p[0]).take(2).join().toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '';
  }
}
