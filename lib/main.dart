import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inventario_app/firebase_options.dart';
import 'package:inventario_app/services/inventory_service.dart';
import 'package:provider/provider.dart';
import '/screens/login_screen.dart';
import '/screens/main_screen.dart';
import '/providers/auth_provider.dart';
import '/services/database_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando inicialización de la aplicación...');
  
  // ✅ 1. PRIMERO inicializar Firebase
  print('🔥 Inicializando Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }
  
  // ✅ 2. LUEGO inicializar base de datos SQLite
  print('💾 Inicializando base de datos local...');
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  // ✅ 3. FINALMENTE inicializar InventoryService (que ahora puede usar Firebase)
  print('🔄 Inicializando InventoryService...');
  await InventoryService.initialize();
  
  print('🎯 Todas las inicializaciones completadas');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        Provider(create: (context) => InventoryService()),
      ],
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