import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'item_model.dart';
import 'etiqueta_service.dart';
import 'agregar_item_screen.dart'; // ← Importación para la edición
import 'audit_service.dart'; // ← Agregar esta importación

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({Key? key}) : super(key: key);

  @override
  _InventarioScreenState createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Item> _items = [];
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
      _items = items;
      _cargando = false;
    });
  }

  Future<void> _eliminarItem(Item item) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${item.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        final dbHelper = DatabaseHelper();
        
        // ✅ LOG DE AUDITORÍA PARA ELIMINACIÓN (ANTES de eliminar)
        await AuditService.logItemDelete(
          context,
          itemId: item.id!,
          itemName: item.nombre,
        );
        
        await dbHelper.deleteItem(item.id!);
        await _cargarItems();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item eliminado exitosamente')),
        );
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _imprimirEtiquetaExistente(Item item) async {
    final opcion = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimir Etiqueta'),
        content: const Text('¿Deseas imprimir una etiqueta para este artículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(0),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(1),
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );

    if (opcion == 1) {
      await EtiquetaService.imprimirEtiqueta(item, context);
    }
  }

  // NUEVO MÉTODO: Editar item
  Future<void> _editarItem(Item item) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarItemScreen(itemParaEditar: item),
      ),
    );

    if (resultado == true) {
      // Recargar items si se editó exitosamente
      await _cargarItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item actualizado exitosamente')),
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
                    'Inventario',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text('No hay items en el inventario'),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(item.nombre),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.descripcion),
                                    Text('Serial: ${item.serial}'),
                                    Text('ID: ${item.numeroIdentificacion}'),
                                    Text('Cantidad: ${item.cantidad} - Precio: \$${item.precio.toStringAsFixed(2)}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // NUEVO BOTÓN: Editar
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarItem(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.local_offer, color: Colors.green),
                                      onPressed: () => _imprimirEtiquetaExistente(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarItem(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}