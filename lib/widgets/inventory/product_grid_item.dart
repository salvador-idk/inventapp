import 'package:flutter/material.dart';
import '../../models/item_model.dart';

class ProductGridItem extends StatelessWidget {
  final Item item;
  final Function(Item, int) onAddToCart;

  const ProductGridItem({
    Key? key,
    required this.item,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showProductDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto
            Expanded(
              child: item.imagenUrl != null
                  ? Image.network(
                      item.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            
            // Información del producto
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text('Serial: ${item.serial}', style: TextStyle(fontSize: 12)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.precio.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Stock: ${item.cantidad}',
                        style: TextStyle(
                          color: item.cantidad > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: item.cantidad > 0 
                        ? () => _showAddToCartDialog(context)
                        : null,
                    child: Text('Agregar al Carrito'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.inventory_2, size: 50, color: Colors.grey[400]),
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.imagenUrl != null)
                Image.network(item.imagenUrl!, height: 200, fit: BoxFit.cover),
              SizedBox(height: 16),
              Text('Descripción: ${item.descripcion}'),
              SizedBox(height: 8),
              Text('Serial: ${item.serial}'),
              Text('ID: ${item.numeroIdentificacion}'),
              SizedBox(height: 8),
              Text('Precio: \$${item.precio.toStringAsFixed(2)}'),
              Text('Stock disponible: ${item.cantidad}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          if (item.cantidad > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddToCartDialog(context);
              },
              child: Text('Agregar al Carrito'),
            ),
        ],
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Agregar al Carrito'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    suffixText: 'Máx: ${item.cantidad}',
                  ),
                  onChanged: (value) {
                    setState(() {}); // Actualizar UI
                  },
                ),
                SizedBox(height: 8),
                if (quantityController.text.isNotEmpty)
                  Text(
                    'Total: \$${(item.precio * (int.tryParse(quantityController.text) ?? 0)).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  if (quantity > 0 && quantity <= item.cantidad) {
                    onAddToCart(item, quantity);
                    Navigator.pop(context);
                  }
                },
                child: Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }
}