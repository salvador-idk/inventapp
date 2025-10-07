// lib/models/categoria_model.dart
import 'dart:ui';

class Categoria {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String color; // En formato hex: "FF0000"

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion,
    this.color = "2196F3", // Azul por defecto
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      color: map['color'] ?? '2196F3',
    );
  }

  Color get colorMaterial {
    return Color(int.parse('0xFF$color'));
  }
}