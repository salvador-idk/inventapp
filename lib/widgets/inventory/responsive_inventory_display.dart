import 'dart:io'; // ✅ AGREGAR ESTE IMPORT
import 'package:flutter/material.dart';
import '../shared/responsive_helper.dart';
import 'product_grid_item.dart'; // ✅ SOLO UN IMPORT
import '../../models/item_model.dart';

class ResponsiveInventoryDisplay extends StatelessWidget {
  final List<Item> items;
  final Function(Item) onItemTap;
  final Function(Item) onItemEdit;
  final Function(Item) onItemDelete;
  final Function(Item) onPrintLabel;
  final Function(Item, int)? onAddToCart; // Opcional para compras

  const ResponsiveInventoryDisplay({
    Key? key,
    required this.items,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.onPrintLabel,
    this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        
        if (isLargeScreen) {
          return _buildGridView(context);
        } else {
          return _buildListView(context);
        }
      },
    );
  }

  // ✅ VISTA GRID PARA PANTALLAS GRANDES
  Widget _buildGridView(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: _getDynamicAspectRatio(context), // ✅ NUEVO MÉTODO DINÁMICO
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        return ProductGridItem(
          item: item,
          onAddToCart: onAddToCart ?? (item, quantity) {
            onItemTap(item);
          },
        );
      },
    );
  }

  // ✅ MÉTODO PARA CALCULAR ASPECT RATIO DINÁMICO
  double _getDynamicAspectRatio(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    
    // Ajustar el aspect ratio según el número de columnas
    switch (crossAxisCount) {
      case 1: // Móvil
        return 0.7;
      case 2: // Tablet pequeña
        return 0.8;
      case 3: // Tablet grande
        return 0.9;
      case 4: // Desktop
        return 1.0;
      case 5: // Desktop grande
        return 1.1;
      default:
        return 0.8;
    }
}

  // ✅ VISTA LISTA PARA MÓVILES (USANDO TU DISEÑO ACTUAL)
  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                  onPressed: () => onItemEdit(item),
                  tooltip: 'Editar item',
                ),
                IconButton(
                  icon: const Icon(Icons.local_offer, color: Colors.green),
                  onPressed: () => onPrintLabel(item),
                  tooltip: 'Imprimir etiqueta',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onItemDelete(item),
                  tooltip: 'Eliminar item',
                ),
              ],
            ),
            onTap: () => onItemTap(item),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(Item item) {
    // ✅ VERIFICAR SI TIENE IMAGEN DE FORMA SEGURA
    bool tieneImagen = item.imagenUrl != null && item.imagenUrl!.isNotEmpty;
    
    if (tieneImagen) {
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
      child: const Icon(Icons.inventory_2, color: Colors.grey),
    );
  }
}