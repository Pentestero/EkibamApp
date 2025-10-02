import 'package:flutter/material.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/home_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final success = await AuthService.instance.signIn(
        _identifierController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identifiant ou mot de passe incorrect.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _identifierController, decoration: const InputDecoration(labelText: 'Email ou Numéro de téléphone', prefixIcon: Icon(Icons.contact_mail)), validator: (value) => (value?.isEmpty ?? true) ? 'Champ requis' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, obscureText: !_isPasswordVisible, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))), validator: (value) => (value?.isEmpty ?? true) ? 'Champ requis' : null),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('Se connecter')),
            ],
          ),
        ),
      ),
    );
  }
}