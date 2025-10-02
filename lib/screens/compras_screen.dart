import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/models/item_model.dart';
import '/utils/ticket_service.dart';
import '/widgets/search_bar.dart';
import '/models/ticket_model.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({Key? key}) : super(key: key);

  @override
  _ComprasScreenState createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  List<Item> _carrito = [];
  final Map<int, int> _cantidadesCarrito = {};
  bool _cargando = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarItems();
  }

  Future<void> _cargarItems() async {
    final dbHelper = DatabaseHelper();
    final items = await dbHelper.getItems();
    setState(() {
      _items = items.where((item) => item.cantidad > 0).toList();
      _filteredItems = _items;
      _cargando = false;
    });
  }

  void _agregarAlCarrito(Item item, int cantidad) {
    if (cantidad <= 0 || cantidad > item.cantidad) return;

    setState(() {
      if (_cantidadesCarrito.containsKey(item.id!)) {
        _cantidadesCarrito[item.id!] = _cantidadesCarrito[item.id!]! + cantidad;
      } else {
        _cantidadesCarrito[item.id!] = cantidad;
        _carrito.add(item);
      }
    });
  }

  void _eliminarDelCarrito(int itemId) {
    setState(() {
      _cantidadesCarrito.remove(itemId);
      _carrito.removeWhere((item) => item.id == itemId);
    });
  }

  double _calcularTotal() {
    double total = 0;
    for (var item in _carrito) {
      total += item.precio * _cantidadesCarrito[item.id!]!;
    }
    return total;
  }

  Future<void> _realizarCompra() async {
    if (_carrito.isEmpty) return;

    final dbHelper = DatabaseHelper();

    try {
      // Crear items para el ticket
      final itemsVenta = _carrito.map((item) {
        final cantidad = _cantidadesCarrito[item.id!]!;
        return ItemVenta(
          nombre: item.nombre,
          cantidad: cantidad,
          precio: item.precio,
          total: item.precio * cantidad,
        );
      }).toList();

      // Calcular total
      final total = _calcularTotal();

      // Crear ticket
      final ticket = TicketVenta(
        fecha: DateTime.now(),
        total: total,
        items: itemsVenta,
        folio: TicketService.generarFolio(),
      );

      // Actualizar inventario
      for (var item in _carrito) {
        final cantidadComprada = _cantidadesCarrito[item.id!]!;
        final itemActualizado = item.copyWith(
          cantidad: item.cantidad - cantidadComprada,
        );
        await dbHelper.updateItem(itemActualizado);
      }

      // Guardar ticket en base de datos
      await dbHelper.insertTicket(ticket);

      // Imprimir ticket
      await TicketService.imprimirTicket(ticket, context);

      setState(() {
        _carrito.clear();
        _cantidadesCarrito.clear();
      });

      await _cargarItems();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra realizada y ticket guardado')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar compra: $e')),
      );
    }
  }

  void _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _cargando = true;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredItems = _items;
        _cargando = false;
      });
    } else {
      final dbHelper = DatabaseHelper();
      final results = await dbHelper.searchItems(query);
      setState(() {
        _filteredItems = results.where((item) => item.cantidad > 0).toList();
        _cargando = false;
      });
    }
  }

  void _onSuggestionSelected(String suggestion) {
    String searchTerm = suggestion;
    if (suggestion.startsWith('Serial: ')) {
      searchTerm = suggestion.replaceFirst('Serial: ', '');
    } else if (suggestion.startsWith('ID: ')) {
      searchTerm = suggestion.replaceFirst('ID: ', '');
    }
    _onSearch(searchTerm);
  }

  Widget _buildProductCard(Item item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(item.nombre),
        subtitle: Text('Disponible: ${item.cantidad} - Precio: \$${item.precio.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para agregar una unidad
            IconButton(
              icon: Icon(Icons.add, color: Colors.green),
              onPressed: () => _agregarAlCarrito(item, 1),
            ),
            // Botón para agregar múltiples unidades
            PopupMenuButton<int>(
              icon: Icon(Icons.add_shopping_cart),
              itemBuilder: (context) => [
                PopupMenuItem(value: 1, child: Text('Agregar 1 unidad')),
                PopupMenuItem(value: 2, child: Text('Agregar 2 unidades')),
                PopupMenuItem(value: 5, child: Text('Agregar 5 unidades')),
                PopupMenuItem(value: 10, child: Text('Agregar 10 unidades')),
              ],
              onSelected: (cantidad) => _agregarAlCarrito(item, cantidad),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Column(
      children: [
        const Divider(),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Carrito de Compra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._carrito.map((item) {
                final cantidad = _cantidadesCarrito[item.id!]!;
                return ListTile(
                  title: Text(item.nombre),
                  subtitle: Text('Cantidad: $cantidad - Total: \$${(item.precio * cantidad).toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarDelCarrito(item.id!),
                  ),
                );
              }),
              Text(
                'Total: \$${_calcularTotal().toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _realizarCompra,
                child: const Text('Realizar Compra e Imprimir Ticket'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                SearchBarWidget(
                  onSearch: _onSearch,
                  onSuggestionSelected: _onSuggestionSelected,
                ),
                
                // Título
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Productos Disponibles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Lista de productos filtrados
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: _searchQuery.isNotEmpty
                              ? Text('No se encontraron resultados para "$_searchQuery"')
                              : Text('No hay productos disponibles'),
                        )
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildProductCard(item);
                          },
                        ),
                ),
                
                // Sección del carrito
                if (_carrito.isNotEmpty) _buildCartSection(),
              ],
            ),
    );
  }
}