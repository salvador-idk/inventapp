// services/data_repository.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_helper.dart';
import 'firestore_service.dart';
import '../models/item_model.dart';
import '../models/categoria_model.dart';
import '../models/user_model.dart';
import '../models/audit_model.dart';
import '../models/ticket_model.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final bool isWeb = kIsWeb;

  // ========== STREAM METHODS ==========
  Stream<List<Item>> getItemsStream() {
    if (isWeb) {
      return FirestoreService.getItemsStream();
    } else {
      // Para SQLite, convertimos Future a Stream periódico
      return Stream.periodic(Duration(seconds: 5))
          .asyncMap((_) => _databaseHelper.getItems())
          .distinct();
    }
  }

  // ========== ITEM METHODS ==========
  Future<List<Item>> getItems() async {
    if (isWeb) {
      return await FirestoreService.getAllItems();
    } else {
      return await _databaseHelper.getItems();
    }
  }

  Future<String> insertItem(Item item) async {
    if (isWeb) {
      return await FirestoreService.addItem(item);
    } else {
      final id = await _databaseHelper.insertItem(item);
      return id.toString();
    }
  }

  Future<void> updateItem(Item item) async {
    if (isWeb) {
      await FirestoreService.updateItem(item);
    } else {
      await _databaseHelper.updateItem(item);
    }
  }

  Future<void> deleteItem(String id) async {
    if (isWeb) {
      await FirestoreService.deleteItem(id);
    } else {
      await _databaseHelper.deleteItemByStringId(id);
    }
  }

  Future<Item?> getItemById(String id) async {
    if (isWeb) {
      return await FirestoreService.getItemById(id);
    } else {
      final intId = int.tryParse(id);
      if (intId == null) return null;
      return await _databaseHelper.getItemById(intId);
    }
  }

  Future<List<Item>> searchItems(String query) async {
    if (isWeb) {
      return await FirestoreService.searchItems(query);
    } else {
      return await _databaseHelper.searchItems(query);
    }
  }

  Future<bool> itemExists(String serial, {String? excludeItemId}) async {
    if (isWeb) {
      return await FirestoreService.itemExists(serial, excludeItemId: excludeItemId);
    } else {
      return await _databaseHelper.itemExists(serial, excludeItemId: excludeItemId);
    }
  }

  // ========== CATEGORY METHODS ==========
  Future<List<Categoria>> getCategorias() async {
    if (isWeb) {
      return await FirestoreService.getCategorias();
    } else {
      return await _databaseHelper.getCategorias();
    }
  }

  Future<String> insertCategoria(Categoria categoria) async {
    if (isWeb) {
      return await FirestoreService.addCategoria(categoria);
    } else {
      final id = await _databaseHelper.insertCategoria(categoria);
      return id.toString();
    }
  }

  Future<void> updateCategoria(Categoria categoria) async {
    if (isWeb) {
      await FirestoreService.updateCategoria(categoria);
    } else {
      await _databaseHelper.updateCategoria(categoria);
    }
  }

  Future<void> deleteCategoria(String id) async {
    if (isWeb) {
      await FirestoreService.deleteCategoria(id);
    } else {
      final intId = int.tryParse(id);
      if (intId != null) {
        await _databaseHelper.deleteCategoria(intId);
      }
    }
  }

  Future<Categoria?> getCategoriaById(String id) async {
    if (isWeb) {
      return await FirestoreService.getCategoriaById(id);
    } else {
      final intId = int.tryParse(id);
      if (intId == null) return null;
      return await _databaseHelper.getCategoriaById(intId);
    }
  }

  // ========== TICKET METHODS ==========
  Future<String> insertTicket(TicketVenta ticket) async {
    if (isWeb) {
      return await FirestoreService.addTicket(ticket);
    } else {
      final id = await _databaseHelper.insertTicket(ticket);
      return id.toString();
    }
  }

  Future<List<TicketVenta>> getTickets() async {
    if (isWeb) {
      return await FirestoreService.getTickets();
    } else {
      return await _databaseHelper.getTickets();
    }
  }

  // ========== USER METHODS ==========
  Future<AppUser?> getUserByUsername(String username) async {
    if (isWeb) {
      return await FirestoreService.getUserByUsername(username);
    } else {
      return await _databaseHelper.getUserByUsername(username);
    }
  }

  // ========== AUDIT METHODS ==========
  Future<String> insertAuditLog(AuditLog auditLog) async {
    if (isWeb) {
      return await FirestoreService.addAuditLog(auditLog);
    } else {
      final id = await _databaseHelper.insertAuditLog(auditLog);
      return id.toString();
    }
  }

  Future<List<AuditLog>> getAuditLogs({DateTime? startDate, DateTime? endDate}) async {
    if (isWeb) {
      return await FirestoreService.getAuditLogs(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      return await _databaseHelper.getAuditLogs(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  // ========== STATISTICS METHODS ==========
  Future<int> getItemsCount() async {
    if (isWeb) {
      return await FirestoreService.getItemsCount();
    } else {
      return await _databaseHelper.getItemsCount();
    }
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    if (isWeb) {
      return await FirestoreService.getInventoryStats();
    } else {
      final count = await _databaseHelper.getItemsCount();
      return {
        'totalItems': count,
        'lowStockItems': 0,
        'lastUpdated': DateTime.now(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAuditStatsByMonth() async {
    if (isWeb) {
      // Implementar para Firestore si es necesario
      return [];
    } else {
      return await _databaseHelper.getAuditStatsByMonth();
    }
  }

  // ========== UTILITY METHODS ==========
  Future<List<String>> getSearchSuggestions(String query) async {
    if (isWeb) {
      // Implementar para Firestore si es necesario
      return [];
    } else {
      return await _databaseHelper.getSearchSuggestions(query);
    }
  }

  Future<void> initializeApp() async {
    if (isWeb) {
      // Inicialización para web (Firestore)
      final connected = await FirestoreService.testConnection();
      if (connected) {
        await FirestoreService.initializeDefaultData();
        print('✅ Firestore inicializado exitosamente');
      } else {
        print('❌ No se pudo conectar a Firestore');
      }
    } else {
      // Para SQLite, ya se inicializa automáticamente
      print('✅ SQLite inicializado');
    }
  }

  Future<void> close() async {
    if (!isWeb) {
      await _databaseHelper.close();
    }
  }
}