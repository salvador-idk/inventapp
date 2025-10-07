// lib/services/carrito_service.dart
import 'package:sqflite/sqflite.dart';
import '../models/cart_item.dart';
import 'database_helper.dart';

class CarritoService {
  static const String tableName = 'carrito';
  
  static Future<void> crearTabla(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId TEXT NOT NULL,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        cantidad INTEGER NOT NULL,
        imagenUrl TEXT,
        fecha_creacion TEXT NOT NULL
      )
    ''');
  }

  static Future<void> guardarCarrito(List<CartItem> items) async {
    final db = await DatabaseHelper().database;
    
    // Limpiar carrito actual
    await db.delete(tableName);
    
    // Guardar nuevos items
    for (final item in items) {
      await db.insert(tableName, {
        'itemId': item.itemId,
        'nombre': item.nombre,
        'precio': item.precio,
        'cantidad': item.cantidad,
        'imagenUrl': item.imagenUrl,
        'fecha_creacion': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<List<CartItem>> cargarCarrito() async {
    final db = await DatabaseHelper().database;
    final resultados = await db.query(tableName);
    
    return resultados.map((map) => CartItem(
      id: map['id'].toString(),
      itemId: map['itemId'] as String,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      cantidad: map['cantidad'] as int,
      imagenUrl: map['imagenUrl'] as String?,
    )).toList();
  }

  static Future<void> limpiarCarrito() async {
    final db = await DatabaseHelper().database;
    await db.delete(tableName);
  }
}