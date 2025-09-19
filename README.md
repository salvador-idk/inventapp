# inventapp
<<<<<<< HEAD
aplicacion de inventario hibrida
=======
**Estructura final del proyecto**
------------------------------
Proyecto hibrido mobil-web
proyecto se desarrolla para la visualizacion en celulares moviles androis/IOS
y web.
-------------------------------
inventario_app/
├── android/
├── ios/
├── lib/
│   ├── web/                    # ✅ NUEVA CARPETA
│   │   ├── inventory_web_screen.dart
│   │   ├── cart_web_screen.dart
│   │   └── main_web.dart       # Punto de entrada web
│   ├── services/               # ✅ NUEVA CARPETA  
│   │   ├── firestore_service.dart
│   │   └── database_helper.dart  # Existente (modificar)
│   ├── models/                 # ✅ Existente (ampliar)
│   │   ├── item_model.dart
│   │   ├── user_model.dart
│   │   ├── audit_model.dart
│   │   ├── ticket_model.dart
│   │   └── cart_item.dart      # ✅ NUEVO ARCHIVO
│   ├── widgets/                # ✅ NUEVA CARPETA
│   │   ├── search_bar.dart
│   │   └── product_card.dart   # Opcional
│   ├── screens/                # ✅ Existente
│   │   ├── login_screen.dart
│   │   ├── main_screen.dart
│   │   ├── inventario_screen.dart
│   │   ├── agregar_item_screen.dart
│   │   ├── compras_screen.dart
│   │   ├── tickets_screen.dart
│   │   └── auditoria_screen.dart
│   ├── utils/                  # ✅ Existente/Opcional
│   │   ├── audit_service.dart
│   │   ├── etiqueta_service.dart
│   │   ├── ticket_service.dart
│   │   └── excel_export_service.dart
│   └── main.dart               # Punto de entrada móvil
├── web/                        # ✅ Carpeta web existente
│   ├── index.html
│   ├── manifest.json
│   └── icons/
├── assets/
├── firebase_options.dart       # ✅ Generado por FlutterFire
└── pubspec.yaml
