// lib/models/categoria_model.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class Categoria {
  final String? id; // ✅ Cambiado a String para Firestore
  final String nombre;
  final String? descripcion;
  final String color; // En formato hex: "FF0000"
  final int? sqlId; // ✅ ID específico para SQLite

  Categoria({
    this.id,
    this.sqlId, // ✅ ID para SQLite
    required this.nombre,
    this.descripcion,
    this.color = "2196F3", // Azul por defecto
  });

  // ✅ FROM FIRESTORE
  factory Categoria.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Categoria(
      id: doc.id, // ✅ Firestore ID como String
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'],
      color: _parseColorFromFirestore(data['color']),
    );
  }

  // ✅ TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion ?? '',
      'color': color, // ✅ Guardar como string hex
    };
  }

  // ✅ FROM MAP (para SQLite)
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      sqlId: map['id'], // ✅ SQLite ID como int
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      color: map['color'] ?? '2196F3',
    );
  }

  // ✅ TO MAP (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (sqlId != null) 'id': sqlId,
      'nombre': nombre,
      'descripcion': descripcion ?? '',
      'color': color,
    };
  }

  // ✅ UTILITY METHODS
  static String _parseColorFromFirestore(dynamic firestoreColor) {
    if (firestoreColor == null) return '2196F3';
    
    if (firestoreColor is String) {
      return firestoreColor;
    } else if (firestoreColor is int) {
      // Convertir int a string hex (sin el 0xFF)
      final hex = firestoreColor.toRadixString(16).toUpperCase();
      return hex.length >= 6 ? hex.substring(2) : '2196F3';
    }
    return '2196F3';
  }

  // ✅ GETTER PARA COLOR MATERIAL
  Color get colorMaterial {
    try {
      // Asegurar que el string tenga 6 caracteres
      String colorHex = color;
      if (colorHex.length == 6) {
        return Color(int.parse('0xFF$colorHex'));
      } else if (colorHex.length > 6) {
        // Si tiene más de 6, tomar los últimos 6
        colorHex = colorHex.substring(colorHex.length - 6);
        return Color(int.parse('0xFF$colorHex'));
      } else {
        // Si tiene menos de 6, rellenar con ceros
        colorHex = colorHex.padLeft(6, '0');
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      print('❌ Error parsing color: $color - $e');
      return Color(0xFF2196F3); // Azul por defecto
    }
  }

  // ✅ GETTER PARA ID UNIFICADO
  String get unifiedId {
    // Priorizar Firestore ID, luego SQLite ID
    return id ?? sqlId?.toString() ?? '';
  }

  // ✅ COPY WITH
  Categoria copyWith({
    String? id,
    int? sqlId,
    String? nombre,
    String? descripcion,
    String? color,
  }) {
    return Categoria(
      id: id ?? this.id,
      sqlId: sqlId ?? this.sqlId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $id, sqlId: $sqlId, nombre: $nombre, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria &&
        other.unifiedId == unifiedId &&
        other.nombre == nombre;
  }

  @override
  int get hashCode {
    return unifiedId.hashCode ^ nombre.hashCode;
  }
}