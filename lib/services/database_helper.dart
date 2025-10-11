import 'dart:io' as io;
import 'package:inventario_app/models/categoria_model.dart';
import '../services/carrito_service.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '/models/item_model.dart';
import 'dart:convert';
import '/models/user_model.dart';
import '/models/audit_model.dart';
import '/models/ticket_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal() {
    _initializeDatabase();
  }

  static sql.Database? _database;

  // ✅ DETECTAR SI ESTAMOS EN WEB
  static bool get _isWeb {
    return const bool.fromEnvironment('dart.library.html');
  }

  // ✅ INICIALIZACIÓN COMPATIBLE CON WEB
  static void _initializeDatabase() {
    if (!_isWeb) {
      _initSqfliteForDesktop();
    }
  }

  // ✅ INICIALIZACIÓN SOLO PARA ESCRITORIO (NO WEB)
  static void _initSqfliteForDesktop() {
    if (!_isWeb) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('✅ sqflite_ffi inicializado para escritorio');
      } catch (e) {
        print('⚠️ Error inicializando sqflite_ffi: $e');
      }
    }
  }

  Future<sql.Database> get database async {
    if (_isWeb) {
      throw UnsupportedError('SQLite no está disponible en web. Usa FirestoreService.');
    }

    if (_database != null) return _database!;
    _database = await _initDatabaseInstance();
    return _database!;
  }

  // ✅ INICIALIZAR INSTANCIA DE BASE DE DATOS
  Future<sql.Database> _initDatabaseInstance() async {
    if (_isWeb) {
      throw UnsupportedError('No se puede inicializar SQLite en web.');
    }

    String dbPath;
    
    final bool isDesktop = !_isWeb && (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS);
    
    if (isDesktop) {
      final documentsDir = await _getWindowsDocumentsDirectory();
      dbPath = path.join(documentsDir.path, 'inventario.db');
      
      final dirExists = await documentsDir.exists();
      if (!dirExists) {
        await documentsDir.create(recursive: true);
      }
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = path.join(documentsDirectory.path, 'inventario.db');
    }
    
    print('📁 Ruta de la base de datos: $dbPath');
    
    return await sql.openDatabase(
      dbPath,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<io.Directory> _getWindowsDocumentsDirectory() async {
    if (_isWeb) {
      throw UnsupportedError('No disponible en web');
    }

    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      return io.Directory.current;
    }
  }

  // ✅ CREAR BASE DE DATOS - VERSIÓN ORIGINAL
  Future<void> _onCreate(sql.Database db, int version) async {
    if (_isWeb) return;
    
    print('🛠️ Creando tablas en versión $version...');
    
    // ✅ TABLA ITEMS (ORIGINAL)
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        serial TEXT NOT NULL UNIQUE,
        numeroIdentificacion TEXT NOT NULL UNIQUE,
        imagenPath TEXT,
        cantidad INTEGER DEFAULT 0,
        precio REAL DEFAULT 0.0,
        categoriaId TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // ✅ TABLA CATEGORIAS (ORIGINAL)
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        colorMaterial INTEGER NOT NULL
      )
    ''');

    // ✅ INSERTAR CATEGORÍAS POR DEFECTO (ORIGINAL)
    await _insertarCategoriasPorDefecto(db);

    // ✅ TABLAS EXISTENTES QUE FUNCIONABAN
    await db.execute('''
      CREATE TABLE tickets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        items TEXT NOT NULL,
        folio TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        nombre TEXT NOT NULL,
        email TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        username TEXT NOT NULL,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        old_values TEXT,
        new_values TEXT,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ✅ USUARIOS POR DEFECTO (ORIGINAL)
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'nombre': 'Administrador',
      'email': 'admin@inventario.com'
    });
    
    await db.insert('users', {
      'username': 'empleado',
      'password': 'empleado123',
      'role': 'empleado',
      'nombre': 'Empleado',
      'email': 'empleado@inventario.com'
    });

    await CarritoService.crearTabla(db);
    
    print('✅ Tablas creadas exitosamente');
  }

  // ✅ MÉTODO ORIGINAL PARA CATEGORÍAS POR DEFECTO
  Future<void> _insertarCategoriasPorDefecto(sql.Database db) async {
    final categorias = [
      {'nombre': 'Electrónicos', 'colorMaterial': 0xFFFF5722},
      {'nombre': 'Ropa', 'colorMaterial': 0xFF2196F3},
      {'nombre': 'Hogar', 'colorMaterial': 0xFF4CAF50},
      {'nombre': 'Deportes', 'colorMaterial': 0xFF9C27B0},
      {'nombre': 'Libros', 'colorMaterial': 0xFF607D8B},
      {'nombre': 'Otros', 'colorMaterial': 0xFF795548},
    ];

    for (final categoria in categorias) {
      await db.insert('categorias', categoria, 
        conflictAlgorithm: sql.ConflictAlgorithm.ignore);
    }
  }

  // ✅ MIGRACIÓN ORIGINAL
  Future<void> _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    if (_isWeb) return;
    
    print('🔄 Migrando base de datos de versión $oldVersion a $newVersion');
    
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tickets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          total REAL NOT NULL,
          items TEXT NOT NULL,
          folio TEXT NOT NULL UNIQUE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL,
          nombre TEXT NOT NULL,
          email TEXT
        )
      ''');
      
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
        'role': 'admin',
        'nombre': 'Administrador',
        'email': 'admin@inventario.com'
      });
      
      await db.insert('users', {
        'username': 'empleado',
        'password': 'empleado123',
        'role': 'empleado',
        'nombre': 'Empleado',
        'email': 'empleado@inventario.com'
      });
    }
    
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          username TEXT NOT NULL,
          action TEXT NOT NULL,
          table_name TEXT NOT NULL,
          record_id INTEGER NOT NULL,
          old_values TEXT,
          new_values TEXT,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          colorMaterial INTEGER NOT NULL
        )
      ''');
      
      await _insertarCategoriasPorDefecto(db);
    }
    
    print('✅ Migración completada');
  }

  // ========== MÉTODOS ORIGINALES QUE FUNCIONABAN ==========

  // ✅ MÉTODOS DE ITEMS (ORIGINALES)
  Future<List<Item>> getItems() async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('items', orderBy: 'nombre');
      return maps.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error obteniendo items: $e');
      return [];
    }
  }

  // En los métodos insertItem y updateItem del DatabaseHelper, CORREGIR:

Future<int> insertItem(Item item) async {
  if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
  
  try {
    final db = await database;
    
    // Check if serial already exists
    final existing = await itemExists(item.serial);
    if (existing) {
      throw Exception('Ya existe un item con el mismo número de serie');
    }

    return await db.insert('items', {
      'nombre': item.nombre,
      'descripcion': item.descripcion,
      'serial': item.serial,
      'numeroIdentificacion': item.numeroIdentificacion,
      'imagenPath': item.imagenUrl,
      'cantidad': item.cantidad,
      'precio': item.precio,
      'categoriaId': item.categoriaId, // ✅ DEJAR COMO STRING, NO CONVERTIR A INT
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('❌ Error insertando item: $e');
    rethrow;
  }
}

Future<int> updateItem(Item item) async {
  if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
  
  try {
    final db = await database;
    
    if (item.id == null) {
      throw Exception('No se puede actualizar un item sin ID');
    }

    // Check if serial already exists (excluding current item)
    final existing = await itemExists(item.serial, excludeItemId: item.id);
    if (existing) {
      throw Exception('Ya existe otro item con el mismo número de serie');
    }

    return await db.update(
      'items',
      {
        'nombre': item.nombre,
        'descripcion': item.descripcion,
        'serial': item.serial,
        'numeroIdentificacion': item.numeroIdentificacion,
        'imagenPath': item.imagenUrl,
        'cantidad': item.cantidad,
        'precio': item.precio,
        'categoriaId': item.categoriaId, // ✅ DEJAR COMO STRING, NO CONVERTIR A INT
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [int.parse(item.id!)],
    );
  } catch (e) {
    print('❌ Error actualizando item: $e');
    rethrow;
  }
}

  // En DatabaseHelper - métodos actualizados
  Future<int> deleteItem(int id) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.delete(
        'items',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('❌ Error eliminando item: $e');
      rethrow;
    }
  }

  Future<int> deleteItemByStringId(String id) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final intId = int.tryParse(id) ?? 0;
      if (intId == 0) {
        throw Exception('ID de item inválido: $id');
      }
      return await deleteItem(intId);
    } catch (e) {
      print('❌ Error eliminando item por string ID: $e');
      rethrow;
    }
  }

  Future<List<Item>> searchItems(String query) async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final searchTerm = query.toLowerCase();
      
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: 'LOWER(nombre) LIKE ? OR LOWER(serial) LIKE ? OR LOWER(numeroIdentificacion) LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
      );

      return maps.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error en búsqueda: $e');
      return [];
    }
  }

  // ✅ MÉTODOS DE CATEGORÍAS (ORIGINALES)
  Future<List<Categoria>> getCategorias() async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final resultados = await db.query('categorias', orderBy: 'nombre');
      return resultados.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  Future<int> insertCategoria(Categoria categoria) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.insert('categorias', categoria.toMap());
    } catch (e) {
      print('❌ Error insertando categoría: $e');
      rethrow;
    }
  }

  Future<int> updateCategoria(Categoria categoria) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.update(
        'categorias',
        categoria.toMap(),
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  Future<int> deleteCategoria(int id) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.delete(
        'categorias',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      rethrow;
    }
  }

  // ✅ MÉTODOS ORIGINALES QUE FUNCIONABAN
  Future<int> insertTicket(TicketVenta ticket) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.insert('tickets', ticket.toMap());
    } catch (e) {
      print('❌ Error insertando ticket: $e');
      rethrow;
    }
  }

  Future<List<TicketVenta>> getTickets() async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tickets',
        orderBy: 'fecha DESC',
      );
      return List.generate(maps.length, (i) => TicketVenta.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error obteniendo tickets: $e');
      return [];
    }
  }

  Future<AppUser?> getUserByUsername(String username) async {
    if (_isWeb) return null;
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        return AppUser.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<int> insertAuditLog(AuditLog auditLog) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.insert('audit_logs', auditLog.toMap());
    } catch (e) {
      print('❌ Error insertando log de auditoría: $e');
      rethrow;
    }
  }

  Future<List<AuditLog>> getAuditLogs({DateTime? startDate, DateTime? endDate}) async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        whereClause = 'created_at BETWEEN ? AND ?';
        whereArgs = [
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ];
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'audit_logs',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) => AuditLog.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error obteniendo logs de auditoría: $e');
      return [];
    }
  }

  // En DatabaseHelper, agregar este método
  Future<List<Map<String, dynamic>>> getAuditStatsByMonth() async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', created_at) as month,
          action,
          COUNT(*) as count
        FROM audit_logs 
        GROUP BY month, action
        ORDER BY month DESC, action
      ''');
      return result;
    } catch (e) {
      print('❌ Error obteniendo estadísticas de auditoría: $e');
      return [];
    }
  }

  // ========== MÉTODOS NUEVOS QUE FALTABAN ==========

  // En DatabaseHelper, agregar este método
  Future<List<String>> getSearchSuggestions(String query) async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        columns: ['nombre', 'serial', 'numeroIdentificacion'],
        where: 'nombre LIKE ? OR serial LIKE ? OR numeroIdentificacion LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        limit: 5,
      );

      final suggestions = <String>[];
      for (final map in maps) {
        if (map['nombre'].toString().toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(map['nombre'] as String);
        }
        if (map['serial'].toString().toLowerCase().contains(query.toLowerCase())) {
          suggestions.add('Serial: ${map['serial']}');
        }
        if (map['numeroIdentificacion'].toString().toLowerCase().contains(query.toLowerCase())) {
          suggestions.add('ID: ${map['numeroIdentificacion']}');
        }
      }

      return suggestions.toSet().toList();
    } catch (e) {
      print('❌ Error obteniendo sugerencias: $e');
      return [];
    }
  }

  // ✅ GET ITEM BY ID (NUEVO - REQUERIDO)
  Future<Item?> getItemById(int id) async {
    if (_isWeb) return null;
    
    try {
      final db = await database;
      final maps = await db.query(
        'items',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Item.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo item por ID: $e');
      return null;
    }
  }

  // ✅ ITEM EXISTS (NUEVO - REQUERIDO)
  Future<bool> itemExists(String serial, {String? excludeItemId}) async {
    if (_isWeb) return false;
    
    try {
      final db = await database;
      final where = 'serial = ? ${excludeItemId != null ? 'AND id != ?' : ''}';
      final whereArgs = excludeItemId != null 
          ? [serial, int.tryParse(excludeItemId) ?? 0]
          : [serial];
      
      final maps = await db.query(
        'items',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando existencia de item: $e');
      return false;
    }
  }

  // ✅ GET CATEGORIA BY ID (NUEVO - REQUERIDO)
  Future<Categoria?> getCategoriaById(int id) async {
    if (_isWeb) return null;
    
    try {
      final db = await database;
      final maps = await db.query(
        'categorias',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Categoria.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo categoría por ID: $e');
      return null;
    }
  }

  // ✅ GET ITEMS COUNT (NUEVO - REQUERIDO)
  Future<int> getItemsCount() async {
    if (_isWeb) return 0;
    
    try {
      final db = await database;
      final count = sql.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM items')
      );
      return count ?? 0;
    } catch (e) {
      print('❌ Error obteniendo conteo de items: $e');
      return 0;
    }
  }

  // ✅ CERRAR BASE DE DATOS
  Future<void> close() async {
    if (_isWeb) return;
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

// En una clase de utilidades o en DatabaseHelper
class TypeUtils {
  static int safeStringToInt(String? value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  static String safeIntToString(int? value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static int? safeStringToIntNullable(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }
}