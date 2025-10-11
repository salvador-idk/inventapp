import 'dart:async';
import '/services/database_helper.dart';
import '/models/item_model.dart';
import '/services/firestore_service.dart';

enum DataSource { firestore, sqlite }

class InventoryService {
  static InventoryService? _instance;
  static bool _isInitialized = false;
  static bool _firebaseAvailable = false;
  static DataSource dataSource = DataSource.sqlite;
  
  bool _useFirebase = false;
  
  factory InventoryService() {
    return _instance ??= InventoryService._internal();
  }
  
  InventoryService._internal();
  
  static Future<void> initialize({bool forceReinitialize = false}) async {
    if (_isInitialized && !forceReinitialize) return;
    
    _instance ??= InventoryService._internal();
    await _instance!._initialize();
    _isInitialized = true;
  }
  
  Future<void> _initialize() async {
    print('🔄 Inicializando InventoryService...');
    
    // Verificar si Firebase está disponible
    try {
      // Test Firebase connection with better error handling
      _useFirebase = await _testFirebaseConnectionWithTimeout();
      
      if (_useFirebase) {
        dataSource = DataSource.firestore;
        print('✅ Firebase disponible - Usando Firebase como fuente');
      } else {
        _useFirebase = false;
        dataSource = DataSource.sqlite;
        print('❌ Conexión Firebase no disponible');
        print('💾 Usando SQLite local como fuente');
      }
    } catch (e) {
      _useFirebase = false;
      dataSource = DataSource.sqlite;
      print('❌ Error verificando Firebase: $e');
      print('💾 Usando SQLite local como fuente de respaldo');
    }
    
    print('✅ InventoryService inicializado - Fuente: ${_useFirebase ? "Firebase" : "SQLite Local"}');
  }

  Future<bool> _testFirebaseConnectionWithTimeout() async {
    try {
      final connectionTest = await FirestoreService.testConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Timeout probando conexión Firebase');
          return false;
        },
      );
      
      return connectionTest;
    } catch (e) {
      print('🔧 Error detallado de Firebase: $e');
      
      // Handle specific Firebase errors
      if (e.toString().contains('Permission denied') || 
          e.toString().contains('API has not been used') ||
          e.toString().contains('Firestore API has not been used')) {
        print('🚫 Firestore API no habilitada. Usando SQLite.');
        return false;
      }
      
      if (e.toString().contains('database does not exist') ||
          e.toString().contains('Not found: The database')) {
        print('🗄️ Base de datos Firestore no existe. Ve a Firebase Console para crearla.');
        print('🔗 https://console.firebase.google.com/project/invapp-5f0f9/firestore');
        return false;
      }
      
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        print('🌐 Error de red. Usando SQLite.');
        return false;
      }
      
      // For other errors, still use SQLite as fallback
      return false;
    }
  }
  
  bool get isUsingFirebase => _useFirebase;

  // ✅ ITEM EXISTS METHOD
  Future<bool> itemExists(String serial, {String? excludeItemId}) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (dataSource == DataSource.firestore) {
        return await FirestoreService.itemExists(serial, excludeItemId: excludeItemId);
      } else {
        return await DatabaseHelper().itemExists(serial, excludeItemId: excludeItemId);
      }
    } catch (e) {
      print('❌ Error verificando existencia de item: $e');
      return false;
    }
  }

  // ✅ STREAM MEJORADO PARA SQLite
  Stream<List<Item>> getItemsStream() {
    if (!_isInitialized) {
      return Stream.fromFuture(initialize()).asyncExpand((_) => getItemsStream());
    }
    
    if (dataSource == DataSource.firestore) {
      return FirestoreService.getItemsStream();
    } else {
      return _createSQLiteStream();
    }
  }

  // ✅ STREAM CONTROLLER PARA SQLite
  Stream<List<Item>> _createSQLiteStream() {
    late StreamController<List<Item>> controller;
    
    controller = StreamController<List<Item>>.broadcast(
      onListen: () async {
        // Emitir datos iniciales
        try {
          final items = await DatabaseHelper().getItems();
          controller.add(items);
        } catch (e) {
          controller.addError(e);
        }
        
        // Actualizar periódicamente
        final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
          try {
            final items = await DatabaseHelper().getItems();
            if (!controller.isClosed) {
              controller.add(items);
            }
          } catch (e) {
            print('Error en stream SQLite: $e');
          }
        });
        
        controller.onCancel = () {
          timer.cancel();
          if (!controller.isClosed) {
            controller.close();
          }
        };
      },
    );
    
    return controller.stream;
  }

  // ✅ AGREGAR ITEM CON MEJOR MANEJO DE ERRORES
  Future<String> addItem(Item item) async {
    if (!_isInitialized) await initialize();
    
    try {
      String itemId;
      
      if (dataSource == DataSource.firestore) {
        itemId = await FirestoreService.addItem(item);
      } else {
        final id = await DatabaseHelper().insertItem(item);
        itemId = id.toString();
      }
      
      print('✅ Item agregado exitosamente - ID: $itemId');
      return itemId;
      
    } catch (e) {
      print('❌ Error agregando item: $e');
      throw Exception('No se pudo guardar el item: ${e.toString()}');
    }
  }

  // ✅ ACTUALIZAR ITEM
  Future<void> updateItem(Item item) async {
    if (!_isInitialized) await initialize();
    
    if (item.id == null) {
      throw Exception('No se puede actualizar un item sin ID');
    }
    
    try {
      if (dataSource == DataSource.firestore) {
        await FirestoreService.updateItem(item);
      } else {
        await DatabaseHelper().updateItem(item);
      }
      print('✅ Item actualizado exitosamente - ID: ${item.id}');
    } catch (e) {
      print('❌ Error actualizando item ${item.id}: $e');
      throw Exception('No se pudo actualizar el item: ${e.toString()}');
    }
  }

  // ✅ ELIMINAR ITEM CON VALIDACIÓN
  Future<void> deleteItem(String itemId) async {
    if (!_isInitialized) await initialize();
    
    if (itemId.isEmpty) {
      throw Exception('ID de item inválido');
    }
    
    try {
      if (dataSource == DataSource.firestore) {
        await FirestoreService.deleteItem(itemId);
      } else {
        await DatabaseHelper().deleteItem(int.tryParse(itemId) ?? 0);
      }
      print('✅ Item eliminado exitosamente - ID: $itemId');
    } catch (e) {
      print('❌ Error eliminando item $itemId: $e');
      throw Exception('No se pudo eliminar el item: ${e.toString()}');
    }
  }

  // ✅ BÚSQUEDA MEJORADA
  Future<List<Item>> searchItems(String query) async {
    if (!_isInitialized) await initialize();
    
    if (query.length < 2) {
      return []; // No buscar con queries muy cortas
    }
    
    try {
      List<Item> results;
      
      if (dataSource == DataSource.firestore) {
        results = await FirestoreService.searchItems(query);
      } else {
        results = await DatabaseHelper().searchItems(query);
      }
      
      print('🔍 Búsqueda completada - Término: "$query", Resultados: ${results.length}');
      return results;
    } catch (e) {
      print('❌ Error en búsqueda "$query": $e');
      return []; // Retornar lista vacía en lugar de throw para mejor UX
    }
  }

  // ✅ OBTENER ITEM POR ID
  Future<Item?> getItemById(String itemId) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (dataSource == DataSource.firestore) {
        return await FirestoreService.getItemById(itemId);
      } else {
        return await DatabaseHelper().getItemById(int.tryParse(itemId) ?? 0);
      }
    } catch (e) {
      print('❌ Error obteniendo item $itemId: $e');
      return null;
    }
  }

  // ✅ OBTENER TODOS LOS ITEMS (PARA OPERACIONES POR LOTES)
  Future<List<Item>> getAllItems() async {
    if (!_isInitialized) await initialize();
    
    try {
      if (dataSource == DataSource.firestore) {
        return await FirestoreService.getAllItems();
      } else {
        return await DatabaseHelper().getItems();
      }
    } catch (e) {
      print('❌ Error obteniendo todos los items: $e');
      return [];
    }
  }

  // ✅ TEST DE CONEXIÓN MEJORADO
  static Future<bool> testFirebaseConnection() async {
    try {
      _firebaseAvailable = await FirestoreService.testConnection();
      
      if (_firebaseAvailable) {
        print('✅ Conexión Firebase exitosa');
      } else {
        print('❌ Conexión Firebase falló');
      }
      
      return _firebaseAvailable;
    } catch (e) {
      print('❌ Error en testFirebaseConnection: $e');
      _firebaseAvailable = false;
      return false;
    }
  }

  // ✅ CAMBIAR DATA SOURCE MEJORADO
  Future<bool> switchToFirebase() async {
    try {
      final isConnected = await testFirebaseConnection();
      
      if (isConnected) {
        dataSource = DataSource.firestore;
        _useFirebase = true;
        print('✅ Cambio a Firebase exitoso');
        return true;
      } else {
        print('❌ No se puede cambiar a Firebase - Sin conexión');
        return false;
      }
    } catch (e) {
      print('❌ Error cambiando a Firebase: $e');
      return false;
    }
  }

  Future<bool> switchToSQLite() async {
    try {
      dataSource = DataSource.sqlite;
      _useFirebase = false;
      print('🔄 Cambiando a SQLite');
      return true;
    } catch (e) {
      print('❌ Error cambiando a SQLite: $e');
      return false;
    }
  }

  // ✅ MIGRACIÓN DE DATOS MEJORADA
  Future<MigrationResult> migrateToFirestore({bool switchAfterMigration = true}) async {
    try {
      if (!_firebaseAvailable) {
        final connected = await testFirebaseConnection();
        if (!connected) {
          return MigrationResult(
            success: false, 
            message: 'No hay conexión con Firebase para migrar datos'
          );
        }
      }
      
      final localItems = await DatabaseHelper().getItems();
      if (localItems.isEmpty) {
        return MigrationResult(
          success: true, 
          message: 'No hay datos locales para migrar'
        );
      }
      
      print('🚀 Iniciando migración de ${localItems.length} items...');
      
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];
      
      for (final item in localItems) {
        try {
          await FirestoreService.addItem(item);
          successCount++;
        } catch (e) {
          errorCount++;
          final errorMsg = 'Item ${item.id}: ${e.toString()}';
          errors.add(errorMsg);
          print('❌ Error migrando $errorMsg');
        }
      }
      
      final message = 'Migración completada: $successCount exitosos, $errorCount errores';
      print('✅ $message');
      
      // Cambiar a Firebase después de migración exitosa
      if (switchAfterMigration && errorCount == 0) {
        dataSource = DataSource.firestore;
        _useFirebase = true;
        print('✅ Cambiado a Firebase después de migración exitosa');
      }
      
      return MigrationResult(
        success: errorCount == 0,
        message: message,
        total: localItems.length,
        successful: successCount,
        errors: errorCount,
        errorDetails: errors,
      );
    } catch (e) {
      final message = 'Error en migración: $e';
      print('❌ $message');
      return MigrationResult(success: false, message: message);
    }
  }

  // ✅ PROPIEDADES DE ESTADO
  String get currentDataSource {
    return dataSource == DataSource.firestore ? 'Firebase Firestore' : 'SQLite Local';
  }

  bool get isFirebaseAvailable => _firebaseAvailable;
  
  bool get isInitialized => _isInitialized;

  // ✅ ESTADO DEL SERVICIO MEJORADO
  Map<String, dynamic> get serviceStatus {
    return {
      'dataSource': currentDataSource,
      'initialized': _isInitialized,
      'firebaseAvailable': _firebaseAvailable,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ✅ REINICIALIZAR SERVICIO
  Future<void> reset() async {
    _isInitialized = false;
    _firebaseAvailable = false;
    dataSource = DataSource.sqlite;
    _useFirebase = false;
    await initialize(forceReinitialize: true);
  }
}

// ✅ CLASE MEJORADA PARA RESULTADOS DE MIGRACIÓN
class MigrationResult {
  final bool success;
  final String message;
  final int? total;
  final int? successful;
  final int? errors;
  final List<String>? errorDetails;

  MigrationResult({
    required this.success,
    required this.message,
    this.total,
    this.successful,
    this.errors,
    this.errorDetails,
  });

  double get successRate {
    if (total == null || total == 0) return 1.0;
    return (successful ?? 0) / total!;
  }

  bool get hasErrors => errors != null && errors! > 0;

  @override
  String toString() {
    return 'MigrationResult(success: $success, message: $message, total: $total, successful: $successful, errors: $errors, successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'total': total,
      'successful': successful,
      'errors': errors,
      'successRate': successRate,
      'hasErrors': hasErrors,
    };
  }
  // Global instance for easy access
  final inventoryService = InventoryService();
}