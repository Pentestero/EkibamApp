import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retourne l'utilisateur actuellement connecté depuis Supabase.
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream qui notifie les changements d'état d'authentification (connexion, déconnexion).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Inscrit un nouvel utilisateur avec email et mot de passe.
  /// Le nom est stocké dans les métadonnées de l'utilisateur.
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      // Après l'inscription, l'utilisateur est automatiquement connecté.
      // On notifie les auditeurs pour mettre à jour l'UI.
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      debugPrint("AuthService SignUp Error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService SignUp Generic Error: $e");
      rethrow;
    }
  }

  /// Connecte un utilisateur avec email et mot de passe.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Après la connexion, on notifie les auditeurs.
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      debugPrint("AuthService SignIn Error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService SignIn Generic Error: $e");
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // La navigation est gérée par le StreamBuilder dans main.dart
    } on AuthException catch (e) {
      debugPrint("AuthService SignOut Error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService SignOut Generic Error: $e");
      rethrow;
    }
  }

  /// Supprime le compte de l'utilisateur actuel.
  /// **NOTE:** La suppression complète nécessite une fonction Edge sur Supabase.
  /// Pour l'instant, cette fonction déconnecte simplement l'utilisateur.
  Future<void> deleteCurrentUser() async {
    // TODO: Implement a Supabase Edge Function to handle user deletion securely.
    // This requires deleting the user from the `auth.users` table, which is protected.
    // For now, we just sign the user out.
    await signOut();
  }
}