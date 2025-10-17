import 'dart:io';
import 'package:flutter/material.dart';
import '../shared/responsive_helper.dart';
import '../inventory/product_grid_item.dart'; // ✅ SOLO UN IMPORT
import '../../models/item_model.dart';
import '../../models/cart_item.dart';

class ResponsivePurchasesDisplay extends StatelessWidget {
  final List<Item> availableItems;
  final List<CartItem> cartItems;
  final Function(Item, int) onAddToCart;
  final Function(String) onRemoveFromCart;
  final Function(String, int) onUpdateCartQuantity;
  final Function(Item) onItemDetails;

  const ResponsivePurchasesDisplay({
    Key? key,
    required this.availableItems,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onUpdateCartQuantity,
    required this.onItemDetails,
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

  // ✅ GRID PARA PANTALLAS GRANDES
  Widget _buildGridView(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: availableItems.length,
      itemBuilder: (context, index) {
        final item = availableItems[index];
        final cartItem = cartItems.firstWhere(
          (ci) => ci.itemId == item.id,
          orElse: () => CartItem(id: '', itemId: '', nombre: '', precio: 0, cantidad: 0),
        );
        final enCarrito = cartItem.itemId.isNotEmpty;
        final cantidadEnCarrito = enCarrito ? cartItem.cantidad : 0;
        final stockDisponible = item.cantidad - cantidadEnCarrito;
        
        return ProductGridItem(
          item: item,
          onAddToCart: (item, quantity) {
            if (stockDisponible >= quantity) {
              onAddToCart(item, quantity);
            }
          },
        );
      },
    );
  }

  // ✅ LISTA PARA MÓVILES (USANDO TU DISEÑO ACTUAL)
  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableItems.length,
      itemBuilder: (context, index) {
        final item = availableItems[index];
        final cartItemIndex = cartItems.indexWhere((cartItem) => cartItem.itemId == item.id);
        final enCarrito = cartItemIndex != -1;
        final cantidadEnCarrito = enCarrito ? cartItems[cartItemIndex].cantidad : 0;
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
                IconButton(
                  icon: Icon(Icons.add, color: stockDisponible > 0 ? Colors.green : Colors.grey),
                  onPressed: stockDisponible > 0 ? () => onAddToCart(item, 1) : null,
                  tooltip: 'Agregar 1 unidad',
                ),
                PopupMenuButton<int>(
                  icon: Icon(Icons.add_shopping_cart, 
                      color: stockDisponible > 0 ? Colors.blue : Colors.grey),
                  onSelected: (cantidad) => onAddToCart(item, cantidad),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 1, child: Text('Agregar 1 unidad')),
                    if (stockDisponible >= 2) 
                      const PopupMenuItem(value: 2, child: Text('Agregar 2 unidades')),
                    if (stockDisponible >= 5) 
                      const PopupMenuItem(value: 5, child: Text('Agregar 5 unidades')),
                    if (stockDisponible >= 10) 
                      const PopupMenuItem(value: 10, child: Text('Agregar 10 unidades')),
                  ],
                ),
              ],
            ),
            onTap: () => onItemDetails(item),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(Item item) {
    // ✅ VERIFICACIÓN MÁS ROBUSTA DE IMAGEN
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
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
    );
  }
}