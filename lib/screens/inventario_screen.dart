import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/database_helper.dart';
import '/services/inventory_service.dart'; // ✅ USAR INVENTORY SERVICE
import '/models/item_model.dart';
import '/utils/etiqueta_service.dart';
import 'agregar_item_screen.dart';
import '/utils/audit_service.dart';
import '/widgets/search_bar.dart';

// ✅ MODELO DE FILTROS DE BÚSQUEDA
class FiltrosBusqueda {
  final String query;
  final double? precioMin;
  final double? precioMax;
  final int? stockMin;
  final int? stockMax;
  final String? categoriaId; // ✅ CAMBIAR A String
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
    String? categoriaId, // ✅ CAMBIAR A String
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
  FiltrosBusqueda _filtros = const FiltrosBusqueda();

  // ✅ GET INVENTORY SERVICE INSTANCE
  InventoryService get _inventoryService {
    return Provider.of<InventoryService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _cargarItems();
  }

  // ✅ USAR INVENTORY SERVICE EN LUGAR DE DATABASE HELPER DIRECTAMENTE
  Future<void> _cargarItems() async {
    try {
      setState(() {
        _cargando = true;
      });

      // Usar InventoryService que maneja tanto SQLite como Firestore
      final items = await _inventoryService.getAllItems();
      
      setState(() {
        _items = items;
        _filteredItems = items;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error cargando items: $e');
      setState(() {
        _cargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando inventario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        // ✅ USAR INVENTORY SERVICE EN LUGAR DE DATABASE HELPER DIRECTAMENTE
        await _inventoryService.deleteItem(item.id!);
        
        // ✅ LOG DE AUDITORÍA
        await AuditService.logItemDelete(
          context,
          itemId: _safeStringToInt(item.id), // ✅ AGREGAR ESTE MÉTODO AL INVENTARIO SCREEN
          itemName: item.nombre,
        );

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

  // ✅ AGREGAR ESTE MÉTODO AL INVENTARIO SCREEN
  int _safeStringToInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
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
      elevation: 2,
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
            if (item.cantidad <= 5)
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
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editarItem(item),
              tooltip: 'Editar item',
            ),
            IconButton(
              icon: const Icon(Icons.local_offer, color: Colors.green),
              onPressed: () => _imprimirEtiquetaExistente(item),
              tooltip: 'Imprimir etiqueta',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarItem(item),
              tooltip: 'Eliminar item',
            ),
          ],
        ),
        onTap: () => _mostrarDetallesItem(item),
      ),
    );
  }

  // ✅ MEJORAR MANEJO DE IMÁGENES
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
          child: _buildImageWidget(item),
        ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildImageWidget(Item item) {
    try {
      // Intentar cargar como archivo local primero
      if (item.imagenUrl!.startsWith('/') || item.imagenUrl!.contains('\\')) {
        return Image.file(
          File(item.imagenUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
        );
      } else {
        // Si es una URL de Firebase o web
        return Image.network(
          item.imagenUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      }
    } catch (e) {
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
              // Imagen del item
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: item.tieneImagen 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(item),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2, size: 50, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Detalles del item
              _buildDetailRow('Descripción:', item.descripcion),
              _buildDetailRow('Número de Serie:', item.serial),
              _buildDetailRow('ID:', item.numeroIdentificacion),
              _buildDetailRow('Cantidad:', '${item.cantidad} unidades'),
              _buildDetailRow('Precio:', '\$${item.precio.toStringAsFixed(2)}'),
              if (item.categoriaId != null)
                _buildDetailRow('Categoría ID:', item.categoriaId!),
              
              // Estado del stock
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.cantidad == 0 
                      ? Colors.red[50] 
                      : item.cantidad <= 5 
                          ? Colors.orange[50] 
                          : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.cantidad == 0 
                          ? Icons.error 
                          : item.cantidad <= 5 
                              ? Icons.warning 
                              : Icons.check_circle,
                      color: item.cantidad == 0 
                          ? Colors.red 
                          : item.cantidad <= 5 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.cantidad == 0 
                          ? 'Sin stock' 
                          : item.cantidad <= 5 
                              ? 'Stock bajo' 
                              : 'Stock suficiente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.cantidad == 0 
                            ? Colors.red 
                            : item.cantidad <= 5 
                                ? Colors.orange 
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _imprimirEtiquetaExistente(item);
            },
            child: const Text('Etiqueta'),
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
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${itemsStockBajo.length} producto(s) con stock bajo',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (itemsStockBajo.any((item) => item.cantidad == 0))
                  Text(
                    '${itemsStockBajo.where((item) => item.cantidad == 0).length} producto(s) sin stock',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
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
    final itemsSinStock = itemsStockBajo.where((item) => item.cantidad == 0).toList();
    final itemsStockBajoConExistencia = itemsStockBajo.where((item) => item.cantidad > 0).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Productos con Stock Bajo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (itemsSinStock.isNotEmpty) ...[
                const Text(
                  '📦 Sin Stock:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                ...itemsSinStock.map((item) => ListTile(
                  leading: _buildItemImage(item),
                  title: Text(item.nombre),
                  subtitle: Text('Precio: \$${item.precio.toStringAsFixed(2)}'),
                  trailing: Text(
                    '0',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              if (itemsStockBajoConExistencia.isNotEmpty) ...[
                const Text(
                  '⚠️ Stock Bajo:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                ...itemsStockBajoConExistencia.map((item) => ListTile(
                  leading: _buildItemImage(item),
                  title: Text(item.nombre),
                  subtitle: Text('Precio: \$${item.precio.toStringAsFixed(2)}'),
                  trailing: Text(
                    '${item.cantidad}',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )),
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

  // ✅ FILTROS DE BÚSQUEDA
  Widget _buildFiltrosHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _filtros.tieneFiltros ? 'Filtros activos' : 'Sin filtros aplicados',
                      style: TextStyle(
                        color: _filtros.tieneFiltros ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_filtros.tieneFiltros)
                      Text(
                        '${_filteredItems.length} de ${_items.length} items',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
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
        ),
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
            title: const Row(
              children: [
                Icon(Icons.filter_list),
                SizedBox(width: 8),
                Text('Filtrar Items'),
              ],
            ),
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
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            hintText: '0.00',
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: precioMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            hintText: '1000.00',
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stockMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            hintText: '100',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtro stock bajo
                  SwitchListTile(
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
              ElevatedButton(
                onPressed: () {
                  _aplicarFiltros(
                    precioMin: double.tryParse(precioMinController.text),
                    precioMax: double.tryParse(precioMaxController.text),
                    stockMin: int.tryParse(stockMinController.text),
                    stockMax: int.tryParse(stockMaxController.text),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar Filtros'),
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
          item.numeroIdentificacion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.descripcion.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    setState(() {
      _filteredItems = resultados;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtros = _filtros.copyWith(query: query);
      _aplicarFiltrosYBusqueda();
    });
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
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarItems,
            tooltip: 'Actualizar inventario',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgregarItemScreen()),
              );
              if (resultado == true) {
                await _cargarItems();
              }
            },
            tooltip: 'Agregar nuevo item',
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
          
          // Filtros
          _buildFiltrosHeader(),
          
          // Alertas de stock bajo
          _buildStockBajoHeader(),
          
          // Contenido principal
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filtros.tieneFiltros
                  ? 'No se encontraron resultados'
                  : 'No hay items en el inventario',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_searchQuery.isNotEmpty || _filtros.tieneFiltros) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _limpiarFiltros,
                child: const Text('Limpiar filtros'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AgregarItemScreen()),
                  );
                  if (resultado == true) {
                    await _cargarItems();
                  }
                },
                child: const Text('Agregar primer item'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}