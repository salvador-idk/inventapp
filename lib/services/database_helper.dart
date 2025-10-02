import 'dart:io' as sql;

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
    _initializeDatabase(); // ✅ NOMBRE CORREGIDO
  }

  static sql.Database? _database;

  // ✅ DETECTAR SI ESTAMOS EN WEB
  static bool get _isWeb {
    return const bool.fromEnvironment('dart.library.html');
  }

  // ✅ INICIALIZACIÓN COMPATIBLE CON WEB - NOMBRE CORREGIDO
  static void _initializeDatabase() {
    // Solo inicializar sqflite_ffi si no estamos en web
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
    _database = await _initDatabaseInstance(); // ✅ NOMBRE CORREGIDO
    return _database!;
  }

  // ✅ NOMBRE CORREGIDO PARA EL MÉTODO DE INSTANCIA
  Future<sql.Database> _initDatabaseInstance() async {
    if (_isWeb) {
      throw UnsupportedError('No se puede inicializar SQLite en web.');
    }

    String dbPath;
    
    // Detección simplificada de plataforma
    final bool isWindows = !_isWeb;
    
    if (isWindows) {
      final documentsDir = await _getWindowsDocumentsDirectory();
      dbPath = path.join(documentsDir.path, 'inventario.db');
      
      final dirExists = await documentsDir.exists();
      if (!dirExists) {
        await documentsDir.create(recursive: true);
      }
    } else {
      // Para Android/iOS
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = path.join(documentsDirectory.path, 'inventario.db');
    }
    
    print('📁 Ruta de la base de datos: $dbPath');
    
    return await sql.openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<sql.Directory> _getWindowsDocumentsDirectory() async {
    if (_isWeb) {
      throw UnsupportedError('No disponible en web');
    }

    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      // Fallback simple
      return sql.Directory.current;
    }
  }

  Future<void> _onCreate(sql.Database db, int version) async {
    if (_isWeb) return;
    
    print('🛠️ Creando tablas en versión $version...');
    
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        serial TEXT NOT NULL UNIQUE,
        numeroIdentificacion TEXT NOT NULL UNIQUE,
        imagenPath TEXT,
        cantidad INTEGER DEFAULT 0,
        precio REAL DEFAULT 0.0
      )
    ''');

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
    
    // Insertar usuarios por defecto
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
    
    print('✅ Tablas creadas exitosamente');
  }

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
      print('✅ Tabla tickets creada en migración');
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
      
      print('✅ Tabla users creada en migración');
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
      print('✅ Tabla audit_logs creada en migración');
    }
  }

  // MÉTODOS PRINCIPALES
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

  Future<List<Item>> getItems() async {
    if (_isWeb) return [];
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('items');
      return maps.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error obteniendo items: $e');
      return [];
    }
  }

  Future<int> insertItem(Item item) async {
    if (_isWeb) throw UnsupportedError('Usa FirestoreService en web');
    
    try {
      final db = await database;
      return await db.insert('items', {
        'nombre': item.nombre,
        'descripcion': item.descripcion,
        'serial': item.serial,
        'numeroIdentificacion': item.numeroIdentificacion,
        'imagenPath': item.imagenPath,
        'cantidad': item.cantidad,
        'precio': item.precio,
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
      return await db.update(
        'items',
        {
          'nombre': item.nombre,
          'descripcion': item.descripcion,
          'serial': item.serial,
          'numeroIdentificacion': item.numeroIdentificacion,
          'imagenPath': item.imagenPath,
          'cantidad': item.cantidad,
          'precio': item.precio,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      print('❌ Error actualizando item: $e');
      rethrow;
    }
  }

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
          suggestions.add(map['nombre']);
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

  Future<void> close() async {
    if (_isWeb) return;
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}