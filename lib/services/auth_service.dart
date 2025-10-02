
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provisions/models/user.dart';

class AuthService {
  static const String _loggedInUserIdentifierKey = 'logged_in_user_identifier';
  static const String _allUsersKey = 'all_users_list_v2';

  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];

  AppUser? get currentUser => _currentUser;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_allUsersKey) ?? '[]';
    _allUsers = (json.decode(usersString) as List).map((data) => AppUser.fromMap(data)).toList();
    final loggedInIdentifier = prefs.getString(_loggedInUserIdentifierKey);
    if (loggedInIdentifier != null) {
      try {
        _currentUser = _allUsers.firstWhere((u) => u.identifier == loggedInIdentifier);
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  bool isLoggedIn() => _currentUser != null;

  Future<bool> signUp({required String name, required String identifier, required String password}) async {
    if (_allUsers.any((user) => user.identifier == identifier)) {
      return false; // User already exists
    }
    final passwordHash = _hashPassword(password);
    final newUser = AppUser(name: name, identifier: identifier, passwordHash: passwordHash);
    _allUsers.add(newUser);
    _currentUser = newUser;
    await _saveAndSetLoggedInUser(newUser);
    return true;
  }

  Future<bool> signIn(String identifier, String password) async {
    try {
      final user = _allUsers.firstWhere((u) => u.identifier == identifier);
      final passwordHash = _hashPassword(password);
      if (user.passwordHash == passwordHash) {
        _currentUser = user;
        await _saveAndSetLoggedInUser(user);
        return true;
      }
    } catch (e) {
      // User not found
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdentifierKey);
  }

  Future<void> deleteCurrentUser() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Remove user-specific data (purchases)
    await prefs.remove('user_purchases_${_currentUser!.identifier}');
    // Remove user from the list
    _allUsers.removeWhere((user) => user.identifier == _currentUser!.identifier);
    await prefs.setString(_allUsersKey, json.encode(_allUsers.map((u) => u.toMap()).toList()));
    // Log out
    await logout();
  }

  Future<void> _saveAndSetLoggedInUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_allUsersKey, json.encode(_allUsers.map((u) => u.toMap()).toList()));
    await prefs.setString(_loggedInUserIdentifierKey, user.identifier);
  }
}
