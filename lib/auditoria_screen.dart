import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // ← Agrega esta línea
import 'database_helper.dart';
import 'audit_model.dart';
import 'excel_export_service.dart';
import 'auth_provider.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({Key? key}) : super(key: key);

  @override
  _AuditoriaScreenState createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<AuditLog> _logs = [];
  List<Map<String, dynamic>> _stats = [];
  bool _loading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final logs = await _dbHelper.getAuditLogs(
        startDate: _startDate,
        endDate: _endDate,
      );
      final stats = await _dbHelper.getAuditStatsByMonth();
      
      setState(() {
        _logs = logs;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  Future<void> _exportToExcel() async {
    try {
      await ExcelExportService.exportAuditLogsToExcel(_logs);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exportado a Excel exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  Future<void> _exportStatsToExcel() async {
    try {
      await ExcelExportService.exportAuditStatsToExcel(_stats);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estadísticas exportadas exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar estadísticas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Seleccionar rango de fechas',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToExcel,
            tooltip: 'Exportar a Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_stats.isNotEmpty) _buildStatsSection(),
                Expanded(
                  child: _logs.isEmpty
                      ? const Center(child: Text('No hay registros de auditoría'))
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) => _buildLogCard(_logs[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsSection() {
    final statsSummary = _prepareStatsSummary();
    final maxValue = statsSummary.values.reduce((a, b) => a > b ? a : b).toDouble();
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de Actividades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: BarChartPainter(
                  data: statsSummary,
                  maxValue: maxValue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _exportStatsToExcel,
              child: const Text('Exportar Estadísticas a Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildLegendItem('Creaciones', Colors.green),
        _buildLegendItem('Actualizaciones', Colors.blue),
        _buildLegendItem('Eliminaciones', Colors.red),
        _buildLegendItem('Logins', Colors.purple),
        _buildLegendItem('Logouts', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Map<String, int> _prepareStatsSummary() {
    final Map<String, int> summary = {
      'Creaciones': 0,
      'Actualizaciones': 0,
      'Eliminaciones': 0,
      'Logins': 0,
      'Logouts': 0,
    };

    for (final stat in _stats) {
      final action = stat['action'] as String;
      final count = stat['count'] as int;

      switch (action) {
        case 'CREATE': summary['Creaciones'] = summary['Creaciones']! + count; break;
        case 'UPDATE': summary['Actualizaciones'] = summary['Actualizaciones']! + count; break;
        case 'DELETE': summary['Eliminaciones'] = summary['Eliminaciones']! + count; break;
        case 'LOGIN': summary['Logins'] = summary['Logins']! + count; break;
        case 'LOGOUT': summary['Logouts'] = summary['Logouts']! + count; break;
      }
    }

    return summary;
  }

  Widget _buildLogCard(AuditLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(log.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por: ${log.username}'),
            Text('Fecha: ${log.formattedDate}'),
            Text('Acción: ${log.actionText} - ${log.tableText}'),
          ],
        ),
        trailing: Icon(_getActionIcon(log.action), color: _getActionColor(log.action)),
        onTap: () => _showLogDetails(log),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'CREATE': return Icons.add_circle;
      case 'UPDATE': return Icons.edit;
      case 'DELETE': return Icons.delete;
      case 'LOGIN': return Icons.login;
      case 'LOGOUT': return Icons.logout;
      default: return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'CREATE': return Colors.green;
      case 'UPDATE': return Colors.blue;
      case 'DELETE': return Colors.red;
      case 'LOGIN': return Colors.purple;
      case 'LOGOUT': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showLogDetails(AuditLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Auditoría'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${log.username}'),
              Text('Fecha: ${log.formattedDate}'),
              Text('Acción: ${log.actionText}'),
              Text('Tabla: ${log.tableText}'),
              Text('ID Registro: ${log.recordId}'),
              Text('Descripción: ${log.description}'),
              if (log.oldValues != null) ...[
                const SizedBox(height: 8),
                const Text('Valores anteriores:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.oldValues!),
              ],
              if (log.newValues != null) ...[
                const SizedBox(height: 8),
                const Text('Valores nuevos:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.newValues!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final Map<String, int> data;
  final double maxValue;

  BarChartPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textStyle = TextStyle(color: Colors.black, fontSize: 12);

    final barWidth = size.width / data.length - 20;
    final maxBarHeight = size.height - 60;
    final barSpacing = 20.0;

    var xPos = 30.0;

    // Dibujar ejes
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(20, size.height - 40),
      Offset(size.width, size.height - 40),
      paint,
    );
    canvas.drawLine(
      Offset(20, 20),
      Offset(20, size.height - 40),
      paint,
    );

    // Dibujar barras
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.orange,
    ];

    var colorIndex = 0;
    
    data.forEach((label, value) {
      final barHeight = (value / maxValue) * maxBarHeight;
      final yPos = size.height - 40 - barHeight;

      // Dibujar barra
      paint.color = colors[colorIndex % colors.length];
      canvas.drawRect(
        Rect.fromLTWH(xPos, yPos, barWidth, barHeight),
        paint,
      );

      // Dibujar valor - USANDO SETTERS
      final valuePainter = TextPainter();
      valuePainter.textDirection = ui.TextDirection.ltr; // ←Setter
      valuePainter.text = TextSpan(
        text: value.toString(),
        style: textStyle,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas,
        Offset(xPos + barWidth / 2 - valuePainter.width / 2, yPos - 20),
      );

      // Dibujar label - USANDO SETTERS
      final labelPainter = TextPainter();
      labelPainter.textDirection = ui.TextDirection.ltr; // ←Setter
      labelPainter.text = TextSpan(
        text: _abbreviateLabel(label),
        style: textStyle,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(xPos + barWidth / 2 - labelPainter.width / 2, size.height - 25),
      );

      xPos += barWidth + barSpacing;
      colorIndex++;
    });
  }

  String _abbreviateLabel(String label) {
    if (label.length <= 8) return label;
    return label.substring(0, 8) + '.';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}