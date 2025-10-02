import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '/models/audit_model.dart';

class ExcelExportService {
  static Future<void> exportAuditLogsToExcel(List<AuditLog> logs) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Auditoría'];

      // Encabezados
      sheet.appendRow([
        'ID',
        'Fecha y Hora',
        'Usuario',
        'Acción',
        'Tabla',
        'ID Registro',
        'Descripción',
        'Valores Anteriores',
        'Valores Nuevos'
      ]);

      // Datos
      for (final log in logs) {
        sheet.appendRow([
          log.id,
          log.formattedDate,
          log.username,
          log.actionText,
          log.tableText,
          log.recordId,
          log.description,
          log.oldValues ?? 'N/A',
          log.newValues ?? 'N/A'
        ]);
      }

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/auditoria_$date.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // Abrir el archivo
      await OpenFile.open(filePath);

    } catch (e) {
      print('❌ Error exportando a Excel: $e');
      rethrow;
    }
  }

  static Future<void> exportAuditStatsToExcel(List<Map<String, dynamic>> stats) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Estadísticas'];

      // Encabezados
      sheet.appendRow(['Mes', 'Acción', 'Cantidad']);

      // Datos
      for (final stat in stats) {
        sheet.appendRow([
          stat['month'],
          _getActionText(stat['action']),
          stat['count']
        ]);
      }

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/estadisticas_auditoria_$date.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      await OpenFile.open(filePath);

    } catch (e) {
      print('❌ Error exportando estadísticas: $e');
      rethrow;
    }
  }

  static String _getActionText(String action) {
    switch (action) {
      case 'CREATE': return 'Creaciones';
      case 'UPDATE': return 'Actualizaciones';
      case 'DELETE': return 'Eliminaciones';
      case 'LOGIN': return 'Inicios de sesión';
      case 'LOGOUT': return 'Cierres de sesión';
      default: return action;
    }
  }
}