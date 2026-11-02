import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page.dart';

// Variabile globale per monitorare lo stato di autenticazione
ValueNotifier<bool> authNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Controlla se il token esiste all'avvio
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  authNotifier.value = token != null && token.isNotEmpty;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Avvolgiamo MaterialApp nel ValueListenableBuilder per resettare 
    // completamente lo stack di navigazione al cambio di stato
    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (context, isLoggedIn, child) {
        return MaterialApp(
          title: 'App PHP Backend',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          home: isLoggedIn ? const HomePage() : const LoginPage(),
        );
      },
    );
  }
}