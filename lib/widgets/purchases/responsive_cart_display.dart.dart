import 'package:flutter/material.dart';
import '../shared/responsive_helper.dart';
import '../../models/cart_item.dart';
import '../../models/item_model.dart';

class ResponsiveCartDisplay extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(String) onRemoveFromCart;
  final Function(String, int) onUpdateCartQuantity;
  final Function(Item) onItemDetails;
  final double total;

  const ResponsiveCartDisplay({
    Key? key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onUpdateCartQuantity,
    required this.onItemDetails,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        
        if (isLargeScreen) {
          return _buildTableLayout(context);
        } else {
          return _buildListLayout();
        }
      },
    );
  }

  // ✅ TABLA PARA PANTALLAS GRANDES
  Widget _buildTableLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezado de la tabla
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Producto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Precio Unit.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Cantidad',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Subtotal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 60), // Espacio para botón eliminar
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Items de la tabla
            ...cartItems.map((cartItem) {
              final subtotal = cartItem.precio * cartItem.cantidad;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Producto
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Imagen del producto
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.grey[200],
                                image: cartItem.imagenUrl != null && cartItem.imagenUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(cartItem.imagenUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: cartItem.imagenUrl == null || cartItem.imagenUrl!.isEmpty
                                  ? Icon(Icons.shopping_bag, size: 24, color: Colors.grey[400])
                                  : null,
                            ),
                            
                            const SizedBox(width: 12),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${cartItem.itemId}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Precio Unitario
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '\$${cartItem.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Cantidad
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: cartItem.cantidad > 1 
                                  ? () => onUpdateCartQuantity(cartItem.itemId, cartItem.cantidad - 1)
                                  : null,
                              padding: EdgeInsets.zero,
                            ),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cartItem.cantidad.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => onUpdateCartQuantity(cartItem.itemId, cartItem.cantidad + 1),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Subtotal
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Botón eliminar
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => onRemoveFromCart(cartItem.itemId),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // Total
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ LISTA PARA PANTALLAS PEQUEÑAS
  Widget _buildListLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartItems[index];
        final subtotal = cartItem.precio * cartItem.cantidad;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Imagen
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: cartItem.imagenUrl != null && cartItem.imagenUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(cartItem.imagenUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cartItem.imagenUrl == null || cartItem.imagenUrl!.isEmpty
                      ? Icon(Icons.shopping_bag, size: 24, color: Colors.grey[400])
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${cartItem.precio.toStringAsFixed(2)} c/u',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Controles de cantidad
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: cartItem.cantidad > 1 
                                ? () => onUpdateCartQuantity(cartItem.itemId, cartItem.cantidad - 1)
                                : null,
                            padding: EdgeInsets.zero,
                          ),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cartItem.cantidad.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => onUpdateCartQuantity(cartItem.itemId, cartItem.cantidad + 1),
                            padding: EdgeInsets.zero,
                          ),
                          
                          const Spacer(),
                          
                          Text(
                            '\$${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => onRemoveFromCart(cartItem.itemId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}