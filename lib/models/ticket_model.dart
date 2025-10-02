// lib/models/ticket_model.dart
import 'dart:convert';

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
      nombre: map['nombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

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
      'items': json.encode(items.map((item) => item.toMap()).toList()),
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

  // Para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fecha': fecha.toIso8601String(),
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
      'folio': folio,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory TicketVenta.fromFirestore(Map<String, dynamic> data, String id) {
    final itemsList = (data['items'] as List<dynamic>)
        .map((itemMap) => ItemVenta.fromMap(Map<String, dynamic>.from(itemMap)))
        .toList();

    return TicketVenta(
      id: int.tryParse(id) ?? 0,
      fecha: DateTime.parse(data['fecha']),
      total: (data['total'] as num).toDouble(),
      items: itemsList,
      folio: data['folio'],
    );
  }
}