import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/database_helper.dart';
import '/models/user_model.dart'; // Asegúrate de importar el modelo correcto
import 'main_screen.dart';
import '../providers/auth_provider.dart';
import '/utils/audit_service.dart'; // ← Agregar esta importación

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
      setState(() {
        _loading = true;
      });

      try {
        final dbHelper = DatabaseHelper();
        final user = await dbHelper.getUserByUsername(_usernameController.text);

        if (user != null && user.password == _passwordController.text) {
          // Login exitoso
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          Provider.of<AuthProvider>(context, listen: false).setCurrentUser(user);
          
          // ✅ LOG DE AUDITORÍA PARA LOGIN
          await AuditService.logLogin(context);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // Credenciales incorrectas
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario o contraseña incorrectos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
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
              // ✅ Reemplaza el FlutterLogo con tu logo
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
                errorBuilder:(context, error, stackTrace){
                  return Icon(Icons.inventory_2, size: 100); //Fallback si la imagen no carga
                },
              ),
              const FlutterLogo(size: 100),
              const SizedBox(height: 30),
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