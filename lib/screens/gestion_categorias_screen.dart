// screens/gestion_categorias_screen.dart
import 'package:flutter/material.dart';
import '/services/data_repository.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN
import '/models/categoria_model.dart';

class GestionCategoriasScreen extends StatefulWidget {
  const GestionCategoriasScreen({Key? key}) : super(key: key);

  @override
  _GestionCategoriasScreenState createState() => _GestionCategoriasScreenState();
}

class _GestionCategoriasScreenState extends State<GestionCategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  // ✅ INSTANCIA DEL DATA REPOSITORY
  final DataRepository _dataRepository = DataRepository();

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      // ✅ USAR DATA REPOSITORY EN LUGAR DE DATABASE HELPER
      final categorias = await _dataRepository.getCategorias();
      setState(() {
        _categorias = categorias;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      setState(() {
        _cargando = false;
      });
      _mostrarError('Error cargando categorías: $e');
    }
  }

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría *',
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
                    _mostrarError('El nombre es requerido');
                    return;
                  }

                  // ✅ VALIDAR SI LA CATEGORÍA YA EXISTE
                  final existeCategoria = _categorias.any(
                    (categoria) => categoria.nombre.toLowerCase() == nombreController.text.toLowerCase()
                  );

                  if (existeCategoria) {
                    _mostrarError('Ya existe una categoría con este nombre');
                    return;
                  }

                  final nuevaCategoria = Categoria(
                    nombre: nombreController.text.trim(),
                    descripcion: descripcionController.text.isEmpty 
                        ? null 
                        : descripcionController.text.trim(),
                    color: colorSeleccionado,
                  );

                  try {
                    // ✅ USAR DATA REPOSITORY PARA INSERTAR
                    await _dataRepository.insertCategoria(nuevaCategoria);
                    
                    Navigator.of(context).pop();
                    await _cargarCategorias();
                    
                    _mostrarExito('Categoría agregada exitosamente');
                  } catch (e) {
                    _mostrarError('Error al agregar categoría: $e');
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

  // ✅ MÉTODO PARA EDITAR CATEGORÍA
  void _mostrarDialogoEditarCategoria(Categoria categoria) {
    final nombreController = TextEditingController(text: categoria.nombre);
    final descripcionController = TextEditingController(text: categoria.descripcion ?? '');
    String colorSeleccionado = categoria.color;

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
            title: const Text('Editar Categoría'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría *',
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
                    _mostrarError('El nombre es requerido');
                    return;
                  }

                  // ✅ VALIDAR SI LA CATEGORÍA YA EXISTE (excluyendo la actual)
                  final existeCategoria = _categorias.any(
                    (cat) => 
                      cat.nombre.toLowerCase() == nombreController.text.toLowerCase() &&
                      cat.unifiedId != categoria.unifiedId
                  );

                  if (existeCategoria) {
                    _mostrarError('Ya existe otra categoría con este nombre');
                    return;
                  }

                  final categoriaActualizada = Categoria(
                    id: categoria.unifiedId, // ✅ USAR unifiedId
                    nombre: nombreController.text.trim(),
                    descripcion: descripcionController.text.isEmpty 
                        ? null 
                        : descripcionController.text.trim(),
                    color: colorSeleccionado,
                  );

                  try {
                    // ✅ USAR DATA REPOSITORY PARA ACTUALIZAR
                    await _dataRepository.updateCategoria(categoriaActualizada);
                    
                    Navigator.of(context).pop();
                    await _cargarCategorias();
                    
                    _mostrarExito('Categoría actualizada exitosamente');
                  } catch (e) {
                    _mostrarError('Error al actualizar categoría: $e');
                  }
                },
                child: const Text('Actualizar'),
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
        // ✅ USAR DATA REPOSITORY PARA ELIMINAR
        await _dataRepository.deleteCategoria(categoria.unifiedId);
        await _cargarCategorias();
        
        _mostrarExito('Categoría eliminada exitosamente');
      } catch (e) {
        _mostrarError('Error al eliminar categoría: $e');
      }
    }
  }

  // ✅ MÉTODOS AUXILIARES PARA MOSTRAR MENSAJES
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
                      Text(
                        'No hay categorías creadas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Presiona el botón + para agregar una',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarCategorias,
                  child: ListView.builder(
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
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          title: Text(
                            categoria.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: categoria.descripcion != null
                              ? Text(
                                  categoria.descripcion!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const Text(
                                  'Sin descripción',
                                  style: TextStyle(color: Colors.grey),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _mostrarDialogoEditarCategoria(categoria),
                                tooltip: 'Editar categoría',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarCategoria(categoria),
                                tooltip: 'Eliminar categoría',
                              ),
                            ],
                          ),
                          onTap: () => _mostrarDialogoEditarCategoria(categoria),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}