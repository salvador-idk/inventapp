import 'dart:io';
import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/models/item_model.dart';
import '/utils/etiqueta_service.dart';
import 'agregar_item_screen.dart';
import '/utils/audit_service.dart';
import '/widgets/search_bar.dart';

// ✅ AGREGAR: Modelo de FiltrosBusqueda
class FiltrosBusqueda {
  final String query;
  final double? precioMin;
  final double? precioMax;
  final int? stockMin;
  final int? stockMax;
  final int? categoriaId;
  final bool soloStockBajo;

  const FiltrosBusqueda({
    this.query = '',
    this.precioMin,
    this.precioMax,
    this.stockMin,
    this.stockMax,
    this.categoriaId,
    this.soloStockBajo = false,
  });

  FiltrosBusqueda copyWith({
    String? query,
    double? precioMin,
    double? precioMax,
    int? stockMin,
    int? stockMax,
    int? categoriaId,
    bool? soloStockBajo,
  }) {
    return FiltrosBusqueda(
      query: query ?? this.query,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      stockMin: stockMin ?? this.stockMin,
      stockMax: stockMax ?? this.stockMax,
      categoriaId: categoriaId ?? this.categoriaId,
      soloStockBajo: soloStockBajo ?? this.soloStockBajo,
    );
  }

  bool get tieneFiltros {
    return query.isNotEmpty ||
        precioMin != null ||
        precioMax != null ||
        stockMin != null ||
        stockMax != null ||
        categoriaId != null ||
        soloStockBajo;
  }
}

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
  FiltrosBusqueda _filtros = const FiltrosBusqueda(); // ✅ INICIALIZAR

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
        onTap: () => _mostrarDetallesItem(item),
      ),
    );
  }

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
                        const Icon(Icons.inventory_2, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
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

  // ✅ ALERTAS DE STOCK BAJO
  Widget _buildStockBajoHeader() {
    final itemsStockBajo = _items.where((item) => item.cantidad <= 5).toList();
    
    if (itemsStockBajo.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${itemsStockBajo.length} productos con stock bajo (≤ 5 unidades)',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _mostrarStockBajoDetalle,
            child: Text(
              'Ver detalles',
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarStockBajoDetalle() {
    final itemsStockBajo = _items.where((item) => item.cantidad <= 5).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Productos con Stock Bajo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: itemsStockBajo.length,
            itemBuilder: (context, index) {
              final item = itemsStockBajo[index];
              return ListTile(
                leading: _buildItemImage(item),
                title: Text(item.nombre),
                subtitle: Text('Stock: ${item.cantidad} - Precio: \$${item.precio.toStringAsFixed(2)}'),
                trailing: Text(
                  '${item.cantidad}',
                  style: TextStyle(
                    color: item.cantidad == 0 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
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

  // ✅ FILTROS DE BÚSQUEDA
  Widget _buildFiltrosHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _filtros.tieneFiltros ? 'Filtros activos' : 'Sin filtros',
              style: TextStyle(
                color: _filtros.tieneFiltros ? Colors.blue : Colors.grey,
                fontWeight: _filtros.tieneFiltros ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarDialogoFiltros,
            tooltip: 'Filtrar items',
          ),
          if (_filtros.tieneFiltros)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
        ],
      ),
    );
  }

  void _mostrarDialogoFiltros() {
    final precioMinController = TextEditingController(text: _filtros.precioMin?.toString());
    final precioMaxController = TextEditingController(text: _filtros.precioMax?.toString());
    final stockMinController = TextEditingController(text: _filtros.stockMin?.toString());
    final stockMaxController = TextEditingController(text: _filtros.stockMax?.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filtrar Items'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filtro por precio
                  const Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: precioMinController,
                          decoration: const InputDecoration(labelText: 'Mínimo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: precioMaxController,
                          decoration: const InputDecoration(labelText: 'Máximo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtro por stock
                  const Text('Stock:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockMinController,
                          decoration: const InputDecoration(labelText: 'Mínimo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stockMaxController,
                          decoration: const InputDecoration(labelText: 'Máximo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtro stock bajo
                  CheckboxListTile(
                    title: const Text('Solo stock bajo (≤ 5 unidades)'),
                    value: _filtros.soloStockBajo,
                    onChanged: (value) {
                      setState(() {
                        _filtros = _filtros.copyWith(soloStockBajo: value);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  _aplicarFiltros(
                    precioMin: double.tryParse(precioMinController.text),
                    precioMax: double.tryParse(precioMaxController.text),
                    stockMin: int.tryParse(stockMinController.text),
                    stockMax: int.tryParse(stockMaxController.text),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _aplicarFiltros({
    double? precioMin,
    double? precioMax,
    int? stockMin,
    int? stockMax,
  }) {
    setState(() {
      _filtros = _filtros.copyWith(
        precioMin: precioMin,
        precioMax: precioMax,
        stockMin: stockMin,
        stockMax: stockMax,
      );
      _aplicarFiltrosYBusqueda();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _filtros = const FiltrosBusqueda();
      _aplicarFiltrosYBusqueda();
    });
  }

  void _aplicarFiltrosYBusqueda() {
    List<Item> resultados = _items;
    
    // Aplicar filtros
    if (_filtros.precioMin != null) {
      resultados = resultados.where((item) => item.precio >= _filtros.precioMin!).toList();
    }
    if (_filtros.precioMax != null) {
      resultados = resultados.where((item) => item.precio <= _filtros.precioMax!).toList();
    }
    if (_filtros.stockMin != null) {
      resultados = resultados.where((item) => item.cantidad >= _filtros.stockMin!).toList();
    }
    if (_filtros.stockMax != null) {
      resultados = resultados.where((item) => item.cantidad <= _filtros.stockMax!).toList();
    }
    if (_filtros.soloStockBajo) {
      resultados = resultados.where((item) => item.cantidad <= 5).toList();
    }
    
    // Aplicar búsqueda de texto
    if (_searchQuery.isNotEmpty) {
      resultados = resultados.where((item) =>
          item.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.serial.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.numeroIdentificacion.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    setState(() {
      _filteredItems = resultados;
    });
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
    
    // Actualizar filtros con la nueva búsqueda
    _filtros = _filtros.copyWith(query: query);
    _aplicarFiltrosYBusqueda();
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
          
          // ✅ FILTROS
          _buildFiltrosHeader(),
          
          // ✅ ALERTAS DE STOCK BAJO
          _buildStockBajoHeader(),
          
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
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else if (_filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No hay items en el inventario', style: TextStyle(fontSize: 16)),
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