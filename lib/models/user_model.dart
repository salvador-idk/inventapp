import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  int? id;
  String username;
  String password;
  String role; // 'admin' o 'empleado'
  String nombre;
  String? email;

  AppUser({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.nombre,
    this.email,
  });

  // ✅ FROM FIRESTORE - NUEVO MÉTODO
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: null, // Firestore usa su propio ID, no necesitamos mapearlo aquí
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'empleado',
      nombre: data['nombre'] ?? '',
      email: data['email'],
    );
  }

  // ✅ TO FIRESTORE - NUEVO MÉTODO
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'nombre': nombre,
      'email': email,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'nombre': nombre,
      'email': email,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      nombre: map['nombre'],
      email: map['email'],
    );
  }
}