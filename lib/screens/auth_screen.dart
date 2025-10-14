import 'package:flutter/material.dart';
import 'package:provisions/screens/signin_screen.dart';
import 'package:provisions/screens/signup_screen.dart';
import 'package:provisions/widgets/app_brand.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Use theme background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBrand(),
              const SizedBox(height: 16), // Adjusted spacing
              Text(
                'Gérez vos approvisionnements simplement',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface, // Ensure text color is visible
                ),
              ),
              const SizedBox(height: 48), // Adjusted spacing
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
                },
                // Removed custom style to use theme's ElevatedButtonThemeData
                child: const Text('S\'inscrire'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
                },
                // Removed custom style to use theme's OutlinedButtonThemeData (if defined, otherwise default)
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary, // Use primary color for text
                  side: BorderSide(color: Theme.of(context).colorScheme.primary), // Use primary color for border
                  padding: const EdgeInsets.symmetric(vertical: 12), // Adjusted padding for consistency
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
