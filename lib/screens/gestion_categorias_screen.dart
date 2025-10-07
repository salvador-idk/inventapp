// screens/gestion_categorias_screen.dart
import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import '/models/categoria_model.dart';

class GestionCategoriasScreen extends StatefulWidget {
  const GestionCategoriasScreen({Key? key}) : super(key: key);

  @override
  _GestionCategoriasScreenState createState() => _GestionCategoriasScreenState();
}

class _GestionCategoriasScreenState extends State<GestionCategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final dbHelper = DatabaseHelper();
    final categorias = await dbHelper.getCategorias();
    setState(() {
      _categorias = categorias;
      _cargando = false;
    });
  }

  // REEMPLAZA el método _mostrarDialogoAgregarCategoria con esta versión corregida
void _mostrarDialogoAgregarCategoria() {
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  String colorSeleccionado = 'FF5722';

  final coloresDisponibles = [
    {'nombre': 'Naranja', 'valor': 'FF5722'},
    {'nombre': 'Azul', 'valor': '2196F3'},
    {'nombre': 'Verde', 'valor': '4CAF50'},
    {'nombre': 'Morado', 'valor': '9C27B0'},
    {'nombre': 'Gris', 'valor': '607D8B'},
    {'nombre': 'Marrón', 'valor': '795548'},
    {'nombre': 'Rojo', 'valor': 'F44336'},
    {'nombre': 'Amarillo', 'valor': 'FFEB3B'},
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Agregar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE: mainAxisSize.min
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Color:'),
                const SizedBox(height: 8),
                
                // ✅ SOLUCIÓN: Usar Wrap en lugar de ListView.builder
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coloresDisponibles.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          colorSeleccionado = color['valor']!;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(color['valor']!),
                          borderRadius: BorderRadius.circular(20),
                          border: colorSeleccionado == color['valor']
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: colorSeleccionado == color['valor']
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                final nuevaCategoria = Categoria(
                  nombre: nombreController.text,
                  descripcion: descripcionController.text.isEmpty 
                      ? null 
                      : descripcionController.text,
                  color: colorSeleccionado,
                );

                try {
                  final dbHelper = DatabaseHelper();
                  await dbHelper.insertCategoria(nuevaCategoria);
                  
                  Navigator.of(context).pop();
                  await _cargarCategorias();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Categoría agregada exitosamente')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}

  Color _hexToColor(String hex) {
    try {
      String hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la categoría "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteCategoria(categoria.id!);
        await _cargarCategorias();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarDialogoAgregarCategoria,
            tooltip: 'Agregar categoría',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay categorías creadas'),
                      SizedBox(height: 8),
                      Text('Presiona el botón + para agregar una'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = _categorias[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: categoria.colorMaterial,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        title: Text(
                          categoria.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: categoria.descripcion != null
                            ? Text(categoria.descripcion!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarCategoria(categoria),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}