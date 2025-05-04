// lib/models/doctor.dart
class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String email;
  final String phone;
  final String bio;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.bio,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      email: json['email'],
      phone: json['phone'],
      bio: json['bio'],
    );
  }
}
