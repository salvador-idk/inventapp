import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/database_helper.dart';
import '/models/user_model.dart';
import 'main_screen.dart';
import '../providers/auth_provider.dart';
import '/utils/audit_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // ✅ VERIFICAR mounted ANTES del primer setState
      if (!mounted) return;
      
      setState(() {
        _loading = true;
      });

      try {
        final dbHelper = DatabaseHelper();
        final user = await dbHelper.getUserByUsername(_usernameController.text);

        if (user != null && user.password == _passwordController.text) {
          // Login exitoso
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.setCurrentUser(user);
          
          // ✅ LOG DE AUDITORÍA PARA LOGIN
          await AuditService.logLogin(context);
          
          // ✅ VERIFICAR mounted ANTES de navegar
          if (!mounted) return;
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // Credenciales incorrectas
          // ✅ VERIFICAR mounted ANTES de mostrar snackbar
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario o contraseña incorrectos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // ✅ VERIFICAR mounted ANTES de manejar errores
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // ✅ VERIFICAR mounted ANTES del último setState
        if (!mounted) return;
        
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ✅ AGREGAR dispose PARA LIMPIAR CONTROLLERS
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
                errorBuilder:(context, error, stackTrace){
                  return const Icon(Icons.inventory_2, size: 100);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Sistema de Inventario',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
              const SizedBox(height: 20),
              const Text(
                'Credenciales por defecto:\nAdmin: admin / admin123\nEmpleado: empleado / empleado123',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}