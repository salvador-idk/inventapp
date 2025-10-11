// lib/models/cart_item.dart
class CartItem {
  final String? id; // ✅ AGREGAR ID PARA SQLite
  final String itemId;
  final String nombre;
  final double precio;
  final int cantidad;
  final String? imagenUrl;

  CartItem({
    this.id,
    required this.itemId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.imagenUrl,
  });

  // ✅ AGREGAR MÉTODO COPYWITH
  CartItem copyWith({
    String? id,
    String? itemId,
    String? nombre,
    double? precio,
    int? cantidad,
    String? imagenUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  // ✅ MÉTODO TO MAP
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'itemId': itemId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'imagenUrl': imagenUrl,
    };
  }

  // ✅ FACTORY FROM MAP
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id']?.toString(),
      itemId: map['itemId'] as String,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      cantidad: map['cantidad'] as int,
      imagenUrl: map['imagenUrl'] as String?,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, itemId: $itemId, nombre: $nombre, precio: $precio, cantidad: $cantidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.itemId == itemId &&
        other.nombre == nombre;
  }

  @override
  int get hashCode {
    return itemId.hashCode ^ nombre.hashCode;
  }
}