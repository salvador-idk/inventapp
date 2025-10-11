import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screens/dashboard_screen.dart';
import '/screens/gestion_categorias_screen.dart';
import '/screens/agregar_item_screen.dart';
import '/screens/inventario_screen.dart';
import '/screens/compras_screen.dart';
import '/screens/tickets_screen.dart';
import '/screens/auditoria_screen.dart';
import '/screens/login_screen.dart';
import '/providers/auth_provider.dart';
import '/services/inventory_service.dart';
import '/utils/audit_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _firebaseStatus = 'Verificando...';

  InventoryService get _inventoryService {
    return Provider.of<InventoryService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    print('🚀 MainScreen iniciado');
    _checkFirebaseStatus(); // ✅ VERIFICAR ESTADO AL INICIAR
  }

  // ✅ VERIFICAR ESTADO DE FIREBASE
  Future<void> _checkFirebaseStatus() async {
    try {
      final isConnected = await InventoryService.testFirebaseConnection();
      setState(() {
        _firebaseStatus = isConnected ? '✅ Conectado' : '❌ No conectado';
      });
      print('Firebase Status: $_firebaseStatus');
      
      // Mostrar snackbar con el resultado
      _showSnackBar(isConnected 
          ? 'Firebase: Conectado correctamente' 
          : 'Firebase: No conectado - usando SQLite');
    } catch (e) {
      setState(() {
        _firebaseStatus = '❌ Error: $e';
      });
      print('Error verificando Firebase: $e');
      _showSnackBar('Error verificando Firebase: $e');
    }
  }

  // ✅ MÉTODO PARA MIGRAR A FIREBASE
  Future<void> _migrateToFirebase() async {
    try {
      _showSnackBar('Iniciando migración a Firebase...');
      final success = await _inventoryService.switchToFirebase();
      await _checkFirebaseStatus(); // Actualizar estado
      
      if (success) {
        _showSnackBar('✅ Cambiado a Firebase exitosamente');
        
        // Opcional: Migrar datos existentes
        final shouldMigrate = await _showMigrationDialog();
        if (shouldMigrate ?? false) {
          await _performDataMigration();
        }
      } else {
        _showSnackBar('❌ No se pudo cambiar a Firebase - usando SQLite');
      }
    } catch (e) {
      _showSnackBar('❌ Error migrando: $e');
    }
  }

  // ✅ DIÁLOGO DE CONFIRMACIÓN PARA MIGRACIÓN
  Future<bool?> _showMigrationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrar Datos'),
        content: const Text('¿Deseas migrar tus datos locales existentes a Firebase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Solo Cambiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Migrar Datos'),
          ),
        ],
      ),
    );
  }

  // ✅ REALIZAR MIGRACIÓN DE DATOS
  Future<void> _performDataMigration() async {
    try {
      _showSnackBar('🚀 Migrando datos a Firebase...');
      final result = await _inventoryService.migrateToFirestore();
      if (result.success) {
        _showSnackBar('✅ Migración completada exitosamente');
      } else {
        _showSnackBar('❌ Migración con errores: ${result.message}');
      }
    } catch (e) {
      _showSnackBar('❌ Error en migración: $e');
    }
  }

  // ✅ MOSTRAR SNACKBAR
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<Widget> _getWidgetOptions(AuthProvider auth) {
    print('📱 _getWidgetOptions - isAdmin: ${auth.isAdmin}');
    
    if (auth.isAdmin) {
      print('✅ Admin: Mostrando 7 pantallas');
      return <Widget>[
        const DashboardScreen(),
        const GestionCategoriasScreen(),
        const AgregarItemScreen(),
        const InventarioScreen(),
        const ComprasScreen(),
        const TicketsScreen(),
        const AuditoriaScreen(),
      ];
    } else {
      print('👤 Empleado: Mostrando solo Compras');
      return <Widget>[
        const ComprasScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(AuthProvider auth) {
    print('🔗 _getNavItems - isAdmin: ${auth.isAdmin}');
    
    if (auth.isAdmin) {
      print('✅ Admin: 7 items de navegación');
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorías'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Agregar Item'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventario'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Tickets'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Auditoría'),
      ];
    } else {
      print('👤 Empleado: 1 item de navegación');
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
      ];
    }
  }

  void _onItemTapped(int index) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    print('🖱️ Tap en índice: $index - isEmpleado: ${auth.isEmpleado}');
    
    if (auth.isEmpleado && index != 0) {
      print('❌ Empleado no puede navegar a índice: $index');
      _showSnackBar('Empleados solo pueden acceder a Compras');
      return;
    }
    
    setState(() {
      _selectedIndex = index;
      print('📊 Índice cambiado a: $index');
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuditService.logLogout(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const LoginScreen())
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // ✅ BOTÓN PARA GESTIÓN DE FIREBASE (solo admin)
  Widget _buildFirebaseMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.cloud, color: Colors.white),
      tooltip: 'Gestión Firebase',
      onSelected: (value) {
        switch (value) {
          case 'test':
            _checkFirebaseStatus();
            break;
          case 'migrate':
            _migrateToFirebase();
            break;
          case 'status':
            _showSnackBar('Estado: $_firebaseStatus | DataSource: ${_inventoryService.currentDataSource}');
            break;
          case 'switch_sqlite':
            _switchToSQLite();
            break;
        }
      },
      itemBuilder: (context) => [
        // Estado actual
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              const Icon(Icons.info, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                _firebaseStatus,
                style: TextStyle(
                  color: _firebaseStatus.contains('✅') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        
        // Probar conexión
        const PopupMenuItem(
          value: 'test',
          child: Row(
            children: [
              Icon(Icons.wifi, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text('Probar Conexión'),
            ],
          ),
        ),
        
        // Migrar a Firebase
        PopupMenuItem(
          value: 'migrate',
          child: Row(
            children: [
              const Icon(Icons.cloud_upload, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Migrar a Firebase'),
              const Spacer(),
              if (!_inventoryService.isUsingFirebase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Volver a SQLite
        if (_inventoryService.isUsingFirebase)
          const PopupMenuItem(
            value: 'switch_sqlite',
            child: Row(
              children: [
                Icon(Icons.storage, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text('Volver a SQLite'),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ CAMBIAR A SQLITE
  Future<void> _switchToSQLite() async {
    final success = await _inventoryService.switchToSQLite();
    if (success) {
      setState(() {
        _firebaseStatus = '🔁 Cambiado a SQLite';
      });
      _showSnackBar('✅ Cambiado a SQLite exitosamente');
    } else {
      _showSnackBar('❌ Error cambiando a SQLite');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // DEBUG: Verificar estado
    print('🎯 BUILD - Usuario: ${auth.currentUser?.username}');
    print('🎯 BUILD - DataSource: ${_inventoryService.currentDataSource}');
    print('🎯 BUILD - Firebase: $_firebaseStatus');

    final widgetOptions = _getWidgetOptions(auth);
    final navItems = _getNavItems(auth);

    final indiceSeguro = _selectedIndex.clamp(0, widgetOptions.length - 1);
    if (_selectedIndex != indiceSeguro && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = indiceSeguro;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Inventario'),
        backgroundColor: Colors.blueGrey[700],
        actions: [
          if (auth.isAdmin) _buildFirebaseMenu(), // ✅ MENÚ FIREBASE SOLO ADMIN
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: _logout, 
            tooltip: 'Cerrar Sesión'
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo para empleados
          if (auth.isEmpleado)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blueGrey[100],
              child: Row(
                children: [
                  const Icon(Icons.info, size: 16),
                  const SizedBox(width: 8),
                  const Text('Modo empleado: solo acceso a compras'),
                  const Spacer(),
                  Text(
                    'Usuario: ${auth.currentUser?.nombre}', 
                    style: const TextStyle(fontSize: 12)
                  ),
                ],
              ),
            ),
          
          // Banner informativo de DataSource (solo admin)
          if (auth.isAdmin)
            Container(
              padding: const EdgeInsets.all(6.0),
              color: _inventoryService.isUsingFirebase 
                  ? Colors.green[50] 
                  : Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _inventoryService.isUsingFirebase 
                        ? Icons.cloud 
                        : Icons.storage,
                    size: 16,
                    color: _inventoryService.isUsingFirebase 
                        ? Colors.green 
                        : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data Source: ${_inventoryService.currentDataSource}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _inventoryService.isUsingFirebase 
                          ? Colors.green 
                          : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(child: widgetOptions[indiceSeguro]),
        ],
      ),
      bottomNavigationBar: auth.isAdmin 
          ? BottomNavigationBar(
              items: navItems,
              currentIndex: indiceSeguro,
              selectedItemColor: Colors.blueGrey[700],
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            )
          : null,
    );
  }
}