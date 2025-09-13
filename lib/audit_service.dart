import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'auth_provider.dart';
import 'audit_model.dart';

class AuditService {
  static Future<void> logAction({
    required BuildContext context,
    required String action,
    required String tableName,
    required int recordId,
    String? oldValues,
    String? newValues,
    required String description,
  }) async {
    try {

      if(!context.mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dbHelper = DatabaseHelper();

      // Crear objeto AuditLog
      final auditLog = AuditLog(
        userId: auth.currentUser?.id ?? 0,
        username: auth.currentUser?.username ?? 'unknown',
        action: action,
        tableName: tableName,
        recordId: recordId,
        oldValues: oldValues,
        newValues: newValues,
        description: description,
        createdAt: DateTime.now(),
      );
      
      // Insertar directamente en la base de datos
      await dbHelper.insertAuditLog(auditLog);
    } catch (e) {
      print('❌ Error en logAction: $e');
    }
  }

  // Métodos específicos para diferentes acciones
  static Future<void> logItemUpdate(BuildContext context, 
      {required int itemId, required String oldData, required String newData, required String itemName}) async {
        if(!context.mounted) return;
    await logAction(
      context: context,
      action: 'UPDATE',
      tableName: 'items',
      recordId: itemId,
      oldValues: oldData,
      newValues: newData,
      description: 'Actualización de artículo: $itemName',
    );
  }

  static Future<void> logItemCreate(BuildContext context, 
      {required int itemId, required String itemName}) async {
        if(!context.mounted) return;
    await logAction(
      context: context,
      action: 'CREATE',
      tableName: 'items',
      recordId: itemId,
      description: 'Creación de artículo: $itemName',
    );
  }

  static Future<void> logItemDelete(BuildContext context, 
      {required int itemId, required String itemName}) async {
        if(!context.mounted) return;
    await logAction(
      context: context,
      action: 'DELETE',
      tableName: 'items',
      recordId: itemId,
      description: 'Eliminación de artículo: $itemName',
    );
  }

  static Future<void> logLogin(BuildContext context) async {
    if(!context.mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await logAction(
      context: context,
      action: 'LOGIN',
      tableName: 'users',
      recordId: auth.currentUser?.id ?? 0,
      description: 'Inicio de sesión',
    );
  }

  static Future<void> logLogout(BuildContext context) async {
    if(!context.mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await logAction(
      context: context,
      action: 'LOGOUT',
      tableName: 'users',
      recordId: auth.currentUser?.id ?? 0,
      description: 'Cierre de sesión',
    );
  }

  static Future<void> logSale(BuildContext context, 
      {required int ticketId, required double total}) async {
        if(!context.mounted) return;
    await logAction(
      context: context,
      action: 'CREATE',
      tableName: 'tickets',
      recordId: ticketId,
      description: 'Venta realizada - Total: \$${total.toStringAsFixed(2)}',
    );
  }
}