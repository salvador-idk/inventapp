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