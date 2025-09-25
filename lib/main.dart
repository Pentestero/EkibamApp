import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PurchaseProvider()..initialize(),
      child: MaterialApp(
        title: 'EKIBAM',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
