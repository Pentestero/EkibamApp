import 'package:flutter/material.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/home_page.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _phoneRegex = RegExp(r'^(6(9\d|5[5-9]|7\d|8\d))\d{6}$');
  final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre nom';
    return null;
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer un email ou un numéro';
    if (value.contains('@')) {
      if (!_emailRegex.hasMatch(value)) return 'Email invalide';
    } else {
      if (!_phoneRegex.hasMatch(value.replaceAll(' ', ''))) return 'Numéro invalide (699.. ou 677..)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final success = await AuthService.instance.signUp(
        name: _nameController.text.trim(),
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cet utilisateur existe déjà.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person)), validator: _validateName, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              TextFormField(controller: _identifierController, decoration: const InputDecoration(labelText: 'Email ou Numéro de téléphone', prefixIcon: Icon(Icons.contact_mail)), validator: _validateIdentifier),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, obscureText: !_isPasswordVisible, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))), validator: _validatePassword),
              const SizedBox(height: 16),
              TextFormField(controller: _confirmPasswordController, obscureText: !_isConfirmPasswordVisible, decoration: InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible))), validator: _validateConfirmPassword),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('S\'inscrire')),
            ],
          ),
        ),
      ),
    );
  }
}