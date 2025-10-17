import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  int? id;
  int userId;
  String username;
  String action;        // 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT'
  String tableName;     // 'items', 'tickets', 'users'
  int recordId;         // ID del registro afectado
  String? oldValues;    // Valores anteriores (JSON)
  String? newValues;    // Valores nuevos (JSON)
  String description;   // Descripción legible
  DateTime createdAt;

  AuditLog({
    this.id,
    required this.userId,
    required this.username,
    required this.action,
    required this.tableName,
    required this.recordId,
    this.oldValues,
    this.newValues,
    required this.description,
    required this.createdAt,
  });

  // ✅ FROM FIRESTORE - NUEVO MÉTODO
  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: null, // Firestore usa su propio ID, no necesitamos mapearlo aquí
      userId: _parseInt(data['userId']) ?? 0,
      username: data['username'] ?? '',
      action: data['action'] ?? '',
      tableName: data['tableName'] ?? '',
      recordId: _parseInt(data['recordId']) ?? 0,
      oldValues: data['oldValues'],
      newValues: data['newValues'],
      description: data['description'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
    );
  }

  // ✅ TO FIRESTORE - NUEVO MÉTODO
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'action': action,
      'tableName': tableName,
      'recordId': recordId,
      'oldValues': oldValues,
      'newValues': newValues,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ MÉTODOS EXISTENTES (mantener igual)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'old_values': oldValues,
      'new_values': newValues,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      userId: map['user_id'],
      username: map['username'],
      action: map['action'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      oldValues: map['old_values'],
      newValues: map['new_values'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // ✅ MÉTODOS UTILITARIOS EXISTENTES (mantener igual)
  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(createdAt);
  }

  String get actionText {
    switch (action) {
      case 'CREATE': return 'Creación';
      case 'UPDATE': return 'Actualización';
      case 'DELETE': return 'Eliminación';
      case 'LOGIN': return 'Inicio de sesión';
      case 'LOGOUT': return 'Cierre de sesión';
      default: return action;
    }
  }

  String get tableText {
    switch (tableName) {
      case 'items': return 'Artículos';
      case 'tickets': return 'Tickets';
      case 'users': return 'Usuarios';
      default: return tableName;
    }
  }

  // ✅ MÉTODOS UTILITARIOS PRIVADOS PARA FIRESTORE
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // ✅ MÉTODO PARA CREAR LOGS DE AUDITORÍA FÁCILMENTE
  static AuditLog create({
    required int userId,
    required String username,
    required String action,
    required String tableName,
    required int recordId,
    String? oldValues,
    String? newValues,
    required String description,
  }) {
    return AuditLog(
      userId: userId,
      username: username,
      action: action,
      tableName: tableName,
      recordId: recordId,
      oldValues: oldValues,
      newValues: newValues,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  // ✅ MÉTODO PARA LOGS DE USUARIO
  static AuditLog userLogin(int userId, String username) {
    return AuditLog(
      userId: userId,
      username: username,
      action: 'LOGIN',
      tableName: 'users',
      recordId: userId,
      description: 'Usuario $username inició sesión',
      createdAt: DateTime.now(),
    );
  }

  static AuditLog userLogout(int userId, String username) {
    return AuditLog(
      userId: userId,
      username: username,
      action: 'LOGOUT',
      tableName: 'users',
      recordId: userId,
      description: 'Usuario $username cerró sesión',
      createdAt: DateTime.now(),
    );
  }

  // ✅ MÉTODO PARA LOGS DE ITEMS
  static AuditLog itemCreated(int userId, String username, int itemId, String itemName) {
    return AuditLog(
      userId: userId,
      username: username,
      action: 'CREATE',
      tableName: 'items',
      recordId: itemId,
      description: 'Usuario $username creó el artículo: $itemName',
      createdAt: DateTime.now(),
    );
  }

  static AuditLog itemUpdated(int userId, String username, int itemId, String itemName) {
    return AuditLog(
      userId: userId,
      username: username,
      action: 'UPDATE',
      tableName: 'items',
      recordId: itemId,
      description: 'Usuario $username actualizó el artículo: $itemName',
      createdAt: DateTime.now(),
    );
  }

  static AuditLog itemDeleted(int userId, String username, int itemId, String itemName) {
    return AuditLog(
      userId: userId,
      username: username,
      action: 'DELETE',
      tableName: 'items',
      recordId: itemId,
      description: 'Usuario $username eliminó el artículo: $itemName',
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AuditLog{id: $id, user: $username, action: $action, table: $tableName, record: $recordId, desc: $description}';
  }
}