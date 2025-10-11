import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/models/item_model.dart';
import '/models/ticket_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _cargarDatosDashboard();
  }

  Future<Map<String, dynamic>> _cargarDatosDashboard() async {
    final dbHelper = DatabaseHelper();
    
    final items = await dbHelper.getItems();
    final tickets = await dbHelper.getTickets();
    final hoy = DateTime.now();

    // Cálculo de métricas
    final totalItems = items.length;
    final valorTotal = items.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
    final itemsStockBajo = items.where((item) => item.cantidad <= 5).length;
    final ventasHoy = tickets.where((ticket) => 
        ticket.fecha.year == hoy.year &&
        ticket.fecha.month == hoy.month && 
        ticket.fecha.day == hoy.day).length;
    final ingresosHoy = tickets.where((ticket) => 
        ticket.fecha.year == hoy.year &&
        ticket.fecha.month == hoy.month && 
        ticket.fecha.day == hoy.day)
        .fold(0.0, (sum, ticket) => sum + ticket.total);
    final itemsSinImagen = items.where((item) => item.imagenUrl == null).length;

    return {
      'totalItems': totalItems,
      'valorTotal': valorTotal,
      'itemsStockBajo': itemsStockBajo,
      'ventasHoy': ventasHoy,
      'ingresosHoy': ingresosHoy,
      'itemsSinImagen': itemsSinImagen,
      'items': items,
      'tickets': tickets,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ✅ TARJETAS DE MÉTRICAS PRINCIPALES
                _buildMetricasPrincipales(data),
                
                const SizedBox(height: 20),
                
                // ✅ ALERTAS DE STOCK BAJO
                if (data['itemsStockBajo'] > 0)
                  _buildAlertaStockBajo(data),
                
                const SizedBox(height: 20),
                
                // ✅ GRÁFICO SIMPLE DE DISTRIBUCIÓN
                _buildGraficoDistribucion(data),
                
                const SizedBox(height: 20),
                
                // ✅ ITEMS MÁS VALIOSOS
                _buildItemsMasValiosos(data),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ TARJETAS DE MÉTRICAS PRINCIPALES
  Widget _buildMetricasPrincipales(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricaCard(
          'Total Items',
          data['totalItems'].toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildMetricaCard(
          'Valor Inventario',
          '\$${data['valorTotal'].toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricaCard(
          'Stock Bajo',
          data['itemsStockBajo'].toString(),
          Icons.warning,
          Colors.orange,
        ),
        _buildMetricaCard(
          'Ventas Hoy',
          data['ventasHoy'].toString(),
          Icons.shopping_cart,
          Colors.purple,
        ),
        _buildMetricaCard(
          'Ingresos Hoy',
          '\$${data['ingresosHoy'].toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.teal,
        ),
        _buildMetricaCard(
          'Sin Imagen',
          data['itemsSinImagen'].toString(),
          Icons.photo,
          Colors.red,
        ),
      ],
    );
  }

  // ✅ TARJETA INDIVIDUAL DE MÉTRICA
  Widget _buildMetricaCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ALERTA DE STOCK BAJO
  Widget _buildAlertaStockBajo(Map<String, dynamic> data) {
    final items = data['items'] as List<Item>;
    final itemsStockBajo = items.where((item) => item.cantidad <= 5).toList();
    
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Text(
                  'Alerta: Stock Bajo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${itemsStockBajo.length} productos tienen stock bajo (≤ 5 unidades)',
              style: TextStyle(color: Colors.orange[700]),
            ),
            const SizedBox(height: 8),
            ...itemsStockBajo.take(3).map((item) => ListTile(
              leading: const Icon(Icons.inventory_2, size: 20),
              title: Text(item.nombre),
              subtitle: Text('Stock: ${item.cantidad} unidades'),
              trailing: Text('\$${item.precio.toStringAsFixed(2)}'),
            )),
            if (itemsStockBajo.length > 3)
              Text(
                '... y ${itemsStockBajo.length - 3} más',
                style: TextStyle(color: Colors.orange[600], fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ GRÁFICO SIMPLE DE DISTRIBUCIÓN
  Widget _buildGraficoDistribucion(Map<String, dynamic> data) {
    final items = data['items'] as List<Item>;
    
    // Categorizar por rangos de precio
    final baratos = items.where((item) => item.precio < 50).length;
    final medios = items.where((item) => item.precio >= 50 && item.precio < 200).length;
    final caros = items.where((item) => item.precio >= 200).length;
    
    final maxCount = [baratos, medios, caros].reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por Precio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBarra('Baratos (<\$50)', baratos, maxCount, Colors.green),
            _buildBarra('Medios (\$50-\$200)', medios, maxCount, Colors.blue),
            _buildBarra('Caros (≥\$200)', caros, maxCount, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildBarra(String label, int value, int maxValue, Color color) {
    final porcentaje = maxValue > 0 ? value / maxValue : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  height: 20,
                  width: porcentaje * 200, // Ancho máximo relativo
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 2,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ITEMS MÁS VALIOSOS
  Widget _buildItemsMasValiosos(Map<String, dynamic> data) {
    final items = data['items'] as List<Item>;
    final itemsMasValiosos = items..sort((a, b) => (b.precio * b.cantidad).compareTo(a.precio * a.cantidad));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items Más Valiosos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...itemsMasValiosos.take(5).map((item) => ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(item.nombre),
              subtitle: Text('${item.cantidad} unidades × \$${item.precio.toStringAsFixed(2)}'),
              trailing: Text(
                '\$${(item.precio * item.cantidad).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),
      ),
    );
  }
}