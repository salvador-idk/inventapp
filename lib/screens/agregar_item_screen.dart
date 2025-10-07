import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/services/database_helper.dart';
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
  int? _categoriaSeleccionada;

  @override
  void initState(){
    super.initState();
    _cargarCategorias();

    // Si estamos editando, precargar los datos
    _modoEdicion = widget.itemParaEditar != null;
    if (_modoEdicion){
      _cargarDatosParaEdicion();
    }
  }

  Future<void> _cargarCategorias() async {
    final dbHelper = DatabaseHelper();
    final categorias = await dbHelper.getCategorias();
    setState(() {
      _categorias = categorias;
    });
  }

  void _cargarDatosParaEdicion(){
    final item = widget.itemParaEditar!;
    _nombreController.text = item.nombre;
    _descripcionController.text = item.descripcion;
    _serialController.text = item.serial;
    _idController.text = item.numeroIdentificacion;
    _cantidadController.text = item.cantidad.toString();
    _precioController.text = item.precio.toString();
    _categoriaSeleccionada = item.categoriaId; // ✅ CARGAR CATEGORÍA

    if(item.imagenPath != null){
      _imagen = File(item.imagenPath!);
    }
    
    // En modo edición, el item ya está guardado
    _itemGuardado = item;
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagen = File(imagen.path);
        _imagenRequerida = false;
      });
    }
  }

 Future<void> _guardarItem() async {
  if (_formKey.currentState!.validate()) {
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

    // ✅ CREAR ITEM CON CATEGORÍA
    final item = Item(
      id: _modoEdicion ? widget.itemParaEditar!.id : null,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      serial: _serialController.text,
      numeroIdentificacion: _idController.text,
      imagenPath: _imagen?.path,
      cantidad: int.parse(_cantidadController.text),
      precio: double.parse(_precioController.text),
      categoriaId: _categoriaSeleccionada, // ✅ INCLUIR CATEGORÍA
    );

    try {
      final dbHelper = DatabaseHelper();

      if(_modoEdicion){
        // MODO EDICIÓN: Verificar si los campos únicos ya existen (excepto para este item)
        if (_serialController.text != widget.itemParaEditar!.serial || 
            _idController.text != widget.itemParaEditar!.numeroIdentificacion) {
          
          final itemsExistentes = await dbHelper.getItems();
          final serialExistente = itemsExistentes.any((i) => 
              i.serial == _serialController.text && i.id != widget.itemParaEditar!.id);
          final idExistente = itemsExistentes.any((i) => 
              i.numeroIdentificacion == _idController.text && i.id != widget.itemParaEditar!.id);
          
          if (serialExistente || idExistente) {
            setState(() { _guardando = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(serialExistente 
                    ? 'Ya existe un item con el mismo número de serie' 
                    : 'Ya existe un item con el mismo número de identificación'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // ✅ LOG DE AUDITORÍA PARA ACTUALIZACIÓN (ANTES de actualizar)
        await AuditService.logItemUpdate(
          context,
          itemId: widget.itemParaEditar!.id!,
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

        // Actualizar item existente
        await dbHelper.updateItem(item);
        final itemActualizado = item.copyWith(id: widget.itemParaEditar!.id);

        setState(() {
          _itemGuardado = itemActualizado;
          _guardando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item actualizado exitosamente')),
        );

        // Regresar a la pantalla anterior con éxito
        Navigator.of(context).pop(true);

      } else {
        // MODO NUEVO: Insertar nuevo item
        final id = await dbHelper.insertItem(item);

        // ✅ LOG DE AUDITORÍA PARA CREACIÓN (DESPUÉS de insertar)
        await AuditService.logItemCreate(
          context,
          itemId: id,
          itemName: item.nombre,
        );

        final itemGuardado = Item(
          id: id,
          nombre: item.nombre,
          descripcion: item.descripcion,
          serial: item.serial,
          numeroIdentificacion: item.numeroIdentificacion,
          imagenPath: item.imagenPath,
          cantidad: item.cantidad,
          precio: item.precio,
          categoriaId: item.categoriaId, // ✅ INCLUIR CATEGORÍA
        );

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
      
      // MANEJO ESPECÍFICO DE ERRORES
      if (e.toString().contains('Ya existe un item')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ya existe un item con el mismo número de serie o ID'),
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
      } else if (e.toString().contains('UNIQUE constraint failed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: El número de serie o ID ya existe en el sistema'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
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

  void _limpiarFormulario() {
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
      _categoriaSeleccionada = null; // ✅ LIMPIAR CATEGORÍA
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modoEdicion ? 'Editar Item' : 'Agregar Item'),
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
                        labelText: 'Nombre del Item',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ✅ DROPDOWN DE CATEGORÍAS (DENTRO DEL BUILD)
                    DropdownButtonFormField<int>(
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
                        ..._categorias.map((categoria) => DropdownMenuItem(
                          value: categoria.id,
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
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                      validator: (value) {
                        // Opcional: agregar validación si quieres que sea requerido
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Serie',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el número de serie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Identificación',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el número de identificación';
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
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese cantidad';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Ingrese un número válido';
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
                              labelText: 'Precio',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese precio';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Ingrese un número válido';
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
                    ),
                    if (_imagenRequerida)
                      const Text(
                        'Por favor agrega una imagen o confirma continuar sin ella',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    if (_imagen != null)
                      Image.file(
                        _imagen!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
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
                          child: Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _guardando
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _guardarItem,
                            child: Text(_modoEdicion ? 'Actualizar Item' : 'Guardar Item'),
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
}