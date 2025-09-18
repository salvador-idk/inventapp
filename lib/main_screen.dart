import 'package:flutter/material.dart';
import 'package:inventario_app/auditoria_screen.dart';
import 'package:provider/provider.dart';
import 'agregar_item_screen.dart';
import 'inventario_screen.dart';
import 'compras_screen.dart';
import 'tickets_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'audit_service.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('🚀 MainScreen iniciado');
  }

  List<Widget> _getWidgetOptions(AuthProvider auth) {
    print('📱 _getWidgetOptions - isAdmin: ${auth.isAdmin}');
    
    if (auth.isAdmin) {
      print('✅ Admin: Mostrando 5 pantallas');
      return <Widget>[
        AgregarItemScreen(),
        InventarioScreen(),
        ComprasScreen(),
        TicketsScreen(),
        AuditoriaScreen(),
      ];
    } else {
      print('👤 Empleado: Mostrando solo Compras');
      return <Widget>[
        ComprasScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(AuthProvider auth) {
    print('🔗 _getNavItems - isAdmin: ${auth.isAdmin}');
    
    if (auth.isAdmin) {
      print('✅ Admin: 5 items de navegación');
      return const <BottomNavigationBarItem>[
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuditService.logLogout(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // DEBUG: Verificar estado de autenticación
    print('🎯 BUILD - Usuario: ${auth.currentUser?.username}');
    print('🎯 BUILD - Rol: ${auth.currentUser?.role}');
    print('🎯 BUILD - isAdmin: ${auth.isAdmin}');
    print('🎯 BUILD - isEmpleado: ${auth.isEmpleado}');
    print('🎯 BUILD - isLoggedIn: ${auth.isLoggedIn}');

    final widgetOptions = _getWidgetOptions(auth);
    final navItems = _getNavItems(auth);

    final indiceSeguro = _selectedIndex.clamp(0, widgetOptions.length - 1);
    if (_selectedIndex != indiceSeguro) {
      print('🔄 Ajustando índice de $_selectedIndex a $indiceSeguro');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedIndex = indiceSeguro;
        });
      });
    }

    // DEBUG: Verificar navegación
    print('📊 Índice actual: $_selectedIndex');
    print('📊 Widgets disponibles: ${widgetOptions.length}');
    print('📊 Items de navegación: ${navItems.length}');
    print('📊 BottomNavigationBar: ${auth.isAdmin ? "VISIBLE" : "OCULTO"}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Inventario'),
        backgroundColor: Colors.blueGrey[700],
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Cerrar Sesión'),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                  Text('Usuario: ${auth.currentUser?.nombre}', style: const TextStyle(fontSize: 12)),
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