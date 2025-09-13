import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'item_model.dart';
import 'ticket_service.dart'; // ← Importar el servicio de tickets

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({Key? key}) : super(key: key);

  @override
  _ComprasScreenState createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  List<Item> _items = [];
  List<Item> _carrito = [];
  final Map<int, int> _cantidadesCarrito = {};
  bool _cargando = true;

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

  // SOLO DEBE HABER UNA FUNCIÓN _realizarCompra - ELIMINAR LA DUPLICADA
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Productos Disponibles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.nombre),
                          subtitle: Text('Disponible: ${item.cantidad} - Precio: \$${item.precio}'),
                          trailing: ElevatedButton(
                            onPressed: () => _agregarAlCarrito(item, 1),
                            child: const Text('Agregar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_carrito.isNotEmpty) ...[
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
                          onPressed: _realizarCompra, // ← Usar la función corregida
                          child: const Text('Realizar Compra e Imprimir Ticket'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}