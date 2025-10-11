import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/item_model.dart';

class FirestoreService {
  // ✅ DEFINE FIRESTORE REFERENCES
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _itemsRef = _firestore.collection('items');
  
  // ✅ STREAM METHODS
  static Stream<List<Item>> getItemsStream() {
    try {
      return _itemsRef
          .orderBy('nombre')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Item.fromFirestore(doc))
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

  // ✅ QUERY METHODS
  static Future<Item?> getItemById(String itemId) async {
    try {
      if (itemId.isEmpty) return null;
      
      final doc = await _itemsRef.doc(itemId).get();
      
      if (doc.exists) {
        return Item.fromFirestore(doc);
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
          .map((doc) => Item.fromFirestore(doc))
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
          final item = Item.fromFirestore(doc);
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
    return aggregateQuery.count ?? 0; // ✅ PROVIDE DEFAULT VALUE
  } catch (e) {
    print('❌ Error obteniendo conteo de items: $e');
    return 0; // ✅ RETURN 0 ON ERROR
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

  // ✅ UTILITY METHODS
  static Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').limit(1).get();
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
}