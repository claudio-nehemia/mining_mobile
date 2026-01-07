class DriverModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String ownType;
  final String namaPemilik;
  final String status;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ownType,
    required this.namaPemilik,
    required this.status,
  });

  // From JSON
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      ownType: json['own_type'],
      namaPemilik: json['nama_pemilik'],
      status: json['status'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'own_type': ownType,
      'nama_pemilik': namaPemilik,
      'status': status,
    };
  }

  // Copy with
  DriverModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? ownType,
    String? namaPemilik,
    String? status,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ownType: ownType ?? this.ownType,
      namaPemilik: namaPemilik ?? this.namaPemilik,
      status: status ?? this.status,
    );
  }
}