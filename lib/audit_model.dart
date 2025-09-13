import 'package:intl/intl.dart';

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
}