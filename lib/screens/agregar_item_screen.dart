import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '/services/data_repository.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN
import '/services/inventory_service.dart';
import '/models/item_model.dart';
import '/models/categoria_model.dart';
import '/utils/etiqueta_service.dart';
import '/utils/audit_service.dart';

class AgregarItemScreen extends StatefulWidget {
  final Item? itemParaEditar;

  const AgregarItemScreen({Key? key, this.itemParaEditar}) : super(key: key);

  @override
  _AgregarItemScreenState createState() => _AgregarItemScreenState();
}

class _AgregarItemScreenState extends State<AgregarItemScreen> {
  // ✅ MÉTODO PARA CONVERSIÓN SEGURA DE STRING A INT
  int _safeStringToInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController(text: '0');
  final TextEditingController _precioController = TextEditingController(text: '0.0');

  File? _imagen;
  final ImagePicker _picker = ImagePicker();
  Item? _itemGuardado;
  bool _guardando = false;
  bool _imagenRequerida = false;
  bool _modoEdicion = false; 

  List<Categoria> _categorias = [];
  String? _categoriaSeleccionada;

  // ✅ GET INVENTORY SERVICE INSTANCE
  InventoryService get _inventoryService {
    return Provider.of<InventoryService>(context, listen: false);
  }

  // ✅ GET DATA REPOSITORY INSTANCE
  DataRepository get _dataRepository {
    return DataRepository();
  }

  @override
  void initState(){
    super.initState();
    _cargarCategorias();

    _modoEdicion = widget.itemParaEditar != null;
    if (_modoEdicion){
      _cargarDatosParaEdicion();
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      // ✅ USAR DATA REPOSITORY EN LUGAR DE DATABASE HELPER DIRECTAMENTE
      final categorias = await _dataRepository.getCategorias();
      setState(() {
        _categorias = categorias;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      // Mostrar snackbar de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando categorías: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cargarDatosParaEdicion(){
    final item = widget.itemParaEditar!;
    _nombreController.text = item.nombre;
    _descripcionController.text = item.descripcion;
    _serialController.text = item.serial;
    _idController.text = item.numeroIdentificacion;
    _cantidadController.text = item.cantidad.toString();
    _precioController.text = item.precio.toString();
    
    // ✅ CONVERSIÓN SEGURA DE CATEGORÍA - MANEJAR STRING IDs
    if (item.categoriaId != null && item.categoriaId!.isNotEmpty) {
      // Buscar la categoría que coincida (el ID en la base de datos es int, pero en Item es String)
      final categoriaEncontrada = _categorias.firstWhere(
        (categoria) => categoria.unifiedId == item.categoriaId,
        orElse: () => Categoria(
          id: '-1', 
          nombre: 'No encontrada', 
          color: 'FF0000' // Rojo para indicar error
        ),
      );
      
      if (categoriaEncontrada.id != '-1') {
        _categoriaSeleccionada = categoriaEncontrada.unifiedId;
      } else {
        // Si no se encuentra, usar el valor original
        _categoriaSeleccionada = item.categoriaId;
        print('⚠️ Categoría no encontrada para ID: ${item.categoriaId}');
      }
    } else {
      _categoriaSeleccionada = null;
    }

    if(item.imagenUrl != null && item.imagenUrl!.isNotEmpty){
      try {
        _imagen = File(item.imagenUrl!);
      } catch (e) {
        print('No se pudo cargar imagen local: $e');
      }
    }
    
    _itemGuardado = item;
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (imagen != null) {
      setState(() {
        _imagen = File(imagen.path);
        _imagenRequerida = false;
      });
    }
  }

  // ✅ VALIDATE SERIAL UNIQUENESS - FIXED TO USE INSTANCE METHOD
  Future<String?> _validarSerialUnico(String? value) async {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el número de serie';
    }

    if (value.length < 2) {
      return 'El número de serie debe tener al menos 2 caracteres';
    }

    try {
      // Podrías mostrar un indicador de carga aquí si la validación es lenta
      final existe = await _inventoryService.itemExists(
        value, 
        excludeItemId: _modoEdicion ? widget.itemParaEditar!.id : null
      );
      
      if (existe) {
        return 'Ya existe un item con este número de serie';
      }
    } catch (e) {
      print('Error validando serial único: $e');
      // No retornar error si falla la validación de unicidad
      // para no bloquear al usuario por errores de red
    }
    
    return null;
  }

  Future<void> _guardarItem() async {
    if (_formKey.currentState!.validate()) {
      // Validate serial uniqueness
      final serialError = await _validarSerialUnico(_serialController.text);
      if (serialError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serialError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Si no hay imagen, preguntar si está seguro
      if (_imagen == null) {
        final continuarSinImagen = await _confirmarSinImagen();
        if (!continuarSinImagen) {
          setState(() {
            _imagenRequerida = true;
          });
          return;
        }
      }

      setState(() {
        _guardando = true;
      });

      // ✅ CREAR ITEM CON CATEGORIA ID CORRECTO (STRING)
      final item = Item(
        id: _modoEdicion ? widget.itemParaEditar!.id : null,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        serial: _serialController.text,
        numeroIdentificacion: _idController.text,
        imagenUrl: _imagen?.path,
        cantidad: int.tryParse(_cantidadController.text) ?? 0,
        precio: double.tryParse(_precioController.text) ?? 0.0,
        categoriaId: _categoriaSeleccionada,
      );

      try {
        if (_modoEdicion) {
          // ✅ LOG DE AUDITORÍA PARA ACTUALIZACIÓN
          await AuditService.logItemUpdate(
            context,
            itemId: _safeStringToInt(widget.itemParaEditar!.id),
            oldData: jsonEncode({
              'nombre': widget.itemParaEditar!.nombre,
              'descripcion': widget.itemParaEditar!.descripcion,
              'serial': widget.itemParaEditar!.serial,
              'numeroIdentificacion': widget.itemParaEditar!.numeroIdentificacion,
              'precio': widget.itemParaEditar!.precio,
              'cantidad': widget.itemParaEditar!.cantidad,
              'categoriaId': widget.itemParaEditar!.categoriaId,
            }),
            newData: jsonEncode({
              'nombre': item.nombre,
              'descripcion': item.descripcion,
              'serial': item.serial,
              'numeroIdentificacion': item.numeroIdentificacion,
              'precio': item.precio,
              'cantidad': item.cantidad,
              'categoriaId': item.categoriaId,
            }),
            itemName: item.nombre,
          );

          // ✅ FIXED: Use instance method instead of static
          await _inventoryService.updateItem(item);

          setState(() {
            _itemGuardado = item.copyWith(id: widget.itemParaEditar!.id);
            _guardando = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item actualizado exitosamente')),
          );

          Navigator.of(context).pop(true);
        } else {
          // ✅ MODO NUEVO: Insertar nuevo item usando InventoryService instance
          final id = await _inventoryService.addItem(item);

          // ✅ LOG DE AUDITORÍA PARA CREACIÓN - CONVERSIÓN SEGURA A INT
          await AuditService.logItemCreate(
            context,
            itemId: _safeStringToInt(id), // ✅ CONVERSIÓN SEGURA
            itemName: item.nombre,
          );

          final itemGuardado = item.copyWith(id: id);

          setState(() {
            _itemGuardado = itemGuardado;
            _guardando = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item guardado exitosamente')),
          );

          await _mostrarOpcionesEtiqueta(itemGuardado);
        }
      } catch (e) {
        setState(() {
          _guardando = false;
        });
        _manejarErrorGuardado(e, context);
      }
    }
  }

  void _manejarErrorGuardado(dynamic e, BuildContext context) {
    String mensaje = 'Error al guardar: ${e.toString()}';
    
    if (e.toString().contains('Ya existe un item')) {
      mensaje = 'Ya existe un item con el mismo número de serie o ID';
    } else if (e.toString().contains('UNIQUE constraint failed')) {
      mensaje = 'Error: El número de serie o ID ya existe en el sistema';
    } else if (e.toString().contains('permission-denied')) {
      mensaje = 'Error de permisos: No tienes acceso para realizar esta acción';
    } else if (e.toString().contains('network-request-failed')) {
      mensaje = 'Error de red: Verifica tu conexión a internet';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<bool> _confirmarSinImagen() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin imagen'),
        content: const Text('¿Estás seguro de que quieres agregar el artículo sin imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agregar imagen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar sin imagen'),
          ),
        ],
      ),
    );
    
    return resultado ?? false;
  }

  Future<void> _mostrarOpcionesEtiqueta(Item item) async {
    final opcion = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etiqueta del Artículo'),
        content: const Text('¿Qué deseas hacer con la etiqueta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(0),
            child: const Text('Solo Guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(1),
            child: const Text('Ver Etiqueta'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(2),
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );

    switch (opcion) {
      case 1:
        await EtiquetaService.previsualizarEtiqueta(item, context);
        break;
      case 2:
        await EtiquetaService.imprimirEtiqueta(item, context);
        break;
      default:
        break;
    }
  }

  // ✅ DROPDOWN DE CATEGORÍAS
  Widget _buildCategoriaDropdown() {
    // Filtrar categorías para eliminar duplicados
    final categoriasUnicas = _eliminarCategoriasDuplicadas(_categorias);
    
    return DropdownButtonFormField<String>(
      value: _categoriaSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Sin categoría'),
        ),
        ...categoriasUnicas.map((categoria) {
          // ✅ USAR EL unifiedId PARA CONSISTENCIA
          final valorUnico = categoria.unifiedId;
          
          return DropdownMenuItem(
            value: valorUnico,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: categoria.colorMaterial,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(categoria.nombre),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _categoriaSeleccionada = value;
        });
      },
    );
  }

  // ✅ MÉTODO PARA ELIMINAR CATEGORÍAS DUPLICADAS
  List<Categoria> _eliminarCategoriasDuplicadas(List<Categoria> categorias) {
    final mapaUnico = <String, Categoria>{};
    
    for (final categoria in categorias) {
      final clave = categoria.unifiedId;
      if (!mapaUnico.containsKey(clave)) {
        mapaUnico[clave] = categoria;
      } else {
        print('⚠️ Categoría duplicada eliminada: ${categoria.nombre} (ID: ${categoria.unifiedId})');
      }
    }
    
    return mapaUnico.values.toList();
  }

  // ✅ MÉTODO PARA LIMPIAR FORMULARIO CON CONFIRMACIÓN
  void _limpiarFormulario() {
    if (_nombreController.text.isNotEmpty || 
        _descripcionController.text.isNotEmpty ||
        _imagen != null) {
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limpiar formulario'),
          content: const Text('¿Estás seguro de que quieres limpiar el formulario? Se perderán todos los datos no guardados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _realizarLimpiezaFormulario();
              },
              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      _realizarLimpiezaFormulario();
    }
  }

  // ✅ MÉTODO PARA REALIZAR LA LIMPIEZA
  void _realizarLimpiezaFormulario() {
    _formKey.currentState!.reset();
    _nombreController.clear();
    _descripcionController.clear();
    _serialController.clear();
    _idController.clear();
    _cantidadController.text = '0';
    _precioController.text = '0.0';
    setState(() {
      _imagen = null;
      _itemGuardado = null;
      _imagenRequerida = false;
      _categoriaSeleccionada = null;
    });
  }

  // ✅ MÉTODO DE VALIDACIÓN PARA SERIAL (también podría faltar)
  String? _validarSerial(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el número de serie';
    }
    if (value.length < 2) {
      return 'El número de serie debe tener al menos 2 caracteres';
    }
    return null;
  }

  // ✅ MÉTODO PARA MANEJAR ERRORES DE ELIMINACIÓN
  void _manejarErrorEliminacion(dynamic e, BuildContext context) {
    String mensaje = 'Error al eliminar: ${e.toString()}';
    
    if (e.toString().contains('permission-denied')) {
      mensaje = 'Error de permisos: No tienes acceso para eliminar items';
    } else if (e.toString().contains('network-request-failed')) {
      mensaje = 'Error de red: Verifica tu conexión a internet';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // ✅ MÉTODO PARA ELIMINAR ITEM
  Future<void> _eliminarItem() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Item'),
        content: const Text('¿Estás seguro de que quieres eliminar este item? Esta acción no se puede deshacer.'),
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

    if (confirmar == true) {
      try {
        setState(() {
          _guardando = true;
        });

        // ✅ Asegurar que el ID sea String
        final itemId = widget.itemParaEditar!.id;
        if (itemId == null) {
          throw Exception('El item no tiene ID');
        }

        // ✅ FIXED: Use instance method instead of static
        await _inventoryService.deleteItem(itemId);

        // ✅ LOG DE AUDITORÍA PARA ELIMINACIÓN - CONVERSIÓN SEGURA A INT
        await AuditService.logItemDelete(
          context,
          itemId: _safeStringToInt(itemId), // ✅ CONVERSIÓN SEGURA
          itemName: widget.itemParaEditar!.nombre,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item eliminado exitosamente')),
        );

        Navigator.of(context).pop(true);
      } catch (e) {
        setState(() {
          _guardando = false;
        });
        _manejarErrorEliminacion(e, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modoEdicion ? 'Editar Item' : 'Agregar Item'),
        actions: [
          if (_modoEdicion)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarItem,
              tooltip: 'Eliminar Item',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Item *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre';
                        }
                        if (value.length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la descripción';
                        }
                        if (value.length < 5) {
                          return 'La descripción debe tener al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildCategoriaDropdown(),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Serie *',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validarSerial,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Identificación *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el número de identificación';
                        }
                        if (value.length < 2) {
                          return 'El ID debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadController,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese cantidad';
                              }
                              final cantidad = int.tryParse(value);
                              if (cantidad == null) {
                                return 'Ingrese un número válido';
                              }
                              if (cantidad < 0) {
                                return 'La cantidad no puede ser negativa';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese precio';
                              }
                              final precio = double.tryParse(value);
                              if (precio == null) {
                                return 'Ingrese un número válido';
                              }
                              if (precio < 0) {
                                return 'El precio no puede ser negativo';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _seleccionarImagen,
                      icon: const Icon(Icons.image),
                      label: const Text('Seleccionar Imagen'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    if (_imagenRequerida)
                      const Text(
                        'Por favor agrega una imagen o confirma continuar sin ella',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    if (_imagen != null)
                      Stack(
                        children: [
                          Image.file(
                            _imagen!,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _imagen = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _guardando
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Guardando...'),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: _guardarItem,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: _modoEdicion ? Colors.orange : Colors.blue,
                            ),
                            child: Text(
                              _modoEdicion ? 'Actualizar Item' : 'Guardar Item',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_itemGuardado != null && !_modoEdicion) ...[
                const Divider(),
                const Text(
                  'Código QR generado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: _itemGuardado!.toQRData(),
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => EtiquetaService.previsualizarEtiqueta(_itemGuardado!, context),
                      child: const Text('Ver Etiqueta'),
                    ),
                    ElevatedButton(
                      onPressed: () => EtiquetaService.imprimirEtiqueta(_itemGuardado!, context),
                      child: const Text('Imprimir Etiqueta'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _limpiarFormulario,
                  child: const Text('Agregar Nuevo Item'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ... (los métodos _manejarErrorEliminacion y _eliminarItem se mantienen igual)
}