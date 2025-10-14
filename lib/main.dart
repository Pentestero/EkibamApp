import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/screens/home_page.dart';
import 'package:provisions/screens/auth_screen.dart';
import 'package:provisions/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ajparjbrzvaxfpafjbad.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqcGFyamJyenZheGZwYWZqYmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMTM0OTAsImV4cCI6MjA3NTc4OTQ5MH0.A3UNx_1z6EWBE3qwdQIXPth_iUyiuTXLKgl5m-wrDds',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService.instance),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: MaterialApp(
        title: 'EKIBAM',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: StreamBuilder<AuthState>(
          stream: AuthService.instance.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final session = snapshot.data?.session;
            if (session != null) {
              // If we have a session, pass the user object to the HomePage
              return HomePage(user: session.user);
            } 

            // Otherwise, show the auth screen
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
