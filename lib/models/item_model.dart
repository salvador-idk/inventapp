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
  int? categoriaId;

  Item({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.serial,
    required this.numeroIdentificacion,
    this.imagenPath,
    this.cantidad = 0,
    this.precio = 0.0,
    this.categoriaId,
  });

  // Método fromMap que falta
  factory Item.fromMap(Map<String, dynamic> map) {
  return Item(
    id: map['id'],
    nombre: map['nombre'] ?? '',
    descripcion: map['descripcion'] ?? '',
    serial: map['serial'] ?? '',
    numeroIdentificacion: map['numeroIdentificacion'] ?? '',
    imagenPath: map['imagenPath'],
    cantidad: map['cantidad'] ?? 0,
    precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
    categoriaId: map['categoriaId'],
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
      'categoriaId': categoriaId,
    };
  }

  String toQRData() {
    return 'Nombre: $nombre\nID: $id\nSerial: $serial\nDescripción: $descripcion\nCantidad: $cantidad\nPrecio: \$$precio';
  }

  // ✅ AGREGAR ESTE MÉTODO PARA FIRESTORE
  factory Item.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Item(
      id: int.tryParse(documentId) ?? 0, // Convertir ID de String a int
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      serial: data['serial'] ?? '',
      numeroIdentificacion: data['numeroIdentificacion'] ?? '',
      imagenPath: data['imagenPath'],
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ✅ MÉTODO PARA CONVERTIR A FIRESTORE (opcional)
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'serial': serial,
      'numeroIdentificacion': numeroIdentificacion,
      'imagenPath': imagenPath,
      'cantidad': cantidad,
      'precio': precio,
      'updatedAt': DateTime.now().toIso8601String(),
    };
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
    int? categoriaId
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
      categoriaId: categoriaId ?? this.categoriaId,
    );
  }
}

