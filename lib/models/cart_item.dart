class CartItem {
  final String id;
  final String itemId;
  final String nombre;
  final double precio;
  final int cantidad;
  final String? imagenUrl;

  CartItem({
    required this.id,
    required this.itemId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.imagenUrl,
  });

  // Opcional: Métodos para conversión
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'imagenUrl': imagenUrl,
      'cantidad': cantidad,
      'precio': precio,
      'total': total,
    };
  }
  
  double get total => precio * cantidad;

  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      itemId: data['itemId'] ?? '',
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
      cantidad: data['cantidad'] ?? 0,
      imagenUrl: data['imagenUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'imagenUrl': imagenUrl,
    };
  }
}