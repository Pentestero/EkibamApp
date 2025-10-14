import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre nom';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer un email';
    if (!_emailRegex.hasMatch(value)) return 'Email invalide';
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && response.user != null) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomePage(user: response.user!)), (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Une erreur inattendue est survenue.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), validator: _validateEmail, keyboardType: TextInputType.emailAddress),
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