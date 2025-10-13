# Sistema de Inventario Móvil 📱

Sistema completo de gestión de inventario desarrollado en Flutter con **soporte multiplataforma y sincronización en la nube**.

## 🚀 Novedades y Mejoras Recientes

### 🔄 **Nueva Arquitectura de Datos**
- **Sistema Híbrido**: SQLite Local + Firebase Firestore
- **Sincronización Bidireccional**: Datos disponibles online/offline
- **Migración Automática**: Transferencia segura de datos entre fuentes
- **Fallback Inteligente**: Usa SQLite si Firebase no está disponible

### ☁️ **Integración Firebase**
- **Firestore**: Base de datos en la nube
- **Autenticación**: Sistema de usuarios escalable  
- **Storage**: Almacenamiento de imágenes en la nube

### 🎯 **Mejoras en la Gestión de Estado**
- Provider mejorado con MultiProvider
- Streams en tiempo real para actualizaciones instantáneas

## 📊 Características Principales Actualizadas

### **1. Gestión de Inventario Mejorada**
- ✅ **Items con categorías dinámicas** y colores personalizados
- ✅ **Validación en tiempo real** de números de serie únicos
- ✅ **Subida de imágenes** a Firebase Storage
- ✅ **Streams en tiempo real** para actualizaciones instantáneas

### **2. Sistema de Compras Avanzado**
- Carrito persistente con sincronización
- Validación de stock en tiempo real
- Tickets profesionales con formato PDF

### **3. Auditoría Completa**
- ✅ **Log de todas las acciones**: Crear, editar, eliminar items
- ✅ **Registro de compras** y transacciones
- ✅ **Seguimiento de usuarios** y horarios

### **4. Dashboard en Tiempo Real**
- Métricas actualizadas automáticamente
- Gráficos de stock y ventas
- Alertas proactivas de stock bajo

### **5. Búsqueda y Filtros Mejorados**
- Búsqueda por texto en múltiples campos
- Filtros por precio, stock y categorías
- Búsqueda con sugerencias inteligentes

### **6. Sistema de Etiquetas Profesional**
- **Formatos 5x2.5cm** estándar industrial
- **Códigos QR** con información completa del producto
- **Impresión directa** desde la aplicación

## 👥 Roles de Usuario Mejorados

### **Administrador** 🔧
- Gestión completa de inventario
- Configuración de Firebase y sincronización
- Reportes y auditoría detallada
- Migración de datos local → nube
- Gestión de categorías y usuarios

### **Empleado** 👤
- Módulo de compras optimizado
- Búsqueda rápida de productos
- Generación de tickets
- Stock en tiempo real

## 🛠 Stack Tecnológico Actualizado

### **Frontend & UI**
- **Flutter 3.19+** con Null Safety
- **Material Design 3** - Diseño moderno
- **Responsive Design** - Adaptable a tablets

### **Base de Datos**
```yaml
dependencies:
  sqflite: ^2.3.0      # SQLite local
  cloud_firestore: ^4.9.5  # Firebase Firestore
  firebase_core: ^2.15.1   # Core de Firebase
