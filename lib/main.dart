import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventario_app/firebase_options.dart';
import 'package:inventario_app/services/inventory_service.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Para TimeoutException
import '/screens/login_screen.dart';
import '/screens/main_screen.dart';
import '/providers/auth_provider.dart';
import '/services/database_helper.dart';
import '/services/data_repository.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación...');
  print('🌐 Plataforma: ${kIsWeb ? 'Web' : 'Móvil/Desktop'}');
  
  try {
    // ✅ 1. INICIALIZAR FIREBASE
    print('🔥 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
    print('📊 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    
    // ✅ 2. DIAGNÓSTICO SEGÚN PLATAFORMA
    if (kIsWeb) {
      print('🔍 Iniciando diagnóstico para Web...');
      await _performWebDiagnostic();
    } else {
      print('📱 Iniciando diagnóstico para Móvil/Desktop...');
      await _performMobileDiagnostic();
    }
    
  } catch (e) {
    print('⚠️ Error en inicialización: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        Provider<DataRepository>(create: (_) => DataRepository()), // ✅ AGREGAR DATA REPOSITORY
        Provider<InventoryService>(
          create: (context) => InventoryService(
            repository: context.read<DataRepository>(), // ✅ PASAR REPOSITORY
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// ✅ DIAGNÓSTICO OPTIMIZADO PARA WEB
Future<void> _performWebDiagnostic() async {
  try {
    final repository = DataRepository();
    
    // Test de conexión Firestore
    print('🔍 Test de conexión Firestore...');
    final connected = await _testFirestoreConnection();
    
    if (connected) {
      print('✅ Firestore conectado correctamente');
      
      // Inicializar datos por defecto
      print('🔄 Inicializando datos por defecto...');
      await repository.initializeApp();
      
    } else {
      print('⚠️ Firestore puede estar en proceso de creación');
      print('💡 La app funcionará en modo limitado hasta que Firestore esté listo');
      
      // Inicializar de todos modos para que la app no crashee
      await repository.initializeApp();
    }
    
  } catch (e) {
    print('❌ Error en diagnóstico web: $e');
    print('💡 La app puede funcionar con capacidades limitadas');
  }
}

// ✅ DIAGNÓSTICO PARA MÓVIL/DESKTOP
Future<void> _performMobileDiagnostic() async {
  try {
    final repository = DataRepository();
    
    // Inicializar SQLite
    print('💾 Inicializando SQLite local...');
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    print('✅ SQLite inicializado correctamente');
    
    // Test de Firestore opcional para sincronización
    print('🔍 Verificando Firestore para sincronización...');
    final connected = await _testFirestoreConnection();
    if (connected) {
      print('✅ Firestore disponible para sincronización');
      
      // Inicializar datos por defecto en Firestore
      await repository.initializeApp();
    } else {
      print('⚠️ Firestore no disponible, usando solo SQLite local');
      await repository.initializeApp();
    }
    
  } catch (e) {
    print('❌ Error en diagnóstico móvil: $e');
  }
}

// ✅ TEST DE CONEXIÓN MÁS RÁPIDO Y ROBUSTO
Future<bool> _testFirestoreConnection() async {
  try {
    // Timeout más corto para web
    final timeoutDuration = kIsWeb ? Duration(seconds: 5) : Duration(seconds: 10);
    
    final result = await Future.any([
      _actualConnectionTest(),
      Future.delayed(timeoutDuration, () => false),
    ]);
    
    return result;
  } catch (e) {
    print('⏰ Timeout o error en test de conexión: $e');
    return false;
  }
}

Future<bool> _actualConnectionTest() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Test más simple y rápido
    await firestore.collection('connection_test')
        .limit(1)
        .get(const GetOptions(source: Source.server));
    
    return true;
  } catch (e) {
    print('❌ Error en test de conexión Firestore: $e');
    
    if (e is FirebaseException) {
      print('   Código: ${e.code}');
      print('   Mensaje: ${e.message}');
      
      if (e.code == 'permission-denied') {
        print('   🔍 PROBLEMA: Permisos denegados');
        print('   💡 SOLUCIÓN: Verifica las reglas en Firebase Console');
      }
      
      if (e.code == 'not-found') {
        print('   🔍 PROBLEMA: Base de datos no encontrada');
        print('   💡 SOLUCIÓN: La base de datos puede necesitar más tiempo para activarse');
      }
    }
    
    if (e is TimeoutException) {
      print('   🔍 PROBLEMA: Timeout de conexión');
      print('   💡 SOLUCIÓN: La base de datos está creándose');
      print('   ⏰ Espera 5-10 minutos y reinicia la app');
      print('   🔗 Verifica: https://console.firebase.google.com/project/invapp-5f0f9/firestore');
    }
    
    return false;
  }
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