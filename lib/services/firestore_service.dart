import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/item_model.dart';
import '/models/categoria_model.dart';
import '/models/user_model.dart';
import '/models/audit_model.dart';
import '/models/ticket_model.dart';

class FirestoreService {
  // ✅ DEFINE FIRESTORE REFERENCES
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _itemsRef = _firestore.collection('items');
  static final CollectionReference _categoriesRef = _firestore.collection('categorias');
  static final CollectionReference _ticketsRef = _firestore.collection('tickets');
  static final CollectionReference _usersRef = _firestore.collection('users');
  static final CollectionReference _auditLogsRef = _firestore.collection('audit_logs');
  
  // ✅ STREAM METHODS CORREGIDOS
  static Stream<List<Item>> getItemsStream() {
    try {
      return _itemsRef
          .orderBy('nombre')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return Item.fromFirestore(doc); // ✅ CORREGIDO
              })
              .toList());
    } catch (e) {
      print('❌ Error en getItemsStream: $e');
      return Stream.value([]);
    }
  }

  // ✅ CRUD METHODS
  static Future<String> addItem(Item item) async {
    try {
      final docRef = await _itemsRef.add(item.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error agregando item: $e');
      throw Exception('No se pudo agregar el item: $e');
    }
  }

  static Future<void> updateItem(Item item) async {
    try {
      if (item.id == null || item.id!.isEmpty) {
        throw Exception('Item ID es requerido para actualizar');
      }
      await _itemsRef.doc(item.id).update(item.toFirestore());
    } catch (e) {
      print('❌ Error actualizando item ${item.id}: $e');
      throw Exception('No se pudo actualizar el item: $e');
    }
  }

  static Future<void> deleteItem(String itemId) async {
    try {
      await _itemsRef.doc(itemId).delete();
    } catch (e) {
      print('❌ Error eliminando item $itemId: $e');
      throw Exception('No se pudo eliminar el item: $e');
    }
  }

  // ✅ QUERY METHODS CORREGIDOS
  static Future<Item?> getItemById(String itemId) async {
    try {
      if (itemId.isEmpty) return null;
      
      final doc = await _itemsRef.doc(itemId).get();
      
      if (doc.exists) {
        return Item.fromFirestore(doc); // ✅ CORREGIDO
      } else {
        print('❌ Item no encontrado con ID: $itemId');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo item por ID $itemId: $e');
      return null;
    }
  }

  static Future<List<Item>> getAllItems() async {
    try {
      final querySnapshot = await _itemsRef.get();
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc)) // ✅ CORREGIDO
          .toList();
    } catch (e) {
      print('❌ Error obteniendo todos los items: $e');
      return [];
    }
  }

  static Future<List<Item>> searchItems(String query) async {
    try {
      if (query.length < 2) return [];
      
      // Search in nombre, descripcion, and serial fields
      final nombreQuery = _itemsRef
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final descripcionQuery = _itemsRef
          .where('descripcion', isGreaterThanOrEqualTo: query)
          .where('descripcion', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final serialQuery = _itemsRef
          .where('serial', isGreaterThanOrEqualTo: query)
          .where('serial', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final results = await Future.wait([nombreQuery, descripcionQuery, serialQuery]);
      
      // Combine and deduplicate results
      final allItems = <Item>[];
      final seenIds = <String>{};
      
      for (final querySnapshot in results) {
        for (final doc in querySnapshot.docs) {
          final item = Item.fromFirestore(doc); // ✅ CORREGIDO
          if (!seenIds.contains(item.id)) {
            seenIds.add(item.id!);
            allItems.add(item);
          }
        }
      }
      
      return allItems;
    } catch (e) {
      print('❌ Error buscando items: $e');
      return [];
    }
  }

  static Future<bool> itemExists(String serial, {String? excludeItemId}) async {
    try {
      Query query = _itemsRef.where('serial', isEqualTo: serial);
      
      // Exclude current item when updating
      if (excludeItemId != null && excludeItemId.isNotEmpty) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeItemId);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando existencia de item: $e');
      return false;
    }
  }

  // ✅ BATCH OPERATIONS
  static Future<void> addItemsBatch(List<Item> items) async {
    try {
      final batch = _firestore.batch();
      
      for (final item in items) {
        final docRef = _itemsRef.doc();
        batch.set(docRef, item.toFirestore());
      }
      
      await batch.commit();
      print('✅ ${items.length} items agregados en lote exitosamente');
    } catch (e) {
      print('❌ Error agregando items en lote: $e');
      throw Exception('No se pudieron agregar los items en lote: $e');
    }
  }

  // ✅ STATISTICS METHODS
  static Future<int> getItemsCount() async {
    try {
      final aggregateQuery = await _itemsRef.count().get();
      return aggregateQuery.count ?? 0;
    } catch (e) {
      print('❌ Error obteniendo conteo de items: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final totalItems = await getItemsCount();
      
      // Get items with low quantity (less than 5)
      final lowStockQuery = await _itemsRef
          .where('cantidad', isLessThan: 5)
          .get();
      
      final lowStockCount = lowStockQuery.docs.length;
      
      return {
        'totalItems': totalItems,
        'lowStockItems': lowStockCount,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {
        'totalItems': 0,
        'lowStockItems': 0,
        'lastUpdated': DateTime.now(),
      };
    }
  }

  // ========== CATEGORY METHODS CORREGIDOS ==========
  static Future<List<Categoria>> getCategorias() async {
    try {
      final querySnapshot = await _categoriesRef.orderBy('nombre').get();
      return querySnapshot.docs
          .map((doc) => Categoria.fromFirestore(doc)) // ✅ CORREGIDO
          .toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  static Future<String> addCategoria(Categoria categoria) async {
    try {
      final docRef = await _categoriesRef.add(categoria.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error agregando categoría: $e');
      throw Exception('No se pudo agregar la categoría: $e');
    }
  }

  static Future<void> updateCategoria(Categoria categoria) async {
    try {
      if (categoria.id == null || categoria.id!.isEmpty) {
        throw Exception('Categoría ID es requerido para actualizar');
      }
      await _categoriesRef.doc(categoria.id).update(categoria.toFirestore());
    } catch (e) {
      print('❌ Error actualizando categoría ${categoria.id}: $e');
      throw Exception('No se pudo actualizar la categoría: $e');
    }
  }

  static Future<Categoria?> getCategoriaById(String id) async {
    try {
      final doc = await _categoriesRef.doc(id).get();
      if (doc.exists) {
        return Categoria.fromFirestore(doc); // ✅ CORREGIDO
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo categoría por ID $id: $e');
      return null;
    }
  }

  static Future<void> deleteCategoria(String categoriaId) async {
    try {
      await _categoriesRef.doc(categoriaId).delete();
    } catch (e) {
      print('❌ Error eliminando categoría $categoriaId: $e');
      throw Exception('No se pudo eliminar la categoría: $e');
    }
  }

  // ========== TICKET METHODS CORREGIDOS ==========
  static Future<String> addTicket(TicketVenta ticket) async {
    try {
      final docRef = await _ticketsRef.add(ticket.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error agregando ticket: $e');
      throw Exception('No se pudo agregar el ticket: $e');
    }
  }

  static Future<List<TicketVenta>> getTickets() async {
    try {
      final querySnapshot = await _ticketsRef
          .orderBy('fecha', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => TicketVenta.fromFirestore(doc)) // ✅ CORREGIDO
          .toList();
    } catch (e) {
      print('❌ Error obteniendo tickets: $e');
      return [];
    }
  }

  // ========== USER METHODS CORREGIDOS ==========
  static Future<AppUser?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await _usersRef
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return AppUser.fromFirestore(querySnapshot.docs.first); // ✅ CORREGIDO
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // ========== AUDIT METHODS CORREGIDOS ==========
  static Future<String> addAuditLog(AuditLog auditLog) async {
    try {
      final docRef = await _auditLogsRef.add(auditLog.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error agregando log de auditoría: $e');
      throw Exception('No se pudo agregar el log de auditoría: $e');
    }
  }

  static Future<List<AuditLog>> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _auditLogsRef.orderBy('createdAt', descending: true);

      if (startDate != null && endDate != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: startDate)
            .where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc)) // ✅ CORREGIDO
          .toList();
    } catch (e) {
      print('❌ Error obteniendo logs de auditoría: $e');
      return [];
    }
  }

  // ✅ UTILITY METHODS
  static Future<bool> testConnection() async {
    try {
      // Test más rápido y confiable
      await _firestore.collection('connection_test')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      print('❌ Error probando conexión Firebase: $e');
      return false;
    }
}

  // ✅ BACKUP/RESTORE METHODS (OPTIONAL)
  static Future<void> backupData() async {
    try {
      final items = await getAllItems();
      final backupData = {
        'timestamp': FieldValue.serverTimestamp(),
        'itemCount': items.length,
        'items': items.map((item) => item.toMap()).toList(),
      };
      
      await _firestore.collection('backups').add(backupData);
      print('✅ Backup creado exitosamente con ${items.length} items');
    } catch (e) {
      print('❌ Error creando backup: $e');
    }
  }

  // ✅ CLEANUP METHODS
  static Future<void> cleanupOrphanedItems() async {
    // Optional: Clean up items that might be orphaned or in invalid state
    try {
      // Example: Delete items with empty names
      final orphanedQuery = await _itemsRef
          .where('nombre', isEqualTo: '')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in orphanedQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ ${orphanedQuery.docs.length} items huérfanos eliminados');
    } catch (e) {
      print('❌ Error en limpieza: $e');
    }
  }

  // ✅ INITIALIZATION METHODS
  static Future<void> initializeDefaultData() async {
    try {
      // Verificar si ya existen categorías
      final categoriasSnapshot = await _categoriesRef.get();
      if (categoriasSnapshot.docs.isEmpty) {
        await _insertarCategoriasPorDefecto();
      }

      // Verificar si ya existen usuarios
      final usersSnapshot = await _usersRef.get();
      if (usersSnapshot.docs.isEmpty) {
        await _insertarUsuariosPorDefecto();
      }
    } catch (e) {
      print('❌ Error inicializando datos por defecto: $e');
    }
  }

  static Future<void> _insertarCategoriasPorDefecto() async {
    final categorias = [
      {
        'nombre': 'Electrónicos', 
        'descripcion': 'Dispositivos y componentes electrónicos',
        'color': 'FF5722'
      },
      {
        'nombre': 'Ropa', 
        'descripcion': 'Prendas de vestir y accesorios',
        'color': '2196F3'
      },
      {
        'nombre': 'Hogar', 
        'descripcion': 'Artículos para el hogar',
        'color': '4CAF50'
      },
      {
        'nombre': 'Deportes', 
        'descripcion': 'Equipamiento deportivo',
        'color': '9C27B0'
      },
      {
        'nombre': 'Libros', 
        'descripcion': 'Libros y material de lectura',
        'color': '607D8B'
      },
      {
        'nombre': 'Otros', 
        'descripcion': 'Otras categorías',
        'color': '795548'
      },
    ];

    for (final categoria in categorias) {
      await _categoriesRef.add(categoria);
    }
    print('✅ ${categorias.length} categorías por defecto insertadas');
  }

  static Future<void> _insertarUsuariosPorDefecto() async {
    final usuarios = [
      {
        'username': 'admin',
        'password': 'admin123',
        'role': 'admin',
        'nombre': 'Administrador',
        'email': 'admin@inventario.com'
      },
      {
        'username': 'empleado',
        'password': 'empleado123',
        'role': 'empleado',
        'nombre': 'Empleado',
        'email': 'empleado@inventario.com'
      },
    ];

    for (final usuario in usuarios) {
      await _usersRef.add(usuario);
    }
    print('✅ ${usuarios.length} usuarios por defecto insertados');
  }

  // ✅ MÉTODO PARA VERIFICAR ESTRUCTURA DE DATOS
  static Future<void> checkDataStructure() async {
    try {
      print('🔍 Verificando estructura de datos en Firestore...');
      
      final categorias = await getCategorias();
      print('📊 Categorías en Firestore: ${categorias.length}');
      
      final items = await getAllItems();
      print('📦 Items en Firestore: ${items.length}');
      
      final usersCount = await _usersRef.count().get();
      print('👥 Usuarios en Firestore: ${usersCount.count}');
      
    } catch (e) {
      print('❌ Error verificando estructura de datos: $e');
    }
  }
}