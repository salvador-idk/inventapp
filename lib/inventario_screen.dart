import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'item_model.dart';
import 'etiqueta_service.dart';
import 'agregar_item_screen.dart';
import 'audit_service.dart';
import 'search_bar.dart'; // ← Necesitas importar el SearchBarWidget

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

  Widget _buildItemCard(Item item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editarItem(item),
            ),
            IconButton(
              icon: Icon(Icons.local_offer, color: Colors.green),
              onPressed: () => _imprimirEtiquetaExistente(item),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarItem(item),
            ),
          ],
        ),
      ),
    );
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
            Center(child: CircularProgressIndicator())
          else if (_filteredItems.isEmpty && _searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No se encontraron resultados para "$_searchQuery"',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else if (_filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Text('No hay items en el inventario'),
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