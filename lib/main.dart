import 'package:firebase_core/firebase_core.dart';
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
    print('📊 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    
    // 🔍 DIAGNÓSTICO FIRESTORE - PARA BASE DE DATOS NUEVA "inv-mro"
    print('🔍 Iniciando diagnóstico Firestore (base de datos: inv-mro)...');
    try {
      final firestore = FirebaseFirestore.instance;
      print('   ✅ Instancia Firestore obtenida');
      
      // Probar con colección que usará la app
      final testDoc = firestore.collection('items').doc('test_conexion');
      
      print('   ⏳ Intentando escritura en colección "items"...');
      
      // Usar timeout para evitar que se quede trabado
      await testDoc.set({
        'nombre': 'Item de prueba - Conexión Firestore',
        'descripcion': 'Verificando conexión con base de datos inv-mro',
        'timestamp': FieldValue.serverTimestamp(),
        'proyecto': DefaultFirebaseOptions.currentPlatform.projectId,
        'base_datos': 'inv-mro',
      }).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Firestore no respondió después de 15 segundos');
      });
      
      print('   ✅ Escritura Firestore exitosa en "items"');
      
      // Probar operación de lectura
      print('   ⏳ Intentando lectura...');
      final snapshot = await testDoc.get().timeout(const Duration(seconds: 10));
      print('   ✅ Lectura Firestore exitosa');
      print('   📄 Datos guardados: ${snapshot.data()}');
      
      // Limpiar test (opcional)
      await testDoc.delete().timeout(const Duration(seconds: 5));
      print('   🧹 Test de diagnóstico limpiado');
      
      print('🎯 Firestore funcionando correctamente ✅');
      print('   Base de datos: inv-mro');
      print('   Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      
    } catch (e) {
      print('❌ Error en diagnóstico Firestore:');
      print('   Tipo: ${e.runtimeType}');
      print('   Mensaje: $e');
      
      if (e is FirebaseException) {
        print('   Código: ${e.code}');
        print('   Detalles: ${e.message}');
        
        if (e.code == 'permission-denied') {
          print('   🔍 PROBLEMA: Permisos denegados');
          print('   💡 SOLUCIÓN: Verifica las reglas en Firebase Console');
        }
        
        if (e.code == 'not-found') {
          print('   🔍 PROBLEMA: Base de datos no encontrada');
          print('   💡 SOLUCIÓN: La base de datos inv-mro puede necesitar más tiempo para activarse');
        }
      }
      
      if (e is TimeoutException) {
        print('   🔍 PROBLEMA: Timeout de conexión');
        print('   💡 SOLUCIÓN: La base de datos inv-mro está creándose');
        print('   ⏰ Espera 5-10 minutos y reinicia la app');
        print('   🔗 Verifica: https://console.firebase.google.com/project/invapp-5f0f9/firestore');
      }
      
      print('   💡 La app funcionará con SQLite local mientras se resuelve Firestore');
    }
    
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }
  
  // ✅ 2. LUEGO inicializar base de datos SQLite
  print('💾 Inicializando base de datos local...');
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  // ✅ 3. FINALMENTE inicializar InventoryService
  print('🔄 Inicializando InventoryService...');
  await InventoryService.initialize();

  // ✅ 4. FORZAR SQLITE MIENTRAS SE RESUELVE FIRESTORE
  print('🛡️  Configurando modo de operación...');
  try {
    await InventoryService().switchToSQLite();
    print('💾 Modo SQLite activado - App funcionando correctamente');
    print('   📍 Base de datos local: inventario.db');
  } catch (e) {
    print('⚠️  Error configurando SQLite: $e');
  }
  
  print('🎯 Todas las inicializaciones completadas');
  print('   ✅ SQLite Local: Operativo');
  print('   🔄 Firestore (inv-mro): En verificación');
  print('   🚀 Aplicación lista para usar');
  
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