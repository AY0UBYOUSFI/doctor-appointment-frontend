import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static final GetStorage storage = GetStorage(); // ⬅️ نضيفه هنا

  static String? get token => storage.read('token');
  // تسجيل الدخول
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('فشل تسجيل الدخول: ${response.body}');
      }
    } on SocketException {
      throw Exception('لا يوجد اتصال بالسيرفر. تأكد أن السيرفر يعمل.');
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل مريض
  static Future<Map<String, dynamic>> registerPatient(String name, String email,
      String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": confirmPassword,
          "role": "patient",
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('فشل التسجيل: ${response.body}');
      }
    } on SocketException {
      throw Exception('لا يوجد اتصال بالسيرفر. تأكد أن السيرفر يعمل.');
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل طبيب
  static Future<Map<String, dynamic>> registerDoctor(
      String name,
      String email,
      String password,
      String confirmPassword,
      String specialization,
      String phone,
      String bio) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/doctor'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": confirmPassword,
          "specialization": specialization,
          "phone": phone,
          "bio": bio,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('فشل تسجيل الطبيب: ${response.body}');
      }
    } on SocketException {
      throw Exception('لا يوجد اتصال بالسيرفر. تأكد أن السيرفر يعمل.');
    } catch (e) {
      rethrow;
    }
  }

  // ✅ جلب جميع الأطباء
  static Future<List<dynamic>> getAllDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['doctors'];
      } else {
        throw Exception('فشل في تحميل الأطباء: ${response.body}');
      }
    } on SocketException {
      throw Exception('لا يوجد اتصال بالسيرفر. تأكد أن السيرفر يعمل.');
    } catch (e) {
      rethrow;
    }
  }
}
