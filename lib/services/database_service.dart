import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/models/product.dart';

class DatabaseService {
  // --- Singleton Pattern ---
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();
  // --- End Singleton Pattern ---

  final _supabase = Supabase.instance.client;

  // --- Purchase Methods ---
  Future<List<Purchase>> getAllPurchases() async {
    // Get the current user's ID. If no user is logged in, return an empty list.
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Fetch purchases belonging to the current user, along with their related items.
      final data = await _supabase
          .from('purchases')
          .select('''
            *,
            purchase_items(*, 
              products(*),
              suppliers(*)
            )
          ''')
          .eq('user_id', userId) // Filter by the current user's ID
          .order('created_at', ascending: false);

      print("Supabase raw data for purchases: $data");

      final purchases = data.map((purchaseData) {
        final purchase = Purchase.fromMap(purchaseData);
        
        final itemsData = purchaseData['purchase_items'];
        if (itemsData != null && itemsData is List) {
          purchase.items = itemsData.map((itemData) {
            if (itemData['products'] != null) {
              itemData['productName'] = itemData['products']['name'];
            }
            if (itemData['suppliers'] != null) {
              itemData['supplierName'] = itemData['suppliers']['name'];
            }
            return PurchaseItem.fromMap(itemData);
          }).toList();
        } else {
          purchase.items = [];
        }

        return purchase;
      }).toList();

      return purchases;
    } catch (e) {
      print("Erreur lors de la récupération des achats: $e");
      print("Full error details: ${e.toString()}");
      return [];
    }
  }

  Future<Purchase> addPurchase(Purchase purchase, String userId) async {
    try {
      // 1. Insert the main purchase record, now including the user_id
      final purchaseToInsert = {
        'request_number': purchase.requestNumber,
        'date': purchase.date.toIso8601String(),
        'owner': purchase.owner,
        'creator_initials': purchase.creatorInitials,
        'demander': purchase.demander,
        'project_type': purchase.projectType,
        'payment_method': purchase.paymentMethod,
        'comments': purchase.comments,
        'created_at': purchase.createdAt.toIso8601String(),
        'user_id': userId, // Associate the purchase with the current user
      };

      final insertedPurchase = await _supabase
          .from('purchases')
          .insert(purchaseToInsert)
          .select()
          .single();

      final newPurchaseId = insertedPurchase['id'];

      // 2. Prepare and insert the related items
      if (purchase.items.isNotEmpty) {
        final itemsToInsert = purchase.items.map((item) => {
          'purchase_id': newPurchaseId,
          'product_id': item.productId,
          'supplier_id': item.supplierId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'payment_fee': item.paymentFee,
          'comment': item.comment,
        }).toList();

        await _supabase.from('purchase_items').insert(itemsToInsert);
      }
      
      // Return the complete object to update the UI
      return purchase.copyWith(id: newPurchaseId);

    } catch (e) {
      print("Erreur lors de l'ajout de l'achat: $e");
      rethrow;
    }
  }

  Future<Purchase> updatePurchase(Purchase purchase) async {
    try {
      // 1. Update the main purchase record
      final purchaseToUpdate = {
        'request_number': purchase.requestNumber,
        'date': purchase.date.toIso8601String(),
        'owner': purchase.owner,
        'creator_initials': purchase.creatorInitials,
        'demander': purchase.demander,
        'project_type': purchase.projectType,
        'payment_method': purchase.paymentMethod,
        'comments': purchase.comments,
      };

      await _supabase
          .from('purchases')
          .update(purchaseToUpdate)
          .eq('id', purchase.id!);

      // 2. Delete old items
      await _supabase
          .from('purchase_items')
          .delete()
          .eq('purchase_id', purchase.id!);

      // 3. Insert new items
      if (purchase.items.isNotEmpty) {
        final itemsToInsert = purchase.items.map((item) => {
          'purchase_id': purchase.id,
          'product_id': item.productId,
          'supplier_id': item.supplierId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'payment_fee': item.paymentFee,
          'comment': item.comment,
        }).toList();

        await _supabase.from('purchase_items').insert(itemsToInsert);
      }

      // Return the complete object to update the UI
      return purchase;

    } catch (e) {
      print("Erreur lors de la mise à jour de l'achat: $e");
      rethrow;
    }
  }

  // --- Product Methods ---
  Future<List<Product>> getProducts() async {
    try {
      final data = await _supabase.from('products').select();
      final products = data.map((item) {
        return Product.fromMap(item);
      }).toList();
      return products;
    } catch (e) {
      print("Erreur lors de la récupération des produits: $e");
      return [];
    }
  }

  // --- Supplier Methods ---
  Future<List<Supplier>> getSuppliers() async {
    try {
      final data = await _supabase.from('suppliers').select();
      final suppliers = data.map((item) => Supplier.fromMap(item)).toList();
      return suppliers;
    } catch (e) {
      print("Erreur lors de la récupération des fournisseurs: $e");
      return [];
    }
  }
  
  // --- Metadata Adding Placeholders ---
  // These methods are called by the PurchaseProvider but their full Supabase implementation
  // is not yet done. They currently just print a message and return a dummy value.

  Future<Product> insertProduct(String userId, Product product) async {
    try {
      final insertedProduct = await _supabase
          .from('products')
          .insert({
            'name': product.name,
            'unit': product.unit,
            'default_price': product.defaultPrice,
          })
          .select()
          .single();

      return Product.fromMap(insertedProduct);
    } catch (e) {
      print("Erreur lors de l'insertion du produit: $e");
      rethrow;
    }
  }

  Future<Supplier> insertSupplier(String userId, Supplier supplier) async {
    try {
      final insertedSupplier = await _supabase
          .from('suppliers')
          .insert({'name': supplier.name})
          .select()
          .single();

      return Supplier.fromMap(insertedSupplier);
    } catch (e) {
      print("Erreur lors de l'insertion du fournisseur: $e");
      rethrow;
    }
  }

  Future<String> insertPaymentMethod(String userId, String name) async {
    print("insertPaymentMethod called but not fully implemented for Supabase yet.");
    // TODO: Implement actual Supabase insert for payment methods
    return name;
  }

  // --- Other Placeholder Methods ---
  Future<List<String>> getPaymentMethods() async {
    try {
      final data = await _supabase.from('payment_methods').select('name');
      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      print("Erreur lors de la récupération des modes de paiement: $e");
      return [];
    }
  }
}
