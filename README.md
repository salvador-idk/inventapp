# Sistema de Inventario Móvil 📱

Sistema completo de gestión de inventario desarrollado en Flutter.

## 🚀 Características Principales

- **Gestión de Inventario**: Agregar, editar, eliminar items con imágenes
- **Sistema de Compras**: Carrito persistente y tickets de venta
- **Auditoría**: Log completo de todas las acciones del sistema
- **Dashboard**: Métricas y estadísticas en tiempo real
- **Alertas de Stock**: Notificaciones de productos con stock bajo
- **Búsqueda Avanzada**: Filtros por precio, stock y categorías
- **Etiquetas**: Impresión de etiquetas 5x2.5cm con códigos QR
- **Base de datos**: SQLite local con persistencia

## 👥 Roles de Usuario

- **Administrador**: Acceso completo al sistema (inventario, reportes, auditoría)
- **Empleado**: Solo módulo de compras y ventas

## 🛠 Tecnologías Utilizadas

- Flutter 3.x
- SQLite (sqflite)
- Provider (Gestión de estado)
- PDF/Printing (Reportes y etiquetas)
- QR Flutter (Códigos QR)
- Image Picker (Selección de imágenes)

## 📦 Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tuusuario/inventario-app.git

# Entrar al directorio
cd inventario-app

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
