import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/services/carrito_service.dart'; // ✅ CORREGIR IMPORT
import '/models/item_model.dart';
import '/models/cart_item.dart'; // ✅ AGREGAR IMPORT
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
    _cargarCarritoPersistente();
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

  // ✅ NUEVO: Cargar carrito guardado
  Future<void> _cargarCarritoPersistente() async {
    try {
      final carritoGuardado = await CarritoService.cargarCarrito();
      if (carritoGuardado.isNotEmpty) {
        // Primero cargar items para poder reconstruir el carrito
        await _cargarItems();
        
        setState(() {
          // Reconstruir carrito desde base de datos
          for (final cartItem in carritoGuardado) {
            try {
              final item = _items.firstWhere(
                (item) => item.id.toString() == cartItem.itemId,
              );
              
              if (item.id != null) {
                _cantidadesCarrito[item.id!] = cartItem.cantidad;
                if (!_carrito.any((i) => i.id == item.id)) {
                  _carrito.add(item);
                }
              }
            } catch (e) {
              print('Item no encontrado en inventario: ${cartItem.itemId}');
            }
          }
        });
      }
    } catch (e) {
      print('Error cargando carrito: $e');
    }
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
      _guardarCarritoPersistente(); // ✅ GUARDAR
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cantidad ${item.nombre} agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarDelCarrito(int itemId) {
    setState(() {
      _cantidadesCarrito.remove(itemId);
      _carrito.removeWhere((item) => item.id == itemId);
      _guardarCarritoPersistente(); // ✅ GUARDAR
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto eliminado del carrito'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ NUEVO: Guardar carrito
  Future<void> _guardarCarritoPersistente() async {
    try {
      final cartItems = _carrito.map((item) => CartItem(
        id: item.id.toString(),
        itemId: item.id.toString(),
        nombre: item.nombre,
        precio: item.precio,
        cantidad: _cantidadesCarrito[item.id!]!,
        imagenUrl: item.imagenPath,
      )).toList();
      
      await CarritoService.guardarCarrito(cartItems);
    } catch (e) {
      print('Error guardando carrito: $e');
    }
  }

  double _calcularTotal() {
    double total = 0;
    for (var item in _carrito) {
      total += item.precio * _cantidadesCarrito[item.id!]!;
    }
    return total;
  }

  int _calcularTotalItems() {
    int total = 0;
    for (var cantidad in _cantidadesCarrito.values) {
      total += cantidad;
    }
    return total;
  }

  Future<void> _realizarCompra() async {
    if (_carrito.isEmpty) return;

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text(
          '¿Confirmar compra de ${_calcularTotalItems()} productos por un total de \$${_calcularTotal().toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

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

      // ✅ LIMPIAR CARRITO DESPUÉS DE COMPRA EXITOSA
      await CarritoService.limpiarCarrito();
      
      setState(() {
        _carrito.clear();
        _cantidadesCarrito.clear();
      });

      await _cargarItems();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Compra realizada y ticket guardado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al procesar compra: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
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
    final enCarrito = _cantidadesCarrito.containsKey(item.id);
    final cantidadEnCarrito = enCarrito ? _cantidadesCarrito[item.id]! : 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          item.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enCarrito ? Colors.blue : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disponible: ${item.cantidad} - Precio: \$${item.precio.toStringAsFixed(2)}'),
            if (enCarrito)
              Text(
                'En carrito: $cantidadEnCarrito',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
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
              icon: Icon(Icons.add_shopping_cart, color: Colors.blue),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text('Agregar 1 unidad')),
                const PopupMenuItem(value: 2, child: Text('Agregar 2 unidades')),
                const PopupMenuItem(value: 5, child: Text('Agregar 5 unidades')),
                const PopupMenuItem(value: 10, child: Text('Agregar 10 unidades')),
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
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Carrito (${_calcularTotalItems()} productos)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ..._carrito.map((item) {
                final cantidad = _cantidadesCarrito[item.id!]!;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_basket, color: Colors.green),
                    title: Text(item.nombre),
                    subtitle: Text('$cantidad × \$${item.precio.toStringAsFixed(2)} = \$${(item.precio * cantidad).toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () {
                            if (cantidad > 1) {
                              _agregarAlCarrito(item, -1);
                            } else {
                              _eliminarDelCarrito(item.id!);
                            }
                          },
                        ),
                        Text(
                          cantidad.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => _agregarAlCarrito(item, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarDelCarrito(item.id!),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_calcularTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _realizarCompra,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Realizar Compra e Imprimir Ticket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Vaciar Carrito'),
                        content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await CarritoService.limpiarCarrito();
                              setState(() {
                                _carrito.clear();
                                _cantidadesCarrito.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Vaciar Carrito', style: TextStyle(color: Colors.red)),
                ),
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
                              : const Text('No hay productos disponibles'),
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