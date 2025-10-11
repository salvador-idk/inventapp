import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/database_helper.dart';
import '/services/carrito_service.dart';
import '/services/inventory_service.dart';
import '/models/item_model.dart';
import '/models/cart_item.dart';
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
  List<CartItem> _carrito = []; // ✅ USAR LIST<CARTITEM>
  bool _cargando = true;
  String _searchQuery = '';

  // ✅ GET INVENTORY SERVICE INSTANCE
  InventoryService get _inventoryService {
    return Provider.of<InventoryService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _cargarItems();
    _cargarCarritoPersistente();
  }

  Future<void> _cargarItems() async {
    try {
      setState(() {
        _cargando = true;
      });

      // ✅ FIXED: Use instance method instead of static
      final items = await _inventoryService.getAllItems();
      
      setState(() {
        _items = items.where((item) => item.cantidad > 0).toList();
        _filteredItems = _items;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error cargando items: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  // ✅ CARGAR CARRITO - CORREGIDO
  Future<void> _cargarCarritoPersistente() async {
    try {
      final carritoGuardado = await CarritoService.cargarCarrito();
      
      setState(() {
        _carrito = carritoGuardado;
      });
    } catch (e) {
      print('Error cargando carrito: $e');
    }
  }

  // ✅ GUARDAR CARRITO - CORREGIDO
  Future<void> _guardarCarritoPersistente() async {
    try {
      await CarritoService.guardarCarrito(_carrito);
    } catch (e) {
      print('Error guardando carrito: $e');
    }
  }

  // ✅ AGREGAR AL CARRITO - CORREGIDO
  void _agregarAlCarrito(Item item, int cantidad) {
    if (item.id == null) return;
    if (cantidad <= 0 || cantidad > item.cantidad) return;

    setState(() {
      final itemId = item.id!;
      final existingIndex = _carrito.indexWhere((cartItem) => cartItem.itemId == itemId);
      
      if (existingIndex != -1) {
        // Actualizar cantidad existente
        final nuevaCantidad = _carrito[existingIndex].cantidad + cantidad;
        if (nuevaCantidad > item.cantidad) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay suficiente stock de ${item.nombre}'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _carrito[existingIndex] = _carrito[existingIndex].copyWith(cantidad: nuevaCantidad);
      } else {
        // Agregar nuevo item al carrito
        final cartItem = CartItem(
          itemId: itemId,
          nombre: item.nombre,
          precio: item.precio,
          cantidad: cantidad,
          imagenUrl: item.imagenUrl, 
          id: '',
        );
        _carrito.add(cartItem);
      }
      
      _guardarCarritoPersistente();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cantidad ${item.nombre} agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ ELIMINAR DEL CARRITO - CORREGIDO
  void _eliminarDelCarrito(String itemId) {
    setState(() {
      _carrito.removeWhere((cartItem) => cartItem.itemId == itemId);
      _guardarCarritoPersistente();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto eliminado del carrito'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ ACTUALIZAR CANTIDAD EN CARRITO - CORREGIDO
  void _actualizarCantidadCarrito(String itemId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(itemId);
      return;
    }

    final item = _items.firstWhere((item) => item.id == itemId);
    if (nuevaCantidad > item.cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficiente stock de ${item.nombre}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final index = _carrito.indexWhere((cartItem) => cartItem.itemId == itemId);
      if (index != -1) {
        _carrito[index] = _carrito[index].copyWith(cantidad: nuevaCantidad);
        _guardarCarritoPersistente();
      }
    });
  }

  // ✅ OBTENER ITEM DESDE CARTITEM
  Item? _getItemFromCart(CartItem cartItem) {
    try {
      return _items.firstWhere((item) => item.id == cartItem.itemId);
    } catch (e) {
      return null; // Item no encontrado en inventario
    }
  }

  double _calcularTotal() {
    double total = 0;
    for (var cartItem in _carrito) {
      total += cartItem.precio * cartItem.cantidad;
    }
    return total;
  }

  int _calcularTotalItems() {
    int total = 0;
    for (var cartItem in _carrito) {
      total += cartItem.cantidad;
    }
    return total;
  }

  Future<void> _realizarCompra() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    try {
      // Crear items para el ticket
      final itemsVenta = _carrito.map((cartItem) {
        final item = _getItemFromCart(cartItem);
        return ItemVenta(
          nombre: cartItem.nombre,
          cantidad: cartItem.cantidad,
          precio: cartItem.precio,
          total: cartItem.precio * cartItem.cantidad,
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

      // ✅ ACTUALIZAR INVENTARIO - FIXED: Use instance method
      for (var cartItem in _carrito) {
        final item = _getItemFromCart(cartItem);
        if (item != null) {
          final itemActualizado = item.copyWith(
            cantidad: item.cantidad - cartItem.cantidad,
          );
          await _inventoryService.updateItem(itemActualizado);
        }
      }

      // ✅ GUARDAR TICKET
      final dbHelper = DatabaseHelper();
      await dbHelper.insertTicket(ticket);

      // Imprimir ticket
      await TicketService.imprimirTicket(ticket, context);

      // ✅ LIMPIAR CARRITO DESPUÉS DE COMPRA EXITOSA
      await CarritoService.limpiarCarrito();
      
      setState(() {
        _carrito.clear();
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
      print('❌ Error en compra: $e');
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
      // ✅ FIXED: Use instance method instead of static
      final results = await _inventoryService.searchItems(query);
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
    final cartItemIndex = _carrito.indexWhere((cartItem) => cartItem.itemId == item.id);
    final enCarrito = cartItemIndex != -1;
    final cantidadEnCarrito = enCarrito ? _carrito[cartItemIndex].cantidad : 0;
    final stockDisponible = item.cantidad - cantidadEnCarrito;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: _buildItemImage(item),
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
            Text('Precio: \$${item.precio.toStringAsFixed(2)}'),
            Text('Disponible: $stockDisponible unidades'),
            if (enCarrito)
              Text(
                'En carrito: $cantidadEnCarrito',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (stockDisponible <= 5)
              Text(
                '⚠️ Stock bajo',
                style: TextStyle(
                  color: Colors.orange[800],
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
              icon: Icon(Icons.add, color: stockDisponible > 0 ? Colors.green : Colors.grey),
              onPressed: stockDisponible > 0 ? () => _agregarAlCarrito(item, 1) : null,
              tooltip: 'Agregar 1 unidad',
            ),
            // Botón para agregar múltiples unidades
            PopupMenuButton<int>(
              icon: Icon(Icons.add_shopping_cart, 
                  color: stockDisponible > 0 ? Colors.blue : Colors.grey),
              onOpened: stockDisponible > 0 ? null : null,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text('Agregar 1 unidad')),
                if (stockDisponible >= 2) 
                  const PopupMenuItem(value: 2, child: Text('Agregar 2 unidades')),
                if (stockDisponible >= 5) 
                  const PopupMenuItem(value: 5, child: Text('Agregar 5 unidades')),
                if (stockDisponible >= 10) 
                  const PopupMenuItem(value: 10, child: Text('Agregar 10 unidades')),
              ],
              onSelected: (cantidad) => _agregarAlCarrito(item, cantidad),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(Item item) {
    if (item.tieneImagen) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imagenUrl!.startsWith('http')
              ? Image.network(
                  item.imagenUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                )
              : Image.file(
                  File(item.imagenUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                ),
        ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
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
              const Spacer(),
              Text(
                'Total: \$${_calcularTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        ..._carrito.map((cartItem) {
          final item = _getItemFromCart(cartItem);
          if (item == null) {
            return const SizedBox.shrink(); // Item no encontrado en inventario
          }
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: _buildItemImage(item),
              title: Text(cartItem.nombre),
              subtitle: Text('${cartItem.cantidad} × \$${cartItem.precio.toStringAsFixed(2)} = \$${(cartItem.precio * cartItem.cantidad).toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () => _actualizarCantidadCarrito(cartItem.itemId, cartItem.cantidad - 1),
                  ),
                  Text(
                    cartItem.cantidad.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => _actualizarCantidadCarrito(cartItem.itemId, cartItem.cantidad + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarDelCarrito(cartItem.itemId),
                  ),
                ],
              ),
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a pagar:',
                      style: TextStyle(
                        fontSize: 18,
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
                child: ElevatedButton.icon(
                  onPressed: _realizarCompra,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text(
                    'Realizar Compra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
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
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Carrito vaciado')),
                              );
                            },
                            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: const Text('Vaciar Carrito', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: const Text('Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarItems,
            tooltip: 'Actualizar productos',
          ),
          if (_carrito.isNotEmpty)
            Badge(
              label: Text(_calcularTotalItems().toString()),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
                tooltip: 'Ver carrito',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          SearchBarWidget(
            onSearch: _onSearch,
            onSuggestionSelected: _onSuggestionSelected,
          ),
          
          // Contenido principal
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Título
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Productos Disponibles (${_filteredItems.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // Lista de productos
                      Expanded(
                        child: _filteredItems.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return _buildProductCard(item);
                                },
                              ),
                      ),
                    ],
                  ),
          ),
          
          // Sección del carrito (si hay items)
          if (_carrito.isNotEmpty) _buildCartSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron resultados para "$_searchQuery"'
                  : 'No hay productos disponibles',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _onSearch(''),
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}