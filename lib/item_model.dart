import 'dart:convert'; // ← Import necesario para json.decode

class Item {
  int? id;
  String nombre;
  String descripcion;
  String serial;
  String numeroIdentificacion;
  String? imagenPath;
  int cantidad;
  double precio;

  Item({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.serial,
    required this.numeroIdentificacion,
    this.imagenPath,
    this.cantidad = 0,
    this.precio = 0.0,
  });

  // Método fromMap que falta
  factory Item.fromMap(Map<String, dynamic> map) {
  return Item(
    id: map['id'],
    nombre: map['nombre'] ?? '', // ← Evita null
    descripcion: map['descripcion'] ?? '',
    serial: map['serial'] ?? '',
    numeroIdentificacion: map['numeroIdentificacion'] ?? '',
    imagenPath: map['imagenPath'],
    cantidad: map['cantidad'] ?? 0, // ← Valor por defecto
    precio: (map['precio'] as num?)?.toDouble() ?? 0.0, // ← Conversión segura
  );
}

  // Método toMap para completar
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'serial': serial,
      'numeroIdentificacion': numeroIdentificacion,
      'imagenPath': imagenPath,
      'cantidad': cantidad,
      'precio': precio,
    };
  }

  String toQRData() {
    return 'Nombre: $nombre\nID: $id\nSerial: $serial\nDescripción: $descripcion\nCantidad: $cantidad\nPrecio: \$$precio';
  }

  Item copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? serial,
    String? numeroIdentificacion,
    String? imagenPath,
    int? cantidad,
    double? precio,
  }) {
    return Item(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      serial: serial ?? this.serial,
      numeroIdentificacion: numeroIdentificacion ?? this.numeroIdentificacion,
      imagenPath: imagenPath ?? this.imagenPath,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
    );
  }
}

// Modelo para los items del ticket
class ItemVenta {
  final String nombre;
  final int cantidad;
  final double precio;
  final double total;

  ItemVenta({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'cantidad': cantidad,
      'precio': precio,
      'total': total,
    };
  }

  factory ItemVenta.fromMap(Map<String, dynamic> map) {
    return ItemVenta(
      nombre: map['nombre'],
      cantidad: map['cantidad'],
      precio: (map['precio'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

// Modelo para el ticket de compra
class TicketVenta {
  int? id;
  final DateTime fecha;
  final double total;
  final List<ItemVenta> items;
  final String folio;

  TicketVenta({
    this.id,
    required this.fecha,
    required this.total,
    required this.items,
    required this.folio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'items': json.encode(items.map((item) => item.toMap()).toList()), // ← Guardar como JSON
      'folio': folio,
    };
  }

  factory TicketVenta.fromMap(Map<String, dynamic> map) {
    // Convertir la columna 'items' de JSON string a List<ItemVenta>
    final itemsJson = map['items'] as String;
    final itemsList = (json.decode(itemsJson) as List<dynamic>)
        .map((itemMap) => ItemVenta.fromMap(Map<String, dynamic>.from(itemMap)))
        .toList();

    return TicketVenta(
      id: map['id'],
      fecha: DateTime.parse(map['fecha']),
      total: (map['total'] as num).toDouble(),
      items: itemsList,
      folio: map['folio'],
    );
  }
}