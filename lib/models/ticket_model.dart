// lib/models/ticket_model.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ✅ COPY WITH
  ItemVenta copyWith({
    String? nombre,
    int? cantidad,
    double? precio,
    double? total,
  }) {
    return ItemVenta(
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      total: total ?? this.total,
    );
  }

  @override
  String toString() {
    return 'ItemVenta(nombre: $nombre, cantidad: $cantidad, precio: $precio, total: $total)';
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

  // ✅ FROM FIRESTORE CORREGIDO - 1 PARÁMETRO
  factory TicketVenta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TicketVenta(
      id: _parseInt(doc.id), // Convertir ID de string a int si es posible
      fecha: _parseTimestamp(data['fecha']) ?? DateTime.now(),
      total: _parseDouble(data['total']) ?? 0.0,
      items: _parseItems(data['items']),
      folio: data['folio'] ?? '',
    );
  }

  // ✅ TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'fecha': FieldValue.serverTimestamp(), // Usar FieldValue para Firestore
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
      'folio': folio,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ FROM MAP (para SQLite)
  factory TicketVenta.fromMap(Map<String, dynamic> map) {
    return TicketVenta(
      id: map['id'],
      fecha: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      items: _parseItemsFromJson(map['items']),
      folio: map['folio'] ?? '',
    );
  }

  // ✅ TO MAP (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'items': json.encode(items.map((item) => item.toMap()).toList()),
      'folio': folio,
    };
  }

  // ✅ MÉTODOS DE UTILIDAD AGREGADOS
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<ItemVenta> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    if (itemsData is List) {
      return itemsData.map((itemMap) {
        if (itemMap is Map<String, dynamic>) {
          return ItemVenta.fromMap(itemMap);
        }
        return ItemVenta(
          nombre: '',
          cantidad: 0,
          precio: 0.0,
          total: 0.0,
        );
      }).toList();
    }
    return [];
  }

  static List<ItemVenta> _parseItemsFromJson(dynamic itemsJson) {
    if (itemsJson == null) return [];
    try {
      if (itemsJson is String) {
        final decoded = json.decode(itemsJson) as List<dynamic>;
        return decoded.map((itemMap) {
          return ItemVenta.fromMap(Map<String, dynamic>.from(itemMap));
        }).toList();
      } else if (itemsJson is List) {
        return itemsJson.map((itemMap) {
          return ItemVenta.fromMap(Map<String, dynamic>.from(itemMap));
        }).toList();
      }
    } catch (e) {
      print('❌ Error parseando items: $e');
    }
    return [];
  }

  // ✅ GETTERS ÚTILES
  int get cantidadItems => items.fold(0, (sum, item) => sum + item.cantidad);
  
  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String get totalFormateado => '\$${total.toStringAsFixed(2)}';

  // ✅ MÉTODO PARA OBTENER RESUMEN DE ITEMS
  String get resumenItems {
    if (items.isEmpty) return 'Sin items';
    if (items.length == 1) return items.first.nombre;
    return '${items.first.nombre} y ${items.length - 1} más';
  }

  // ✅ COPY WITH
  TicketVenta copyWith({
    int? id,
    DateTime? fecha,
    double? total,
    List<ItemVenta>? items,
    String? folio,
  }) {
    return TicketVenta(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      items: items ?? this.items,
      folio: folio ?? this.folio,
    );
  }

  // ✅ MÉTODO PARA AGREGAR ITEM
  TicketVenta agregarItem(ItemVenta item) {
    final nuevosItems = List<ItemVenta>.from(items)..add(item);
    final nuevoTotal = total + item.total;
    
    return copyWith(
      items: nuevosItems,
      total: nuevoTotal,
    );
  }

  // ✅ MÉTODO PARA REMOVER ITEM
  TicketVenta removerItem(int index) {
    if (index < 0 || index >= items.length) return this;
    
    final itemRemovido = items[index];
    final nuevosItems = List<ItemVenta>.from(items)..removeAt(index);
    final nuevoTotal = total - itemRemovido.total;
    
    return copyWith(
      items: nuevosItems,
      total: nuevoTotal,
    );
  }

  // ✅ MÉTODO PARA LIMPIAR ITEMS
  TicketVenta limpiarItems() {
    return copyWith(
      items: [],
      total: 0.0,
    );
  }

  // ✅ MÉTODO PARA GENERAR FOLIO AUTOMÁTICO
  static String generarFolio() {
    final now = DateTime.now();
    return 'TKT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch}';
  }

  // ✅ MÉTODO PARA CREAR TICKET VACÍO
  static TicketVenta crearVacio() {
    return TicketVenta(
      fecha: DateTime.now(),
      total: 0.0,
      items: [],
      folio: generarFolio(),
    );
  }

  @override
  String toString() {
    return 'TicketVenta(id: $id, folio: $folio, total: $totalFormateado, items: ${items.length}, fecha: $fechaFormateada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketVenta &&
        other.id == id &&
        other.folio == folio;
  }

  @override
  int get hashCode {
    return id.hashCode ^ folio.hashCode;
  }
}