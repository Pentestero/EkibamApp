import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/screens/home_page.dart';
import 'package:provisions/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PurchaseProvider(),
      child: MaterialApp(
        title: 'EKIBAM',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: AuthService.instance.isLoggedIn() ? const HomePage() : const AuthScreen(),
      ),
    );
  }
}