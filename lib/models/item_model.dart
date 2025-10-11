import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String? id;
  String nombre;
  String descripcion;
  String serial;
  String numeroIdentificacion;
  String? imagenUrl;
  int cantidad;
  double precio;
  final String? categoriaId; // ✅ MANTENER COMO String PARA CONSISTENCIA
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Item({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.serial,
    required this.numeroIdentificacion,
    this.imagenUrl,
    this.cantidad = 0,
    this.precio = 0.0,
    this.categoriaId,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ PARA FIRESTORE
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'serial': serial,
      'numeroIdentificacion': numeroIdentificacion,
      'imagenUrl': imagenUrl,
      'cantidad': cantidad,
      'precio': precio,
      'categoriaId': categoriaId, // ✅ ENVIAR COMO STRING
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  // ✅ DESDE FIRESTORE
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Item(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      serial: data['serial'] ?? '',
      numeroIdentificacion: data['numeroIdentificacion'] ?? '',
      imagenUrl: data['imagenUrl'],
      cantidad: _safeInt(data['cantidad']),
      precio: _safeDouble(data['precio']),
      categoriaId: _safeString(data['categoriaId']), // ✅ CONVERSIÓN SEGURA
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  // ✅ MÉTODO fromMap - MEJORADO PARA SQLite
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id']?.toString(),
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      serial: map['serial'] ?? '',
      numeroIdentificacion: map['numeroIdentificacion'] ?? '',
      imagenUrl: map['imagenPath'] ?? map['imagenUrl'], // Compatibilidad
      cantidad: _safeInt(map['cantidad']),
      precio: _safeDouble(map['precio']),
      categoriaId: _safeString(map['categoriaId']), // ✅ CONVERSIÓN SEGURA
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  // ✅ MÉTODO toMap - MEJORADO PARA SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'serial': serial,
      'numeroIdentificacion': numeroIdentificacion,
      'imagenPath': imagenUrl, // Compatibilidad con SQLite
      'imagenUrl': imagenUrl,
      'cantidad': cantidad,
      'precio': precio,
      'categoriaId': categoriaId, // ✅ MANTENER COMO STRING
      'createdAt': _timestampToIso(createdAt),
      'updatedAt': _timestampToIso(updatedAt),
    };
  }

  // ✅ MÉTODO COPYWITH
  Item copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? serial,
    String? numeroIdentificacion,
    String? imagenUrl,
    int? cantidad,
    double? precio,
    String? categoriaId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      serial: serial ?? this.serial,
      numeroIdentificacion: numeroIdentificacion ?? this.numeroIdentificacion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      categoriaId: categoriaId ?? this.categoriaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ MÉTODOS AUXILIARES MEJORADOS
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is int) return value.toDouble();
    return 0.0;
  }

  // ✅ NUEVO: CONVERSIÓN SEGURA PARA STRING
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  // ✅ NUEVO: PARSEAR TIMESTAMP DESDE STRING (SQLite)
  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is String) {
      try {
        final dateTime = DateTime.parse(value);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ✅ NUEVO: CONVERTIR TIMESTAMP A STRING PARA SQLite
  static String? _timestampToIso(Timestamp? timestamp) {
    if (timestamp == null) return null;
    return timestamp.toDate().toIso8601String();
  }

  // ✅ MÉTODO QR DATA
  String toQRData() {
    final qrData = {
      'id': id,
      'nombre': nombre,
      'serial': serial,
      'numeroIdentificacion': numeroIdentificacion,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio': precio,
      if (categoriaId != null) 'categoriaId': categoriaId,
    };
    return jsonEncode(qrData);
  }

  // ✅ MÉTODO PARA CARGAR DESDE QR
  factory Item.fromQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      return Item(
        id: data['id']?.toString(),
        nombre: data['nombre'] ?? '',
        descripcion: data['descripcion'] ?? '',
        serial: data['serial'] ?? '',
        numeroIdentificacion: data['numeroIdentificacion'] ?? '',
        cantidad: _safeInt(data['cantidad']),
        precio: _safeDouble(data['precio']),
        categoriaId: _safeString(data['categoriaId']),
      );
    } catch (e) {
      return Item(
        nombre: 'Item desde QR',
        descripcion: 'Cargado desde código QR',
        serial: '',
        numeroIdentificacion: '',
      );
    }
  }

  @override
  String toString() {
    return 'Item(id: $id, nombre: $nombre, serial: $serial, cantidad: $cantidad, precio: $precio, categoriaId: $categoriaId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        other.id == id &&
        other.nombre == nombre &&
        other.serial == serial;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nombre.hashCode ^ serial.hashCode;
  }

  // ✅ MÉTODOS DE CONVENIENCIA
  bool get tieneImagen => imagenUrl != null && imagenUrl!.isNotEmpty;
  bool get tieneCategoria => categoriaId != null && categoriaId!.isNotEmpty;
  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';
  
  // ✅ VALIDACIÓN DE DATOS
  bool get esValido {
    return nombre.isNotEmpty && 
           serial.isNotEmpty && 
           numeroIdentificacion.isNotEmpty;
  }

  // ✅ MÉTODO PARA OBTENER CATEGORIA ID COMO INT (PARA SQLite)
  int? get categoriaIdAsInt {
    if (categoriaId == null) return null;
    return int.tryParse(categoriaId!);
  }

  // ✅ MÉTODO PARA CREAR ITEM CON CATEGORIA ID COMO INT
  Item withCategoriaIdInt(int? categoriaIdInt) {
    return copyWith(
      categoriaId: categoriaIdInt?.toString(),
    );
  }
}