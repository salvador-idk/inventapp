import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'auth_provider.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos y crear usuario por defecto si no existe
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Inventario',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          print('🏠 MyApp - isLoggedIn: ${auth.isLoggedIn}');
          return auth.isLoggedIn ? const MainScreen() : const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}