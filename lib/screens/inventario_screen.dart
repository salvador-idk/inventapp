import 'dart:io';

import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/models/item_model.dart';
import '/utils/etiqueta_service.dart';
import 'agregar_item_screen.dart';
import '/utils/audit_service.dart';
import '/widgets/search_bar.dart'; // ← Necesitas importar el SearchBarWidget

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({Key? key}) : super(key: key);

  @override
  _InventarioScreenState createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
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
      _items = items;
      _filteredItems = items;
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

  Future<void> _editarItem(Item item) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarItemScreen(itemParaEditar: item),
      ),
    );

    if (resultado == true) {
      await _cargarItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item actualizado exitosamente')),
      );
    }
  }

  Widget _buildItemCard(Item item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        // ✅ AGREGAR IMAGEN A LA IZQUIERDA
        leading: _buildItemImage(item),
        title: Text(
          item.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.descripcion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('Serial: ${item.serial}'),
            Text('ID: ${item.numeroIdentificacion}'),
            Text('Cantidad: ${item.cantidad} - Precio: \$${item.precio.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        // ✅ HACER TAPPABLE PARA VER DETALLES CON IMAGEN
        onTap: () => _mostrarDetallesItem(item),
      ),
    );
  }

  // ✅ NUEVO MÉTODO: CONSTRUIR WIDGET DE IMAGEN
  Widget _buildItemImage(Item item) {
    if (item.imagenPath != null) {
      try {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(item.imagenPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderIcon();
              },
            ),
          ),
        );
      } catch (e) {
        return _buildPlaceholderIcon();
      }
    } else {
      return _buildPlaceholderIcon();
    }
  }

  // ✅ ICONO PLACEHOLDER CUANDO NO HAY IMAGEN
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: const Icon(Icons.inventory_2, color: Colors.grey),
    );
  }

  // ✅ NUEVO MÉTODO: MOSTRAR DETALLES CON IMAGEN GRANDE
  void _mostrarDetallesItem(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN GRANDE EN DETALLES
              if (item.imagenPath != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.imagenPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: _buildPlaceholderIcon(),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // INFORMACIÓN DEL ITEM
              _buildDetailRow('Descripción:', item.descripcion),
              _buildDetailRow('Número de Serie:', item.serial),
              _buildDetailRow('ID:', item.numeroIdentificacion),
              _buildDetailRow('Cantidad:', item.cantidad.toString()),
              _buildDetailRow('Precio:', '\$${item.precio.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editarItem(item);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO AUXILIAR PARA FILAS DE DETALLE
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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
        _filteredItems = results;
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

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
              'Inventario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Contenido principal
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_filteredItems.isEmpty && _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No se encontraron resultados para "$_searchQuery"',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else if (_filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay items en el inventario', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildItemCard(item);
                },
              ),
            ),
        ],
      ),
    );
  }
}